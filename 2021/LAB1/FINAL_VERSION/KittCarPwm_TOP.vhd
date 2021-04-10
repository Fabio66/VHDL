---------- DEFAULT LIBRARY ---------
library IEEE;
	use IEEE.STD_LOGIC_1164.all;
	use IEEE.NUMERIC_STD.ALL;
------------------------------------

entity KITT_CARR_PWM is
	Generic (
		BIT_LENGTH				:	INTEGER		RANGE	1 TO 32 		:= 32;      -- Bit used inside PWM. This value limit the lowest reacheable PWM frequency.

		CLK_PERIOD_NS			:	POSITIVE	RANGE	1 TO 100     	:= 10;		-- clk period in nanoseconds
		MIN_KITT_CAR_STEP_MS	:	POSITIVE	RANGE	1 TO 2000    	:= 1;		-- Minimum step period in milliseconds (i.e., value in milliseconds of Delta_t)

		NUM_OF_SWS				:	INTEGER		RANGE	1 TO 16 		:= 16;		-- Number of input switches
		NUM_OF_LEDS				:	INTEGER		RANGE	1 TO 16 		:= 16;		-- Number of output LEDs
		TAIL_LENGTH				:	INTEGER		RANGE	1 TO 16			:= 4;		-- Tail length
		
        PWM_FREQUENCY_KHZ		:	POSITIVE 	RANGE	1 TO 100		:= 1		-- PWM frequency in KHz
	);
	Port (
		reset	    :	IN	STD_LOGIC;
		clk		    :	IN	STD_LOGIC;

		sw		    :	IN	STD_LOGIC_VECTOR(NUM_OF_SWS-1 downto 0);	-- Switches avaiable on Basys3
		leds	    :	OUT	STD_LOGIC_VECTOR(NUM_OF_LEDS-1 downto 0)	-- LEDs avaiable on Basys3
	);
end KITT_CARR_PWM;


