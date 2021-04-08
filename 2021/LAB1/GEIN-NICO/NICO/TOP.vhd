
---------- DEFAULT LIBRARY ---------
library IEEE;
	use IEEE.STD_LOGIC_1164.all;
	use IEEE.NUMERIC_STD.ALL;
------------------------------------










entity KittCarPWM is
	Generic (

		CLK_PERIOD_NS			:	POSITIVE	RANGE	1 TO 100     	:= 10;		-- clk period in nanoseconds
		MIN_KITT_CAR_STEP_MS	:	POSITIVE	RANGE	1 TO 2000    	:= 1;		-- Minimum step period in milliseconds (i.e., value in milliseconds of Delta_t)

		NUM_OF_SWS				:	INTEGER		RANGE	1 TO 16 		:= 16;		-- Number of input switches
		NUM_OF_LEDS				:	INTEGER		RANGE	1 TO 16 		:= 16;		-- Number of output LEDs

		PWM_FREQUENCY_KHZ		:	POSITIVE 	RANGE	1 TO 100		:= 10;		-- PWM frequency in KHz
		TAIL_LENGTH				:	INTEGER		RANGE	1 TO 16			:= 6		-- Tail length
	);
	Port (

		------- Reset/Clock --------
		reset	:	IN	STD_LOGIC;
		clk		:	IN	STD_LOGIC;
		----------------------------

		-------- LEDs/SWs ----------
		sw		:	IN	STD_LOGIC_VECTOR(NUM_OF_SWS-1 downto 0);	-- Switches avaiable on Basys3
		leds	:	OUT	STD_LOGIC_VECTOR(NUM_OF_LEDS-1 downto 0)	-- LEDs avaiable on Basys3
		----------------------------

	);
end KittCarPWM;


architecture Behavioral of KittCarPWM is

------------------ CONSTANT DECLARATION -------------------------
constant MS_COUNTER_RANGE		:	INTEGER  	:=	(MIN_KITT_CAR_STEP_MS * 1_000_000) / CLK_PERIOD_NS;
constant SW_COUNTER_RANGE		:	INTEGER 	:= 	2**NUM_OF_SWS;
constant COUNTER_MINIMUM_STEP	:	INTEGER	    :=	((MIN_KITT_CAR_STEP_MS * 1_000_000) / CLK_PERIOD_NS);
constant PWM_PERIOD				:	INTEGER	    :=	1_000_000 / (CLK_PERIOD_NS * PWM_FREQUENCY_KHZ);
constant TON_STEP_VALUE			:	INTEGER	    :=	PWM_PERIOD / TAIL_LENGTH;

------------------------- SIGNALS --------------------------------
signal tail_initialization		:	INTEGER 	RANGE 0 TO 	NUM_OF_LEDS 	:= TAIL_LENGTH;

signal ms_counter				:	INTEGER		RANGE 0 TO 	MS_COUNTER_RANGE	:= 0;
signal ms_counter_overflow 		:	INTEGER 	RANGE 0 TO 	MS_COUNTER_RANGE	:= 0;

signal sw_counter				:	INTEGER		RANGE 0 TO 	SW_COUNTER_RANGE	:= 0;
signal sw_counter_overflow 		:	INTEGER 	RANGE 0 TO 	SW_COUNTER_RANGE	:= 0;

signal switches_value 			:	INTEGER		RANGE 0 TO 	(2**NUM_OF_SWS);


type LED_Ton_array is array (LEDs'range) of STD_LOGIC_VECTOR(15 downto 0);
signal LED_Ton 		: LED_Ton_array := (others => (others => '0'));
signal LED_Ton_up 	: LED_Ton_array := (others => (others => '0'));
signal LED_Ton_down : LED_Ton_array := (others => (others => '0'));


component PulseWidthModulator is
	Generic(					
		BIT_LENGTH	:	INTEGER	;	-- Bit used  inside PWM
		
		T_ON_INIT	:	INTEGER;	-- Init of Ton
		PERIOD_INIT	:	POSITIVE;	-- Init of Periof
		
		PWM_INIT	:	STD_LOGIC	-- Init of PWM
	);
	Port ( 
		reset	:	IN	STD_LOGIC;
		clk		:	IN	STD_LOGIC;

		Ton		:	IN	STD_LOGIC_VECTOR(BIT_LENGTH-1 downto 0);	-- clk at PWM = '1'
		
		PWM		:	OUT	STD_LOGIC		-- PWM signal		
	);
end component PulseWidthModulator;


begin

	PWM_Driver_Stages:

	for I in 0 to NUM_OF_LEDS-1 generate

		PWM_X : PulseWidthModulator

			generic map (
				BIT_LENGTH 	=> 16,
				T_ON_INIT	=> 0,
				PERIOD_INIT	=> PWM_PERIOD,
				PWM_INIT	=> '1'
				)

			port map (
				reset 		=> reset,
				clk 		=> clk,
				Ton 		=> LED_Ton(I),
				PWM 		=> LEDs(I)
				);

	end generate PWM_Driver_Stages;

    process (reset, clk)
    begin

    	for I in 0 to NUM_OF_LEDS-1 loop

			if LED_Ton_up(I) >= LED_Ton_down(I) then

				LED_Ton(I) 	<=	LED_Ton_up(I);

			elsif LED_Ton_up(I) < LED_Ton_down(I) then

				LED_Ton(I) 	<=	LED_Ton_down(I);

			end if;
		
		end loop;
  
        if reset = '1' then									-- Reset condition
            ms_counter			<=	0;
            sw_counter			<=	0;
            tail_initialization	<=	TAIL_LENGTH;
           	LED_Ton_up 			<=	(others =>(others => '0'));
           	LED_Ton_down		<=	(others =>(others => '0'));
            
        elsif rising_edge(clk) then

        	ms_counter			<=	ms_counter +1;					-- Increase counter value by 1
        	switches_value		<= 	to_integer(unsigned(sw));	-- Sample switch states
        	ms_counter_overflow	<= 	COUNTER_MINIMUM_STEP;
        	sw_counter_overflow	<=	switches_value +1;

        	if ms_counter >= ms_counter_overflow then

        		ms_counter 		<=	0;
        		sw_counter 		<= sw_counter +1;

        		if sw_counter >= sw_counter_overflow then

        			sw_counter <= 0;

		        	if tail_initialization /= 0 then					--Initialization steps (injecting values)

		        		LED_Ton_up(0)	   		<=	STD_LOGIC_VECTOR(to_unsigned(tail_initialization * TON_STEP_VALUE, 16));
		        		LED_Ton_up(LED_Ton_up'high downto 1)        		<=	LED_Ton_up((LED_Ton_up'high -1) downto 0);       
		        		tail_initialization	<=	tail_initialization - 1;

		    		elsif tail_initialization = 0 then					--Normal operation on KittCarPWM

		    			LED_Ton_up 		<= 	LED_Ton_up((LED_Ton_up'high -1) downto 0) & LED_Ton_down(LED_Ton_down'low);
		    			LED_Ton_down	<= 	LED_Ton_up(LED_Ton_up'high) & LED_Ton_down((LED_Ton_down'high) downto 1);
		            	

		            end if;	            
                end if;	            
            end if;                       
        end if;
    
    end process; 

end Behavioral;