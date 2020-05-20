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

    constant init_fir : std_logic_vector(TO_EXTEND+8*WORD_BYTES-1 downto 0) := std_logic_vector(to_signed(INIT,TO_EXTEND+Data_in'LENGTH));
    constant init_sum : signed(TO_EXTEND+8*WORD_BYTES-1 downto 0) := to_signed(INIT,TO_EXTEND+Data_in'LENGTH);

    --Type Declaration
    type shiftreg is array (0 to 2**TO_EXTEND-1) of std_logic_vector(TO_EXTEND+8*WORD_BYTES-1 downto 0); 
    --"Type" instantiation
    signal shift_reg0 : shiftreg := (others => init_fir);

    signal sum : signed(TO_EXTEND+8*WORD_BYTES-1 downto 0) := init_sum;

    signal data_in_extended : std_logic_vector(TO_EXTEND+8*WORD_BYTES-1 downto 0);

begin

    -----------------------------------------------------------DATAFLOW---------------------------------------------------------------------
    data_in_extended(Data_in'HIGH downto 0) <= Data_in;
    with Data_in(Data_in'HIGH) select data_in_extended(data_in_extended'HIGH downto Data_in'LENGTH) <=
        (others => '1')  when '1',
        (others => '0')  when others;
    
    ----------------------------------------------------------------------------------------------------------------------------------------

    process(clk)
        --variable internal_sum : signed(TO_EXTEND+8*WORD_BYTES-1 downto 0) := to_signed(INIT,data_in_extended'LENGTH);
    begin
        if reset = '1' then
            --(2**TO_EXTEND * init_fir ) = init_sum
            shift_reg0  <= (others => init_fir);
            sum         <= init_sum;
       
        elsif rising_edge(clk) then
            case CE is
                when '1' => 
                    shift_reg0(1 to 2**TO_EXTEND-1)     <= shift_reg0(0 to 2**TO_EXTEND-2); 
                    shift_reg0(0)                       <= data_in_extended;
                    
                    sum                                 <= sum + signed(data_in_extended) - signed(shift_reg0(2**TO_EXTEND-1));
                    --internal_sum                        := internal_sum + signed(data_in_extended) - signed(shift_reg0(2**TO_EXTEND-1));

                    Data_out                            <= std_logic_vector(sum(sum'HIGH downto TO_EXTEND));
                    --Data_out                            <= std_logic_vector(internal_sum(internal_sum'HIGH downto TO_EXTEND));
            
                when '0' =>               
                    --Remain still and do not care about the input
                    shift_reg0(0 to 2**TO_EXTEND-1)     <= shift_reg0(0 to 2**TO_EXTEND-1);
                    Data_out                            <= std_logic_vector(sum(sum'HIGH downto TO_EXTEND));
                    --Data_out                            <= std_logic_vector(internal_sum(internal_sum'HIGH downto TO_EXTEND));

                
                when others =>
                    --

            end case;
        end if;
    end process;
end Behavioral;