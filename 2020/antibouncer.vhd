library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity antibouncer is
    generic(
        SAFE_BIT             := positive := 2
    );
    port(
        clk                  : in std_logic;
        --reset not really needed

        switch_x             : in std_logic;
        switch_x_sampled     : out std_logic
    );
end antibouncer;

--not that proud of this architecture.
architecture Behavioral of antibouncer is

    signal disable_count : integer range 0 to 2**SAFE_BIT := 0;

begin

    SAMPLE : process(clk, switch_x)
    
    begin
    
        if rising_edge(clk) then
            if count = 0 then
                switch_x_sampled <= switch_x;
                count <= 1;
            elsif count >= 1 then
                count <= count + 1;
            else count = 2**SAFE_BIT then 
                count <= 0;
            end if;
    end process;
end Behavioral;