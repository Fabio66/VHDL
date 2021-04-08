library IEEE;
	use IEEE.STD_LOGIC_1164.ALL;
	use IEEE.NUMERIC_STD.ALL;

entity sim_kittcar is
	Generic(
		CLK_PERIOD_NS			    :	POSITIVE	RANGE	1	TO	100     := 10;	-- clk period in nanoseconds
		NUM_OF_SWS					:	INTEGER		RANGE	1   TO  16      := 16;					-- Number of input switches
		MIN_KITT_CAR_STEP_MS		:	POSITIVE	RANGE	1	TO	20000   := 1000;			-- Minimum step period in milliseconds (i.e., value in milliseconds of Delta_t)
		DEFAULT_KITT_CAR_STEP_MS	: 	POSITIVE	RANGE	1	TO	2000    := 100;
		TAIL_LENGTH					:	INTEGER		RANGE	1 	TO 	16		:= 8;							-- Tail length
		NUM_OF_LEDS					:	INTEGER		RANGE	1 	TO 	16 		:= 16;			 -- Number of output LEDs
		PWM_FREQUENCY_KHZ		    :	POSITIVE 	RANGE	1 TO 100		:= 10;		-- PWM frequency in KHz
		T_ON_INIT	                :	INTEGER	      := 64;				-- Init of Ton
		PERIOD_INIT	                :	POSITIVE	  := 128;				-- Init of Periof
		PWM_INIT	                :	STD_LOGIC:= '1';					-- Init of PWM
        SR_DEPTH                    :   INTEGER := 16
	);
end sim_kittcar;

architecture Behavioral of sim_kittcar is

	component TopEntity is	
		Generic(
			CLK_PERIOD_NS			    :	POSITIVE;
			NUM_OF_SWS					:	INTEGER ;
			MIN_KITT_CAR_STEP_MS		:	POSITIVE ;
			DEFAULT_KITT_CAR_STEP_MS	: 	POSITIVE;
			TAIL_LENGTH					:	INTEGER;
			NUM_OF_LEDS					:	INTEGER	;
			PWM_FREQUENCY_KHZ		    :	POSITIVE ;
			T_ON_INIT	                :	INTEGER	;
			PERIOD_INIT	                :	POSITIVE;
			PWM_INIT	                :	STD_LOGIC;
			SR_DEPTH                    :   INTEGER
		);
		Port ( 	
			sw    			: in     std_logic_vector(NUM_OF_SWS - 1 DOWNTO 0);
			leds			: out 	 std_logic_vector(NUM_OF_LEDS - 1 DOWNTO 0);

			clk				: in std_logic;
			reset			: in std_logic		
		);
	
	end component;
	
	signal sw_int, leds_int 	: std_logic_vector(NUM_OF_SWS - 1 DOWNTO 0):= (others => '0');
	signal clk_int, reset_int 	: std_logic	:= '0';
	
	constant	CLK_PERIOD 	:	TIME	:= 10   ns;
	constant	HUMAN_PERIOD:	TIME	:= 10  ms;
	constant	RESET_WND	:	TIME	:= 10*CLK_PERIOD;



begin

	TopEntity_inst1 : TopEntity
		generic map(
			CLK_PERIOD_NS			    =>CLK_PERIOD_NS,
			NUM_OF_SWS					=>NUM_OF_SWS,
			MIN_KITT_CAR_STEP_MS		=>MIN_KITT_CAR_STEP_MS,
			DEFAULT_KITT_CAR_STEP_MS	=>DEFAULT_KITT_CAR_STEP_MS,
			TAIL_LENGTH					=>TAIL_LENGTH,							
			NUM_OF_LEDS					=>NUM_OF_LEDS,			 
			PWM_FREQUENCY_KHZ		    =>PWM_FREQUENCY_KHZ,		
			T_ON_INIT	                =>T_ON_INIT,				
			PERIOD_INIT	                =>PERIOD_INIT,				
			PWM_INIT	                =>PWM_INIT,					
			SR_DEPTH                    =>SR_DEPTH	
		)
		port map(
			sw    			=>sw_int,
			leds			=>leds_int,
			
			clk				=>clk_int,
			reset			=>reset_int
		);
		
	----------CLOCK SQUARE WAVE------------------	
	clk_int <= not clk_int after CLK_PERIOD/2;


	----- Reset Process --------
	reset_wave:		process
		begin
			reset_int <= '1';
			wait for RESET_WND;
			
			reset_int <= '0';
			wait;
		end process;	
	
	
   ------ Stimulus process -------
	
    stim_proc: 		process
    begin		

		-- waiting the reset wave
		sw_int	<= std_logic_vector(to_unsigned(0,NUM_OF_SWS));
		wait for RESET_WND;	

--		sw_int	<= std_logic_vector(to_unsigned(50,NUM_OF_SWS));
--		wait for HUMAN_PERIOD;
		
--		sw_int	<= std_logic_vector(to_unsigned(100,NUM_OF_SWS));
--		wait for HUMAN_PERIOD;
		
--		sw_int	<= std_logic_vector(to_unsigned(200,NUM_OF_SWS));
--		wait for HUMAN_PERIOD;
		
--		sw_int	<= std_logic_vector(to_unsigned(400,NUM_OF_SWS));
--		wait for HUMAN_PERIOD;
		
--		sw_int	<= std_logic_vector(to_unsigned(800,NUM_OF_SWS));
--		wait for HUMAN_PERIOD;
		
--		sw_int	<= std_logic_vector(to_unsigned(1000,NUM_OF_SWS));
--		wait for HUMAN_PERIOD;
		
--		sw_int	<= std_logic_vector(to_unsigned(1200,NUM_OF_SWS));
--		wait for HUMAN_PERIOD;
		
		sw_int	<= std_logic_vector(to_unsigned(1400,NUM_OF_SWS));
		wait for HUMAN_PERIOD;
		
--		sw_int	<= std_logic_vector(to_unsigned(2000,NUM_OF_SWS));
--		wait for HUMAN_PERIOD;
		
--		sw_int	<= std_logic_vector(to_unsigned(4000,NUM_OF_SWS));
--		wait for HUMAN_PERIOD;
		
--		sw_int	<= std_logic_vector(to_unsigned(8000,NUM_OF_SWS));
--		wait for HUMAN_PERIOD;
		
--		sw_int	<= std_logic_vector(to_unsigned(12000,NUM_OF_SWS));
--		wait for HUMAN_PERIOD;
		
--		sw_int	<= std_logic_vector(to_unsigned(24000,NUM_OF_SWS));
--		wait for HUMAN_PERIOD;
		
--		sw_int	<= std_logic_vector(to_unsigned(25000,NUM_OF_SWS));
--		wait for HUMAN_PERIOD;
		
--		sw_int	<= std_logic_vector(to_unsigned(28000,NUM_OF_SWS));
--		wait for HUMAN_PERIOD;
		
--		sw_int	<= std_logic_vector(to_unsigned(32000,NUM_OF_SWS));
		wait for HUMAN_PERIOD;
		
		wait;
		
    end process;
	
end Behavioral;