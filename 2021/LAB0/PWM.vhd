library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- We have to consider that Delta = T_ON_INIT/(PERIOD_INIT+1) = T_ON/(PERIOD+1)
-- If T_ON_INIT >= PERIOD_INIT ===> Delta = 1 obviously.

entity PWM is 
    Generic(
        BIT_LENGTH      : INTEGER RANGE 1 TO 16 := 8;               -- Bit used inside PWM
        T_ON_INIT       : POSITIVE := 64;                           -- Init of Ton
        PERIOD_INIT     : POSITIVE := 128;                          -- Init of Period
        PWM_INIT        : STD_LOGIC:= '0'                           -- Init of PWM
    );
    Port(
        reset           : IN STD_LOGIC;
        clk             : IN STD_LOGIC;

        Ton             : IN STD_LOGIC_VECTOR(BIT_LENGTH-1 downto 0);       -- clk at PWM = '1'
        Period          : IN STD_LOGIC_VECTOR(BIT_LENGTH-1 downto 0);       -- clk per period of PWM

        PWM             : OUT STD_LOGIC                                     -- PWM signal
    );
end PWM;

-- PWM_INIT tells us the initial value of the PWM output signal, that is, initially low or high
-- T_ON_INIT is time (fraction of PERIOD_INIT) on which the PWM output stays high/low

architecture Behavioral of PWM is 

    constant T_ON_INIT_UNS      : unsigned(BIT_LENGTH-1 downto 0)       := to_unsigned(T_ON_INIT-1, BIT_LENGTH);        --this are the two generics that provide the period length and uptime of the pwm
    constant PERIOD_INIT_UNS    : unsigned(BIT_LENGTH-1 downto 0)       := to_unsigned(PERIOD_INIT-1, BIT_LENGTH);      --converted in unsigneds to be directly used in the architecture
                                                                                                                        --why to_unsigned(T_ON_INIT-1, BIT_LENGTH); ? Cause 0 -> T_ON_INIT-1 => 
                                                                                                                        --exactly T_ON_INIT clock periods "of uptime"

    signal count                : unsigned(BIT_LENGTH-1 downto 0)       := (Others => '0');
    
    signal Ton_reg              : unsigned(BIT_LENGTH-1 downto 0)       := T_ON_INIT_UNS;
    --signal T_ON_un              : unsigned(BIT_LENGTH-1 downto 0)       :=  to_unsigned(T_ON_INIT,BIT_LENGTH);
    signal Period_reg           : unsigned(BIT_LENGTH-1 downto 0)       := PERIOD_INIT_UNS;
    --signal PERIOD_un            : unsigned(BIT_LENGTH-1 downto 0)       :=  to_unsigned(PERIOD_INIT,BIT_LENGTH);
    
    signal pwm_reg              : std_logic     := PWM_INIT;


begin

    PWM <= pwm_reg;
    
    process(clk, reset)
    begin
        if reset = '1' then
            count       <=  (Others => '0');
            PWM         <=  PWM_INIT;
            pwm_reg     <=  PWM_INIT;
        
        elsif rising_edge(clk) then
            
            count   <=  count + 1;

            if count = Ton_reg then
                PWM     <=  not pwm_reg;
            elsif count = Period_reg then
                PWM     <=  pwm_reg;
                count   <=  (Others => '0');
            end if;

            if Ton_reg > Period_reg then
                PWM     <= PWM_INIT;
            end if;
            if Ton_reg = 0 then
                PWM     <= not PWM_INIT;
            end if;
                
        end if;
    end process;

end Behavioral;