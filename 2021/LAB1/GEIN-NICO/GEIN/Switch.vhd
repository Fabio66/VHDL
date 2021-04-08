library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Switch is
	Generic(
		NUM_OF_SWS					:	INTEGER		RANGE	1	TO  16 			:= 16;					-- Number of input switches
		DEFAULT_KITT_CAR_STEP_MS	: 	POSITIVE	RANGE	1	TO	2000    	:= 100	
	);
	Port ( 		
        clk				: in std_logic;
		reset			: in std_logic;	

		SwitchState     : in std_logic_vector(NUM_OF_SWS - 1 DOWNTO 0);

        LedPeriod		: out std_logic_vector(NUM_OF_SWS - 1 DOWNTO 0)
	);
end Switch;

architecture Behavioral of Switch is

    constant DEF_SW             : unsigned(NUM_OF_SWS-1 downto 0)             := to_unsigned(DEFAULT_KITT_CAR_STEP_MS, LedPeriod'LENGTH);
    
    signal LedPeriodInternal    : unsigned(NUM_OF_SWS-1 downto 0)             := DEF_SW;

begin

	-- Read the switches
    LedPeriodInternal <= unsigned(SwitchState);
	
    process(clk, reset)
	begin
				
		if reset = '1' then 
		
			-- if reset is on, pass the DAFAULT_STEP
			LedPeriod <= std_logic_vector(DEF_SW);

		elsif rising_edge(clk) then 
		
			-- pass the switch state 
            LedPeriod <= std_logic_vector(LedPeriodInternal);

        end if;
		
	end process;

end Behavioral;