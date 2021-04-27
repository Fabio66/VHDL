library IEEE;
	use IEEE.STD_LOGIC_1164.ALL;
	use IEEE.NUMERIC_STD.ALL;

entity tb_kittpwm is   
	-- Generic(
	-- );
end tb_kittpwm;

architecture Behavioral of tb_kittpwm is

	constant	CLK_PERIOD		:	TIME	:= 	10 ns;
	constant	HUMAN_PERIOD	:	TIME	:= 	20 ms;
	constant	RESET_WND		:	TIME	:= 	100  ns;

	constant 	CLK_PERIOD_NS			:	POSITIVE	RANGE	1 TO 100     	:= 10;		
	constant 	MIN_KITT_CAR_STEP_MS	:	POSITIVE	RANGE	1 TO 20000   	:= 1;	

	constant 	NUM_OF_SWS  	:   INTEGER := 16;
	constant 	NUM_OF_LEDS  	:   INTEGER := 16;
	constant 	TAIL_LENGTH  	:   INTEGER := 4;

	constant 	PWM_FREQUENCY_KHZ		:	POSITIVE 	RANGE	1   TO  100		:= 10;			             
	constant 	PWM_INIT                :   STD_LOGIC   := '1';

	component KITT_CARR_PWM is
		Generic (
	
			CLK_PERIOD_NS			:	POSITIVE	RANGE	1 TO 100     	:= 10;		-- clk period in nanoseconds
			MIN_KITT_CAR_STEP_MS	:	POSITIVE	RANGE	1 TO 2000    	:= 1;		-- Minimum step period in milliseconds (i.e., value in milliseconds of Delta_t)
	
			NUM_OF_SWS				:	INTEGER		RANGE	1 TO 16 		:= 16;		-- Number of input switches
			NUM_OF_LEDS				:	INTEGER		RANGE	1 TO 16 		:= 16;		-- Number of output LEDs
			TAIL_LENGTH				:	INTEGER		RANGE	1 TO 16			:= 4;		-- Tail length
			
			PWM_FREQUENCY_KHZ		:	POSITIVE 	RANGE	1 TO 100		:= 1;		-- PWM frequency in KHz
			PWM_INIT                :   STD_LOGIC   := '1'
		
		);
		Port (
			reset	    :	IN	STD_LOGIC;
			clk		    :	IN	STD_LOGIC;
	
			sw		    :	IN	STD_LOGIC_VECTOR(NUM_OF_SWS-1 downto 0);	-- Switches avaiable on Basys3
			leds	    :	OUT	STD_LOGIC_VECTOR(NUM_OF_LEDS-1 downto 0)	-- LEDs avaiable on Basys3
		);
	end component;
	
	signal sw				 	: std_logic_vector(NUM_OF_SWS-1 DOWNTO 0)	:= (others => '0');
	signal leds			 		: std_logic_vector(NUM_OF_LEDS-1 DOWNTO 0)	:= (others => '0');
	signal clk			 		: std_logic	:= '1';
	signal reset		 		: std_logic	:= '0';
	

begin

	----------CLOCK SQUARE WAVE------------------	
	clk <= not clk after CLK_PERIOD/2;

	Dut_kit_car_pwm : KITT_CARR_PWM
		generic map(

			CLK_PERIOD_NS			    => CLK_PERIOD_NS,
			MIN_KITT_CAR_STEP_MS		=> MIN_KITT_CAR_STEP_MS,

			NUM_OF_SWS					=> NUM_OF_SWS,
			TAIL_LENGTH					=> TAIL_LENGTH,							
			NUM_OF_LEDS					=> NUM_OF_LEDS,	
		 			
			PWM_FREQUENCY_KHZ		    => PWM_FREQUENCY_KHZ,
			PWM_INIT               		=> PWM_INIT

		)
		port map(
			clk				=> clk,
			reset			=> reset,

			sw    			=> sw,
			leds			=> leds
		);

	----- Reset Process --------
	reset_wave:		process
		begin
			reset 	<= '1';
			wait for RESET_WND;
			
			reset 	<= '0';
			wait;
		end process;	
	
    ------ Stimulus process -------	
	process
    begin		
		-- waiting the reset wave
		sw	<= std_logic_vector(to_unsigned(0,NUM_OF_SWS));
		wait for RESET_WND;	

		sw	<= x"0001";
		wait for 2*HUMAN_PERIOD;
		
		sw	<= x"0010";
		wait for 5*HUMAN_PERIOD;
		
		sw	<= x"0100";
		wait for 20*HUMAN_PERIOD;
		
		sw	<= x"01f0";
		wait for 40*HUMAN_PERIOD;
		
		sw	<= x"0ff0";
		--wait for x*HUMAN_PERIOD;

--		sw_int	<= std_logic_vector(to_unsigned(32000,NUM_OF_SWS));
-- 		wait for HUMAN_PERIOD;
		
		wait;
		
    end process;
end Behavioral;