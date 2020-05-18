library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity FIR is 
    Generic (
            --TO_WEIGHT   : positive      := 32;
        TO_EXTEND   : positive      := 5; --2**TO_EXTEND = TO_WEIGHT
        WORD_BYTES  : positive      := 2;
            --WORDS_IN    : positive      := 2;
        INIT        : integer       := 0
    );
    Port (
        clk         : in    std_logic;
        reset       : in    std_logic;

        Data_in     : in    signed(8*WORD_BYTES-1 downto 0);
        Data_out    : out   signed(8*WORD_BYTES-1 downto 0)
    );
end FIR;

architecture Behavioral of FIR is 

    constant init_fir : signed(8*WORD_BYTES-1 downto 0) := (Others => '0');
    type shiftreg is array (0 to 2**TO_EXTEND-1) of signed(8*WORD_BYTES-1 downto 0) := (others => init_fir);

    signal sum : signed(TO_EXTEND+8*WORD_BYTES-1 downto 0) := (others => '0');

begin

    process(clk)
        --variable temp : unsigned(TO_EXTEND+8*WORD_BYTES-1 downto 0);
    begin
        if reset = '1' then
            shiftreg <= (others => init_fir);
            sum      <= (others => '0');
       
        elsif rising_edge(clk) then
            --If we take directly the input, we do not need to store the std_logic_vectotr referred as TO_WEIGHT-1
            --shiftreg_exit <= shiftreg(TO_WEIGHT-1);
            shiftreg(1 to 2**TO_EXTEND-1)   <= shiftreg(0 to 2**TO_EXTEND-2); 
            shiftreg(0)                     <= Data_in;
            
            sum                             <= sum + Data_in - shiftreg(2**TO_EXTEND-1);
            
            Data_out                        <= sum(sum'HIGH downto TO_EXTEND);
        end if;
    end process;
end Behavioral;