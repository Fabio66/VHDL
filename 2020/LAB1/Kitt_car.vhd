library IEEE;
	use IEEE.STD_LOGIC_1164.all;
	use IEEE.NUMERIC_STD.ALL;

entity kitt_car_pwm is
	generic(
		LED_WIDTH			:	integer range 2 to 16 	:= 16;	-- Numero di led utilizzati
		LED_NUMBER			:	integer range 1 to 15 	:=4;	-- Numero di led accesi contemporaneamente
		
		COUNT_INIT			:	integer := 0;					-- Valore iniziale del counter
		SW_WIDTH			:	integer range 1 to 16 	:= 16;	-- Numero di switch utilizzati
		BIT_MIN				:	integer range 1 to 20 	:= 13;	--	Bits del tempo minimo

		PWM_INIT			:	STD_LOGIC				:= '1'	-- Valore iniziale del PWM
	);
	port( 
		CLK			:	in	std_logic;
		RESET		:	in	std_logic;	
					
		SW			:	in	std_logic_vector(SW_WIDTH - 1 downto 0);	
		LED			:	out	std_logic_vector(LED_WIDTH-1 downto 0)
	);                                 
end kitt_car_pwm;

architecture Behavioral of kitt_car_pwm is

	type mytype	is array (integer range <>) of integer range 0 to 15;					-- Serve per inizializzare il Pointer	
	
	constant	BIT_LENGTH	:	INTEGER	RANGE 1 TO 16	:= 6;																	-- Bits usati nel pwm	
	constant	T_ON_INIT	:	POSITIVE				:= 16;																	-- Valore iniziale del Ton del PWM
	constant	PERIOD_INIT	:	POSITIVE				:= 31;																	-- Valore iniziale del Period del PWM
	constant	LED_INIT	:   std_logic_vector(LED_WIDTH-1 downto 0) := (LED_NUMBER - 1 downto 0 => '1', others	=> '0');	-- Led inizialmente accesi
	constant	POINT_INIT	:	mytype(16-1 downto 0) := (15,14,13,12,11,10,9,8,7,6,5,4,3,2,1,0);								-- Inizializzazione del pointer
	constant	Period		:	std_logic_vector(BIT_LENGTH-1 downto 0) := (others => '1');										-- Fisso il valore del Period del PWM
		
	type mytype2 is array (LED_NUMBER - 1 downto 0) of std_logic_vector(BIT_LENGTH-1 downto 0);		-- Serve per collegare i Ton ai PWM	
	
	component ROM_DIVISION is
		Port (	
			CLK			: in	std_logic;
			ADDR		: in	std_logic_vector(4 - 1 DOWNTO 0);
			DOUT		: out	std_logic_vector(8 - 1 DOWNTO 0)	
		);
	end component;
		
	component counter is
		generic(
			COUNT_INIT			:	integer ;
			BIT_MIN				:	integer range 1 to 20;
			ENLARGEMENT_WIDTH	:	integer range 1 to 16
		);
		port( 
			CLK				:	in	std_logic;
			RESET			:	in 	std_logic;
			ENLARGEMENT		:	in	std_logic_vector(SW_WIDTH - 1 downto 0);
			OVERFLOW		:	out std_logic;
			COUNT			:	out std_logic_vector(BIT_MIN+ENLARGEMENT_WIDTH - 1 downto 0)
		);                                 
	end component;

	component PulseWidthModulator is
		generic(						
			BIT_LENGTH	:	INTEGER	RANGE	1 TO 16;	
			T_ON_INIT	:	POSITIVE;				
			PERIOD_INIT	:	POSITIVE;				
			PWM_INIT	:	STD_LOGIC								
		);
		port ( 	
			reset	:	IN	STD_LOGIC;
			clk		:	IN	STD_LOGIC;
			Ton		:	IN	STD_LOGIC_VECTOR(BIT_LENGTH-1 downto 0);	
			Period	:	IN	STD_LOGIC_VECTOR(BIT_LENGTH-1 downto 0);	
			PWM		:	OUT	STD_LOGIC			
		);
	end component;

	signal LED_REG			:	std_logic_vector(LED_WIDTH-1 downto 0):= LED_INIT;								-- Registro collegato ai led
	signal POINTER			:	mytype(LED_NUMBER - 1 downto 0):= POINT_INIT(LED_NUMBER - 1 downto 0);			-- Punta ai led accesi
	signal DIRECTION		:	std_logic_vector(LED_NUMBER - 1 downto 0) := (others => '0');					-- Direzioni led: 0 SX 1 DX
	signal SHIFT_ON			:	std_logic;																		-- Uscita del counter
	signal PWM_REG			:	std_logic_vector(LED_NUMBER - 1 downto 0);										-- Uscita del pwm
	signal Ton_reg			:	mytype2;																		-- Registro dei Ton collegati ai PWM
	signal INTENSITY_DIFF	:	std_logic_vector(8-1 downto 0) ;												-- Differenza di duty cycle tra led successivi
	signal ADDR_ROM			:	std_logic_vector(4-1 downto 0) := std_logic_vector(to_unsigned(LED_NUMBER, 4));	-- Indirizzo della memoria utilizzato

