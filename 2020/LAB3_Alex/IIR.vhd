library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity IIR is 
    Generic (
        TO_EXTEND   : positive      := 5; 
        WORD_BIT    : positive      := 16;
        INIT        : integer       := 0
    );
    Port (
        clk         : in    std_logic;
        reset       : in    std_logic;

        CE          : in    std_logic;

        Data_in     : in    std_logic_vector(WORD_BIT-1 downto 0);
        Data_out    : out   std_logic_vector(WORD_BIT-1 downto 0)
    );
end IIR;

architecture Behavioral of IIR is 

    --We need to declare two different constants cause shif_reg0 and sum are of different "dimensions"
    constant init_iir : std_logic_vector(WORD_BIT-1 downto 0) := std_logic_vector(to_signed(INIT,Data_in'LENGTH));
    constant init_sum : signed(TO_EXTEND+WORD_BIT-1 downto 0) := to_signed((2**TO_EXTEND)*INIT,TO_EXTEND+Data_in'LENGTH);

    --Type Declaration
    type shiftreg is array (0 to 2**TO_EXTEND-1) of std_logic_vector(WORD_BIT-1 downto 0); 
    --"Type" instantiation
    signal shift_reg0 : shiftreg := (others => init_iir);

    signal sum : signed(TO_EXTEND+WORD_BIT-1 downto 0) := init_sum;

begin

    process(clk)
    begin
        if reset = '1' then
            shift_reg0      <= (others => init_iir);
            sum             <= init_sum;

        elsif rising_edge(clk) then
            if CE = '1' then 
                shift_reg0(1 to 2**TO_EXTEND-1)     <= shift_reg0(0 to 2**TO_EXTEND-2); 
                shift_reg0(0)                       <= Data_in;
                
                sum                                 <= sum + signed(Data_in) - signed(shift_reg0(2**TO_EXTEND-1));

                Data_out                            <= std_logic_vector(sum(sum'HIGH downto TO_EXTEND));
           
            else              
                --Remain still and do not care about the input
                --We need this to properly compute the right output even if the CE is now 0, since we need 2 clock periods to have the right output
                Data_out                            <= std_logic_vector(sum(sum'HIGH downto TO_EXTEND));
                
            end if;
        end if;
    end process;
end Behavioral;