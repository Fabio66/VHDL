-- Delta = Ton/(Period+1)
-- We set Delta = 1 if Ton > (Period+1)  obviously

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity PWM is 
    Generic(
        BIT_LENGTH      : integer range 1 to 16 := 8;           --Bit used inside the PWM
        
        T_on_init       : integer := 64;                        --Ton init
        Period_init     : integer := 128;                       --Init of period

        PWM_INIT        : std_logic := '0'                      --Init of PWM
    );
    Port(
        reset           : in    std_logic;
        clk             : in    std_logic;

        Ton             : in    std_logic_vector(BIT_LENGTH-1 downto 0);    -- clk at PWM = '1'
        Period          : in    std_logic_vector(BIT_LENGTH-1 downto 0);    -- clk per period of PWM

        PWM             : out   std_logic                                   --PWM SIGNAL
    );
end PWM;



architecture Behavioral of PWM is

    signal count : integer range 0 to Period_init := 0;


begin

    PWM_engine : process(clk, reset)
    
    begin
        if reset = '1' then
            PWM  = PWM_INIT;
            count = 0;

        elsif rising_edge(clk) then
            
            count <= count + 1;
            if unsigned(Ton) < unsigned(Period) then
                if count = to_integer(unsigned(Ton)) then
                    PWM     <= not PWM;
                elsif count = to_integer(unsigned(Period)) then
                    count   <= 0;
                    PWM     <= not PWM;
                end if;
            else 
                if count = to_integer(unsigned(Period)) then
                    PWM     <= not PWM;
                    count   <= 0;
                end if;
            end if;
        end if;
    
    end process PWM_engine;


end Behavioral;