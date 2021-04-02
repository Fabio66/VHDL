-- Questa ROM contiene i risultati della divisione del periodo per ottenere la differenza di duty cycle tra led successivi 

---------- DEFAULT LIBRARY ---------
library IEEE;
	use IEEE.STD_LOGIC_1164.ALL;
	use IEEE.NUMERIC_STD.ALL;
------------------------------------

entity ROM_DIVISION is
	
	Port(
	
		---------- Clock -----------
		CLK			: in std_logic;
		----------------------------
		
		ADDR		: in	std_logic_vector(4 - 1 DOWNTO 0);  -- il numero di std_logic non è generic perché questa ROM è fatta su misura per il nostro caso, che può avere al massimo 
		DOUT		: out	std_logic_vector(8 - 1 DOWNTO 0)   -- 16 pwm differenti

	);
end ROM_DIVISION;

architecture Behavioral of ROM_DIVISION is

	------------------ CONSTANT DECLARATION -------------------------
	constant ADDR_LENGTH	: integer := 4;
	constant DOUT_LENGTH	: integer := 8;
	-----------------------------------------------------------------
	
	------------------------ TYPES DECLARATION ----------------------
	type rom_type is array (0 TO (2**ADDR_LENGTH)-1) of std_logic_vector(DOUT_LENGTH-1 DOWNTO 0);
	-----------------------------------------------------------------
	
	---------------------------- SIGNALS ----------------------------
	signal rom : rom_type  := (	x"00",	-- 0
								x"00",	-- Numero led=1
								x"20",  -- 1/2 del periodo
								x"15",	-- 1/3 del periodo
								x"10",	-- 1/4 del periodo
								x"0C",	-- 1/5 del periodo
								x"0A",	-- 1/6 del periodo
								x"09",	-- 1/7 del periodo
								x"08",	-- 1/8 del periodo
								x"07",	-- 1/9 del periodo
								x"06",	-- 1/10 del periodo
								x"05",	-- 1/11 del periodo
								x"05",	-- 1/12 del periodo
								x"04",	-- 1/13 del periodo
								x"04",	-- 1/14 del periodo
								x"04");	-- 1/15 del periodo
	-----------------------------------------------------------------

begin

	----------------------------- PROCESS ------------------------------
	ROM_PROC : process(CLK)
	begin

		if rising_edge(CLK) then

			DOUT	<= rom(to_integer(unsigned(ADDR)));

		end if;

	end process;
	-----------------------------------------------------------------

end Behavioral;
