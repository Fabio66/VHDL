library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.NUMERIC_STD.ALL;

entity SREG is
    Generic(
        Altezza     : positive    := 4;
        Larghezza   : positive    := 1
    );
    Port(
        clk         : std_logic;
        reset       : std_logic;
        ----------------------------------------------------
        in_word     : std_logic_vector (Larghezza-1 downto 0);
        out_word    : std_logic_vector (Larghezza-1 downto 0)       
    );
end SREG;

architecture Behavioral of SREG is 

    constant INIT_VAL : std_logic_vector(Larghezza-1 downto 0) := (others => '0');
    type Registro is array(Altezza-1 downto 0) of std_logic_vector(Larghezza-1 downto 0);
    signal S_reg : Registro := (others => INIT_VAL);
    --signal din   : std_logic_vector(Larghezza-1 downto 0);
    --signal dout  : std_logic_vector(Larghezza-1 downto 0);
begin
    out_word <= S_reg(Altezza-1);
    SREG_engine : process(clk, reset)
    begin
        if reset = '1' then
            S_reg <= (others => INIT_VAL);
        elsif rising_edge(clk) then
            S_reg <= S_reg(Altezza-2 downto 0)&in_word;
        end if;
    end process SREG_engine;

end Behavioral;
