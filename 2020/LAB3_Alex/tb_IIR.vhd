library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_IIR_std_logic is
--  Port ( );
end tb_IIR_std_logic;

architecture Behavioral of tb_IIR_std_logic is

	constant period 		: time          := 10 ns;
    constant TO_EXTEND      : positive      := 5;
    constant INIT           : integer       := 0;
    constant WORD_BIT     : positive        := 16;
    
    signal reset            : std_logic := '1';
    signal CE               : std_logic := '0';
    signal Data_in          : std_logic_vector(WORD_BIT-1 downto 0) := (others => '0');
    signal IIR_Dout         : std_logic_vector(WORD_BIT-1 downto 0) := (others => '0');
    
    signal clk              : std_logic := '1';
    
    component IIR is 
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
    end component;



begin
    
    clk <= not clk after period/2;

    IIR_tb : IIR 
    Generic map(
        TO_EXTEND       => TO_EXTEND,
        WORD_BIT        => WORD_BIT,
        INIT            => INIT
    )
    Port map(
        clk             => clk,
        reset           => reset,

        CE              => CE,

        Data_in         => Data_in,
        Data_out        => IIR_Dout
    );
    
    tb_stimulus : process
    begin
    
        wait for 100ns;
        
        reset <= '0';
        wait until rising_edge(clk);
           
        CE <= '1';
        Data_in <= x"00f0";
        wait for 32*10 ns;
        
        for I in 0 to 2**TO_EXTEND-1 loop
            Data_in <= x"0000";
            wait until rising_edge(clk);
        end loop;
        
        for I in 0 to 2**TO_EXTEND-1 loop
            --Data_in <= x"ffff";
            Data_in <= x"88ff";
            wait until rising_edge(clk);
        end loop;
        
        for I in 0 to 2**TO_EXTEND-1 loop
            Data_in <= x"0000";
            wait until rising_edge(clk);
        end loop;
                
        for I in 0 to 2**TO_EXTEND-1 loop
            Data_in <= x"8fff";
            wait until rising_edge(clk);
        end loop;   

        for I in 0 to 2**TO_EXTEND-1 loop
            Data_in <= x"0000";
            wait until rising_edge(clk);
        end loop;
                
        for I in 0 to 2**TO_EXTEND-1 loop
            Data_in <= x"ffff";
            wait until rising_edge(clk);
        end loop; 
        
        CE    <= '0';
        reset <= '1';
        wait for 100ns;
        
        reset   <= '0';
        CE      <= '1';
        Data_in <= x"00f0";
        wait until rising_edge(clk);
        
        CE      <= '0';
        wait for 100ns;
        
        CE      <= '1';
        wait for 110ns;

        CE      <= '0';
        wait for 100ns;

        CE      <= '1';
        wait for 200ns; 
        
        CE      <= '0';   
        
        wait for 100ns;
        
        reset   <= '1';
        wait for 100ns;
        
        reset  <= '0';
        
        wait for 100ns;
        
        wait;
    end process;

end Behavioral;