architecture Behavioral of KITT_CARR_PWM is

    ------------------ CONSTANT DECLARATION -------------------------

    constant MS_COUNTER_RANGE		:	INTEGER  	    :=	(MIN_KITT_CAR_STEP_MS*1_000_000)/CLK_PERIOD_NS;
    --constant	MS_COUNTER_RANGE	:	POSITIVE	    :=  (MIN_KITT_CAR_STEP_MS*1)/CLK_PERIOD_NS;				  -- Test Bench
    constant SW_COUNTER_RANGE		:	INTEGER 	    := 	2**NUM_OF_SWS-1;
    constant PWM_PERIOD				:	INTEGER	        :=	1_000_000/(CLK_PERIOD_NS*PWM_FREQUENCY_KHZ);
    constant TON_STEP_VALUE			:	INTEGER	        :=	PWM_PERIOD/TAIL_LENGTH;

    ------------------------- TYPES --------------------------------
    type LED_Ton_array is array (LEDs'RANGE) of STD_LOGIC_VECTOR(BIT_LENGTH-1 downto 0);
    type LED_sr_array  is array (NUM_OF_LEDS-2 downto 0) of STD_LOGIC_VECTOR(BIT_LENGTH-1 downto 0);

    ------------------------- SIGNALS --------------------------------

    signal tail_initialization		:	INTEGER     RANGE 0 TO  NUM_OF_LEDS 		    := TAIL_LENGTH;

    signal ms_counter				:	INTEGER		RANGE 0 TO 	MS_COUNTER_RANGE-1	    := 0;
    signal ms_counter_overflow 		:	INTEGER 	RANGE 0 TO 	MS_COUNTER_RANGE-1	    := 0;
    
    signal sw_counter				:	INTEGER		RANGE 0 TO 	SW_COUNTER_RANGE-1	    := 0;
    signal sw_counter_overflow 		:	INTEGER 	RANGE 0 TO 	SW_COUNTER_RANGE-1	    := 0;
    
    signal switches_value 			:	INTEGER		RANGE 0 TO 	2**NUM_OF_SWS-1;        -- ** added - 1


    signal LED_Ton 		    :   LED_Ton_array       := (others => (others => '0'));

    signal LED_Ton_up 	    :   LED_sr_array 	    := (others => (others => '0'));
    signal LED_Ton_down     :   LED_sr_array 	    := (others => (others => '0'));


    component PWM is
        Generic(						
            BIT_LENGTH	:	INTEGER;	    -- Bit used  inside PWM
            
            T_ON_INIT	:	INTEGER;	    -- Init of Ton
            PERIOD_INIT	:	POSITIVE;	    -- Init of Periof
            
            PWM_INIT	:	STD_LOGIC	    -- Init of PWM
        );
        Port ( 
            reset	:	IN	STD_LOGIC;
            clk		:	IN	STD_LOGIC;

            -------- Duty Cycle ----------
            Ton		:	IN	STD_LOGIC_VECTOR(BIT_LENGTH-1 downto 0);	-- clk at PWM = '1'
            -------- Output --------------		
            PWM		:	OUT	STD_LOGIC		                            -- PWM signal			
        );
    end component PWM;


begin

    -- Read switches, can be done in Dataflow since then the value is sampled in sw_counter_overflow
    sw_counter_overflow	    <=	switches_value;      

	PWM_Driver_Stages:

	for I in 0 to NUM_OF_LEDS-1 generate

		PWM_X : PWM
			generic map (
                    BIT_LENGTH 	=> BIT_LENGTH,

                    T_ON_INIT	=> 0,
                    PERIOD_INIT	=> PWM_PERIOD,

                    PWM_INIT	=> '1'
				)
			port map (
                    reset 		=> reset,
                    clk 		=> clk,

                    Ton 		=> LED_Ton(I),

                    PWM 		=> leds(I)
				);
		end generate PWM_Driver_Stages;

    process (reset, clk)   
    begin

        --------------------------------- Output Update---------------------------------------------
        -- copy in led state the two buffers. if some leds are superimposed, select the brighter one   
    	for I in 1 to NUM_OF_LEDS-2 loop
            -- looking at libraries the cast is not strictly needed
			if LED_Ton_up(I) >= LED_Ton_down(I-1) then

				LED_Ton(I) 	<=	LED_Ton_up(I);

			elsif LED_Ton_up(I) < LED_Ton_down(I-1) then

				LED_Ton(I) 	<=	LED_Ton_down(I-1);
			
            end if;
		end loop;


		LED_Ton(0) 	            <=	LED_Ton_up(0);
		LED_Ton(NUM_OF_LEDS-1) 	<=	LED_Ton_down(NUM_OF_LEDS-2);
        
        -- Reset counters and shift registers
        if reset = '1' then									        
            ms_counter			    <=	0;
            sw_counter			    <=	0;
            tail_initialization	    <=	TAIL_LENGTH;
           	LED_Ton_up 			    <=	(others =>(others => '0'));
           	LED_Ton_down		    <=	(others =>(others => '0'));
            
        elsif rising_edge(clk) then

        	ms_counter			    <=	ms_counter + 1;				-- Increase counter value by 1
        	ms_counter_overflow	    <= 	MS_COUNTER_RANGE - 1; 
            switches_value		    <= 	to_integer(unsigned(sw));	       
        	       
        	if ms_counter >= ms_counter_overflow then

        		ms_counter 		 <= 0;
        		sw_counter 		 <= sw_counter + 1;

        		if sw_counter >= sw_counter_overflow then

        			sw_counter <= 0;

                    --Initialization steps (injecting values)
		        	if tail_initialization /= 0 then					

		        		LED_Ton_up(0)	   		                    <=	STD_LOGIC_VECTOR(to_unsigned(tail_initialization * TON_STEP_VALUE, BIT_LENGTH));
		        		LED_Ton_up(LED_Ton_up'HIGH downto 1)        <=	LED_Ton_up((LED_Ton_up'HIGH-1) downto 0);       
		        		tail_initialization	                        <=	tail_initialization - 1;

                    --Normal operation on KittCarPWM
		    		elsif tail_initialization = 0 then					

		    			LED_Ton_up 		<= 	LED_Ton_up((LED_Ton_up'HIGH-1) downto 0) & LED_Ton_down(LED_Ton_down'LOW);
		    			LED_Ton_down	<= 	LED_Ton_up(LED_Ton_up'HIGH) & LED_Ton_down((LED_Ton_down'HIGH) downto 1);
		            	
		            end if;	            
                end if;           
            end if;                    
        end if;
    end process; 
end Behavioral;