begin

	--------------------- COMPONENTS INSTANTIATIONS -------------------
	ROM_DIVISION_inst1 : ROM_DIVISION
		port map(	
			CLK			=> CLK,
			ADDR		=> ADDR_ROM,
			DOUT		=> INTENSITY_DIFF
		);
	
	counter_inst1 : counter
		generic map(
			COUNT_INIT			=>	COUNT_INIT,
			ENLARGEMENT_WIDTH	=>	SW_WIDTH,
			BIT_MIN				=>	BIT_MIN		
		)
		port map( 
			CLK					=>	CLK,
			RESET				=>	RESET,
			ENLARGEMENT			=>	SW,
			OVERFLOW			=>	SHIFT_ON	
		);
	
	loop_gen : for I in 0 to LED_NUMBER - 1 generate
		
		-- Calcolo dei duty cycle per ogni led
		Ton_reg(I) <= std_logic_vector(to_unsigned(to_integer(unsigned(Period))-(LED_NUMBER - 1-I)*(to_integer(unsigned(INTENSITY_DIFF))), BIT_LENGTH));
		
		PulseWidthModulator_inst : PulseWidthModulator
			Generic map(					
				BIT_LENGTH	=>	BIT_LENGTH,
				T_ON_INIT	=>	T_ON_INIT,
				PERIOD_INIT	=>	PERIOD_INIT,
				PWM_INIT	=>	PWM_INIT	
			)
			Port map( 	
				reset	=>	RESET,
				clk		=>	CLK,		
				Ton		=>	Ton_reg(I),
				Period	=>	Period,
				PWM		=>	PWM_REG(I)				
			);
	end generate;

		LED <= LED_REG;
	
	SHIFT : process (RESET, CLK) is

		variable DIRECTION_VAR	: std_logic_vector(LED_NUMBER - 1 downto 0);
		
	begin
		if RESET = '1' then
				LED_REG <=	LED_INIT;
				POINTER <= POINT_INIT(LED_NUMBER - 1 downto 0);
				DIRECTION <= (others => '0');
	
		elsif rising_edge(CLK) then
			
			if SHIFT_ON = '1'  then
				
				DIRECTION_VAR := DIRECTION;
				
				for I in 0 to LED_NUMBER - 1 loop		-- tratto ogni led singolarmente
				
					-- se il led arriva all'estremo cambio la direzione
					if POINTER(I) = 0 then				
						DIRECTION_VAR(I) := '0';
					elsif POINTER(I) = LED_WIDTH - 1 then
						DIRECTION_VAR(I) := '1';
					end if;
				
					-- in base alla direzione sposto il led a sx o dx
					if DIRECTION_VAR(I) = '0' then 			
						POINTER(I) <= POINTER(I) + 1;
					elsif DIRECTION_VAR(I)= '1' then
						POINTER(I) <= POINTER(I) - 1;
					end if;
					
					DIRECTION(I) <= DIRECTION_VAR(I);
									
				end loop;
			end if;
				
			LED_REG <= (others => '0');
			for I in 0 to LED_NUMBER - 1 loop	
				LED_REG(POINTER(I)) <= PWM_REG(I);
			end loop;					
		end if;
	end process SHIFT;
end Behavioral;