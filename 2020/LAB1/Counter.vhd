library IEEE;
	use IEEE.STD_LOGIC_1164.all;
	use IEEE.NUMERIC_STD.ALL;
	
entity counter is
	generic(				
		COUNT_INIT			:	integer := 0;					--	Valore iniziale 
		BIT_MIN				:	integer range 1 to 20 := 11;	--	Bits del tempo minimo
		ENLARGEMENT_WIDTH	:	integer range 1 to 16 := 16		--	Bits del fattore che moltiplica il tempo minimo		
	);	
	port( 
		CLK					:	in	std_logic;
		RESET				:	in	std_logic;
		
		ENLARGEMENT			:	in	std_logic_vector(ENLARGEMENT_WIDTH - 1 downto 0);		--	Fattore che moltiplica il tempo minimo
		OVERFLOW			:	out std_logic;												
		COUNT				:	out std_logic_vector(BIT_MIN+ENLARGEMENT_WIDTH - 1 downto 0)		
	);                                 
end counter;

architecture Behavioral of counter is

	signal	COUNT_REG 		:   unsigned(COUNT'range)   :=  to_unsigned(COUNT_INIT, COUNT'LENGTH);
	signal	OVERFLOW_REG	:	std_logic	            :=	'0';

begin

	COUNT	 <= std_logic_vector(COUNT_REG);
	OVERFLOW <= OVERFLOW_REG;

	COUNTER_PROC : process (RESET, CLK) is
	begin
	
		if RESET='1' then		
			COUNT_REG		<= to_unsigned(COUNT_INIT, COUNT'LENGTH);
			OVERFLOW_REG	<= '0';
			
		elsif rising_edge(CLK) then		
				OVERFLOW_REG	<= '0';
				COUNT_REG		<= COUNT_REG + 1;				
				--	count_reg >= perchè nel caso in cui enlargement cambia durante il conteggio, il target da raggiungere può già essere stato superato
				if COUNT_REG >= (2**BIT_MIN)*(1+to_integer(unsigned(ENLARGEMENT)))-1  then						
					COUNT_REG		<= to_unsigned(COUNT_INIT, COUNT'LENGTH);
					OVERFLOW_REG	<= '1';				
				end if;				
		end if;	
	end process COUNTER_PROC;	
end Behavioral;