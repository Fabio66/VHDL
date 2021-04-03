library IEEE;
	use IEEE.STD_LOGIC_1164.all;
	use IEEE.NUMERIC_STD.ALL;

entity tb_KITT is 
end tb_KITT;

architecture Behavioral of tb_KITT is

    constant clk_period : time          := 10 ns;
    constant reset_wnd  : time          := 100 ns;

    constant sw0        : std_logic_vector          := (Others =>'0');

    constant SW_N_DUT   : integer       := 16;
    constant LED_N_DUT  : integer       := 16;
    

    signal clk          : std_logic         := '1';
    signal reset        : std_logic         := '0';

    signal switches     : std_logic_vector(SW_N_DUT-1 downto 0)         := sw0;
    signal LEDs         : std_logic_vector(0 to LED_N_DUT-1)            := (Others => '0');


    ---------------------------------------------------------------
    component KITT is 
        Generic(
            SW_N        : integer range 0 to 16;
            LED_N       : integer range 2 to 16
        );
        Port(
            clk         :   in std_logic;
            reset       :   in std_logic;
    
            switches    :   in std_logic_vector(SW_N-1 downto 0);
            LEDs        :   out std_logic_vector(0 to LED_N-1)
        );
    end component;
    ---------------------------------------------------------------

begin

    kitt_0 : KITT
        Generic map (
            SW_N    =>  SW_N_DUT,
            LED_N   =>  LED_N_DUT
        )
        Port map (
            clk     =>  clk,
            reset   =>  reset,
            
            switches    =>  switches,
            LEDs        =>  LEDs
        );

    clk <= not clk after clk_period/2;

    --process(clk,reset)
    process 
    begin
        reset <= '1';
        wait for 5*reset_wnd;
        
        reset <= '0';
        wait for 32*clk_period;

        switches <= "0000000000000001";
        wait for 320*clk_period; 

        wait;
    end process;    
end Behavioral;