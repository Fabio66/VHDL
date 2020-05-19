library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity FIR is 
    Generic (
        --TO_WEIGHT   : positive      := 32;
        TO_EXTEND   : positive      := 5; --2**TO_EXTEND = TO_WEIGHT
        WORD_BYTES  : positive      := 2;
        INIT        : integer       := 0
    );
    Port (
        clk         : in    std_logic;
        reset       : in    std_logic;

        CE          : in    std_logic;

        Data_in     : in    std_logic_vector(8*WORD_BYTES-1 downto 0);
        Data_out    : out   std_logic_vector(8*WORD_BYTES-1 downto 0)
    );
end FIR;

architecture Behavioral of FIR is 

    --We need to declare two different constants cause shif_reg0 and sum are of different "dimensions"
    constant init_fir : std_logic_vector(8*WORD_BYTES-1 downto 0) := std_logic_vector(to_signed(INIT,Data_in'HIGH));
    constant init_sum : signed(TO_EXTEND+8*WORD_BYTES-1 downto 0) := to_signed((2**TO_EXTEND)*INIT,TO_EXTEND+Data_in'HIGH);

    --Type Declaration
    type shiftreg is array (0 to 2**TO_EXTEND-1) of std_logic_vector(8*WORD_BYTES-1 downto 0); 
    --"Type" instantiation
    signal shift_reg0 : shiftreg := (others => init_fir);

    signal sum : signed(TO_EXTEND+8*WORD_BYTES-1 downto 0) := init_sum;

begin

    process(clk)

    begin
        if reset = '1' then
            --(2**TO_EXTEND * init_fir ) = init_sum
            shift_reg0  <= (others => init_fir);
            sum         <= init_sum;
       
        elsif rising_edge(clk) then
            if CE = '1' then 
                --If we take directly the input, we do not need to store the std_logic_vector referred as TO_WEIGHT-1
                --shift_reg0_exit <= shift_reg0(TO_WEIGHT-1);
                shift_reg0(1 to 2**TO_EXTEND-1)     <= shift_reg0(0 to 2**TO_EXTEND-2); 
                shift_reg0(0)                       <= Data_in;
                
                sum                                 <= sum + signed(Data_in) - signed(shift_reg0(2**TO_EXTEND-1));
                
                Data_out                            <= std_logic_vector(sum(sum'HIGH downto TO_EXTEND));
           
            else --that is, CE = '0' or even the other unused type of std_logic
               
                --Remain still and do not care about the input
                shift_reg0(0 to 2**TO_EXTEND-1)     <= shift_reg0(0 to 2**TO_EXTEND-1);
                Data_out                            <= std_logic_vector(sum(sum'HIGH downto TO_EXTEND));
            
            end if;
        end if;
    end process;
end Behavioral;