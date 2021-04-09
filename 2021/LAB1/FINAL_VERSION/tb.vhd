library IEEE;
	use IEEE.STD_LOGIC_1164.ALL;
	use IEEE.NUMERIC_STD.ALL;

entity tb_kittpwm is   
	-- Generic(
	-- );
end tb_kittpwm;

architecture Behavioral of tb_kittpwm is

	constant	CLK_PERIOD 	:	TIME	:= 	10 ns;
	constant	HUMAN_PERIOD:	TIME	:= 	10 ms;
	constant	RESET_WND	:	TIME	:= 	10*CLK_PERIOD;

	constant 	NUM_OF_SWS  	:   INTEGER := 16;
	constant 	NUM_OF_LEDS  	:   INTEGER := 16;
	constant 	TAIL_LENGTH  	:   INTEGER := 8;

	--constant 	NUM_OF_SWS  :   INTEGER := 16; already present for tb
	constant MIN_KITT_CAR_STEP_MS			:	POSITIVE	RANGE	1	TO	20000   := 1000;	
	constant DEFAULT_KITT_CAR_STEP_MS		: 	POSITIVE	RANGE	1	TO	2000    := 100;

	constant PWM_FREQUENCY_KHZ		    	:	POSITIVE 	RANGE	1   TO  100		:= 10;		
	constant T_ON_INIT	                	:	INTEGER	        					:= 64;  				        
	constant PERIOD_INIT	                :	POSITIVE	    					:= 128;				            
	constant PWM_INIT	                	:	STD_LOGIC       					:= '1';					        
	constant SR_DEPTH                    	:   INTEGER         					:= 16;    

	component TopEntity is	
		Generic(

			NUM_OF_SWS					:	INTEGER		RANGE	1   TO  16      := 16;		
			NUM_OF_LEDS					:	INTEGER		RANGE	1 	TO 	16 		:= 16;		
			TAIL_LENGTH					:	INTEGER		RANGE	1 	TO 	16		:= 8;		
		
			CLK_PERIOD_NS			    :	POSITIVE	RANGE	1	TO	100     := 10;	    
			MIN_KITT_CAR_STEP_MS		:	POSITIVE	RANGE	1	TO	20000   := 1000;	
			DEFAULT_KITT_CAR_STEP_MS	: 	POSITIVE	RANGE	1	TO	2000    := 100;
		
			PWM_FREQUENCY_KHZ		    :	POSITIVE 	RANGE	1   TO  100		:= 10;		
			T_ON_INIT	                :	INTEGER	        := 64;  				        
			PERIOD_INIT	                :	POSITIVE	    := 128;				            
			PWM_INIT	                :	STD_LOGIC       := '1';					        
			SR_DEPTH                    :   INTEGER         := 16    

		);
		Port ( 	
			clk				: in    std_logic;
			reset			: in    std_logic;

			sw    			: in     std_logic_vector(NUM_OF_SWS-1 downto 0);
			leds			: out 	 std_logic_vector(NUM_OF_LEDS-1 downto 0)		
		);
	
	end component;
	


	signal sw_int, leds_int 	: std_logic_vector(NUM_OF_SWS - 1 DOWNTO 0):= (others => '0');
	signal clk_int, reset_int 	: std_logic	:= '0';
	




begin

	TopEntity_inst1 : TopEntity
		generic map(

			NUM_OF_SWS					=>NUM_OF_SWS,
			TAIL_LENGTH					=>TAIL_LENGTH,							
			NUM_OF_LEDS					=>NUM_OF_LEDS,	

			CLK_PERIOD_NS			    =>CLK_PERIOD,
			MIN_KITT_CAR_STEP_MS		=>MIN_KITT_CAR_STEP_MS,
			DEFAULT_KITT_CAR_STEP_MS	=>DEFAULT_KITT_CAR_STEP_MS,
		 			
			PWM_FREQUENCY_KHZ		    =>PWM_FREQUENCY_KHZ,		
			T_ON_INIT	                =>T_ON_INIT,				
			PERIOD_INIT	                =>PERIOD_INIT,				
			PWM_INIT	                =>PWM_INIT,					
			SR_DEPTH                    =>SR_DEPTH	
		)
		port map(
			clk				=>clk_int,
			reset			=>reset_int,

			sw    			=>sw_int,
			leds			=>leds_int
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
	process
    begin		

		-- waiting the reset wave
		sw_int	<= std_logic_vector(to_unsigned(0,NUM_OF_SWS));
		wait for RESET_WND;	

		sw_int	<= x"0001";
		wait for 2*HUMAN_PERIOD;
		
		sw_int	<= x"0010";
		wait for HUMAN_PERIOD;
		
		sw_int	<= x"0100";
		wait for 2*HUMAN_PERIOD;
		
		sw_int	<= x"01f0";
		wait for HUMAN_PERIOD;
		
		sw_int	<= x"0ff0";
		wait for HUMAN_PERIOD;

--		sw_int	<= std_logic_vector(to_unsigned(32000,NUM_OF_SWS));
-- 		wait for HUMAN_PERIOD;
		
		wait;
		
    end process;

end Behavioral;