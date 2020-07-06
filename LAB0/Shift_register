library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.NUMERIC_STD.ALL;

entity ShiftRegister is
    Generic(
        SR_WIDTH   :   NATURAL   := 8;   --If we look at the shift register as a rectangle proceeding from left to right, this is the height 
        SR_DEPTH   :   POSITIVE  := 4;   --Lenght of the top (bottom) segment, wich mens the number of "shifts" to do before the "output" , namely the number of flip flops for every row
        SR_INIT    :   INTEGER   := 0    --Initial value of one flip flop
    );
    Port ( 
        reset   :   IN  STD_LOGIC;
        clk     :   IN  STD_LOGIC;

        din   :   IN    STD_LOGIC_VECTOR(SR_WIDTH-1 downto 0);
        dout  :   OUT   STD_LOGIC_VECTOR(SR_WIDTH-1 downto 0)      
    );
end ShiftRegister;

architecture Behavioral of ShiftRegister is

    constant   INIT_SLV :    STD_LOGIC_VECTOR(SR_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(SR_INIT,SR_WIDTH));  --When using to_unsigned/to_signed the second parameter needed is the length(true
    ------------ Memory  ------------                                                                                   --number of elements)
    type    MEM_ARRAY_TYPE  is  array(0 TO SR_DEPTH-1) of STD_LOGIC_VECTOR(SR_WIDTH-1 downto 0);  --Instantiating 4 columns of 8 flip flops --> 32 flip flops in total
    signal  mem   :   MEM_ARRAY_TYPE := ( Others  => INIT_SLV);                                   --Initial value of the flip flops

begin
  
	dout    <=  mem(SR_DEPTH-1);                --proceeding to corretcly setting the output, done in dataflow, no big deal

    shift_reg  :  process(reset, clk)
    
    begin
        if (reset = '1') then                  --just putting all the memory units to their initial value
            mem  <= (Others => INIT_SLV);        
        elsif rising_edge(clk) then            --Shiting rightwards the signals
            mem  <=  din&mem(0 TO SR_DEPTH-2);      --the &operator just links the two things, "din will be the MSB and mem() will occupy all the other position from MSB-1 to LSB in mem"
        end if;   
    end process;
end Behavioral;

--We had to go from Integer to unsigned and then std_logic_vector, since there is no direct "cast" from integer (and his subtypes) to std_logic_vector/std_logic (row 22, constant INIT_SLV).