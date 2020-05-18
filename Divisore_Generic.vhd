library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.NUMERIC_STD.ALL;

entity divisore is 
    Generic(
        Div_mul  : natural := 85;   ---Numero per cui vogliamo dividere l'ingesso, Div_mul = 2**m_extend/DIVISORE
        N_bit    : natuarl := 8;   ---Parametrizziamo il numero di bit d'ingresso
        m_extend : natural := 8    ---Estensione, utile per scegliere il grado di approssimazione
    );
    Port(
        clk      : std_logic;   
        reset    : std_logic;
        -------------------------
        d_in     : std_logic_vector(N_bit-1 downto 0);
        d_out    : std_logic_vector(N_bit-1 downto 0)
    );
end divisore;

architecture Behavioral of divisore is

    constant reset_val      : integer := 0;

    signal div_register     : std_logic_vector(to_unsigned(Div_mul,m_extend));
    --Non necessario da dichiarare perché facciamo compare con il singolo bit direttamente nella 
    --condizione del for loop nel process!!
    ------------------------------------------------------------------------------
    --signal countcompare     : std_logic_vector(m-1 downto 0) := (others => '1');
    ------------------------------------------------------------------------------
    signal extend_and_link  : std_logic_vector(m_extend+N_bit-1 downto 0);
    extend_and_link := std_logic_vector(to_unsigned(reset_val,m_extend+N_bit-1));
    
assert DIVISORE > 2**m_extend report "Divisore non rappresentabile con questi bit" severity failure;

begin
    ----------------------DATAFLOW---------------------------
    -- signal step : unsigned := (unsigned(d_in)*1/3);
    -- d_out <= std_logic_vector(step);
    d_out <= extend_and_link(m_extend+N_bit-1 downto m_extend);
    Division_Engine : process(clk, reset)
        --No variables needed
    begin
        if reset = '1' then 
            d_out = (others => '0');
        elsif rising_edge(clk) then
            --Dobbiamo dividere per un numero da decidere... come facciamo? --Dovremmo conoscere 
            --esattamente il numero per cui vogliamo dividere. Oppure?
            --CONTIAMO IL NUMERO DI UNI PRESENTI
            for I in 0 to 7 loop
                if div_register(N_bit-1-I downto N_bit-1-I) = '1' then
                    extend_and_link <= extend_and_link + d_in sll (7-I)
                end if;
            end loop;
            d_out <= extend_and_link(m_extend+N_bit-1 downto m_extend);
        end if;
    end process Division_Engine;
end Behavioral;