library IEEE;
	use IEEE.STD_LOGIC_1164.all;
	use IEEE.NUMERIC_STD.ALL;		

entity tb_PWM is
end tb_PWM;

architecture Behavioral of tb_PWM is
------------------ CONSTANT DECLARATION -------------------------

	--------- Timing -----------
	constant	CLK_PERIOD 	:	TIME	:= 10 ns;
	----------------------------

	------ COMPONENT DECLARATION for the Device Under Test (DUT) ------
	-------- First DUT ---------
	
	component PWM
		generic(							
			BIT_LENGTH	:	INTEGER	RANGE	1 TO 32;

			T_ON_INIT	:	POSITIVE;				
			PERIOD_INIT	:	POSITIVE;

			PWM_INIT	:	STD_LOGIC							
		);
		port( 	
			reset	:	IN	STD_LOGIC;
			clk		:	IN	STD_LOGIC;

			Ton		:	IN	STD_LOGIC_VECTOR(BIT_LENGTH-1 downto 0);	
			Period	:	IN	STD_LOGIC_VECTOR(BIT_LENGTH-1 downto 0);

			pwm		:	OUT	STD_LOGIC			
		);
	end component;

	--------------------- SIGNALS DECLARATION -----------------------
	
	----- First DUT Signals ----
	constant BIT_LENGTH			:	INTEGER	RANGE	1 TO 32 :=4;	
	constant T_ON_INIT			:	POSITIVE :=1;
	constant PERIOD_INIT		:	POSITIVE := 2;
	constant PWM_INIT			:	std_logic := '1';
	signal clk					:	std_logic := '1';
	signal reset				:	std_logic := '0';
	signal Ton					:	std_logic_vector(BIT_LENGTH-1 downto 0) := (others => '0');
	signal Period				:	std_logic_vector(BIT_LENGTH-1 downto 0);
	signal pwm_reg				:	std_logic;
	---------------------------------------

begin

	--------------------- COMPONENTS DUT WRAPPING --------------------	
	----------- DUT ------------
	dut_PWM	:	PWM
		Generic Map(				
			BIT_LENGTH		=>	BIT_LENGTH,
			T_ON_INIT		=>	T_ON_INIT,
			PERIOD_INIT		=>	PERIOD_INIT,
			PWM_INIT		=>	PWM_INIT
		)
		Port Map( 	
			reset	=> reset,
			clk		=> clk,
			Ton		=>	Ton,
			Period	=>	Period,
    		PWM		=>	pwm_reg		
		);
	
	clk <= not clk after CLK_PERIOD/2;

    process
    begin		
    	
		for I in 0 to 2**BIT_LENGTH-1 loop
		
			Period	<= std_logic_vector(to_unsigned(I ,BIT_LENGTH));
		
			for J in 0 to 2**BIT_LENGTH-1 loop 
			
				Ton	<= std_logic_vector(to_unsigned(J ,BIT_LENGTH));	
				wait for 10*CLK_PERIOD;
			
			end loop;
		end loop;
		reset <= '1';
		wait;
    
    end process;
end Behavioral;