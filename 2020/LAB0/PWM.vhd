-- Delta = Ton/(Period+1)
-- We set Delta = 1 if Ton > (Period+1)  obviously

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity PWM is 
    Generic(
        BIT_LENGTH      : integer range 1 to 16 := 8;       -- Bit used inside PWM
        T_ON_INIT       : positive      := 64;              -- Init of Ton
        PERIOD_INIT     : positive      := 128;             -- Init of Period
        PWM_INIT        : std_logic     := '0';             -- Init of PWM
    );
    Port(
        reset           : in    std_logic;
        clk             : in    std_logic;

        Ton             : in    std_logic_vector(BIT_LENGTH-1 downto 0);        -- clk at PWM = '1'
        Period          : in    std_logic_vector(BIT_LENGTH-1 downto 0);        -- clk per period of PWM

        PWM             : out   std_logic                                       --PWM SIGNAL
    );
end PWM;

architecture Behavioral of PWM is

    constant T_ON_INIT_UNS      : unsigned(BIT_LENGTH-1 downto 0)       := to_unsigned(T_ON_INIT-1, BIT_LENGTH);
    constant PERIOD_INIT_UNS    : unsgined(BIT_LENGTH-1 downto 0)       := to_unsigned(T_ON_INIT-1, BIT_LENGTH);

    signal Ton_reg              : unsigned(BIT_LENGTH-1 downto 0)       := T_ON_INIT_UNS;
    signal Period_reg           : unsigned(BIT_LENGTH-1 downto 0)       := PERIOD_INIT_UNS;
    signal count                : unsigned(BIT_LENGTH-1 downto 0)       := (Others => '0');
    signal pwm_reg              : std_logic                             := PWM_INIT;

begin

    PWM_engine : process(clk, reset)
    
    begin
        if reset = '1' then 
            Ton_reg <= T_ON_INIT_UNS;
            Period_reg <= PERIOD_INIT_UNS;
            count <= (Others => '0');
            pwm_reg <= PWM_INIT;

        elsif rising_edge(clk) then 
            count <= count + 1;
            if count = unsigned(Period_reg) then 
                count <= (Others => '0');
                pwm_reg <= PWM_INIT;
                Period_reg <= unsigned(Period);
                Ton_reg  <= unsigned(Ton);
            end if;
            if count = Ton_reg-1 then 
                pwm_reg <= not PWM_INIT;
            end if;

            --Particular cases, like limit cases... They have to be taken into account separately 

            if Ton_reg = 0 then
                pwm_reg <= not PWM_INIT;
            end if;

            if Ton_reg > Period_reg then
                pwm_reg <= PWM_INIT;
            end if;
        end if;        
    end process PWM_engine;
end Behavioral;

-- So, how does this Entity work? -> We have to instantiate a module that provides at his output a single bit pwm.
-- To do this we need some generics, like Ton_init that tells us how much with respect to the period will the signal stay high/low (depending on PWM_INIT, that tells us if we are developing a "high 
-- driving pwm" or a "low driving pwm"), Period_init that tells us how much is the period and BIT_LENGTH that tells us how many bits are required to our counters and circuits to correctly create a pwm module
-- through this way of implementation

-- There are 5 ports in this entity, 4 inptus and 1 output, namely clk and reset, the inputs to correctly realize the Ton/Period+1 (delta) not fixed and the exit, pwm.

-- If we set the rest high we proceed to impose the delta as in the first cycle after the turning on of the device, so with our generics, namely
-- Ton_reg <= T_ON_INIT_UNS, Period_reg <= PERIOD_INIT_UNS.. we set the counter to 0 and the output to the choosen (with generics as said above) input.

-- In this solution we simply use a counter and we choose from different cases looking at this counter. The two limit cases have to be taken into account separately cause of this.
-- On every rising_edge of the clk signal, we increment the counter by 1, so we are counting the total number of clock cycle passed, from 0 to 2**BIT_LENGTH - 1 = PERIOD and if we reached PERIOD or Ton 
-- numbers of clk rising_edges we have to, in the first case we have finished a PERIOD of the PWM, (signal to transmit at the output) and we have to begin another cycle, in the second case we have reached 
-- the time in which we have to change the polarity of the output, passing from PWM_INIT to not PWM_INIT, (for instance from 1 to 0), and then wait to reach a PERIOD of clocks (from Ton periods in which
-- we are now). The limit cases are when delta = 0 and when for some reasons we get at the inputs a delta greater than one, namely Ton > Period (Period+1 to be precise).