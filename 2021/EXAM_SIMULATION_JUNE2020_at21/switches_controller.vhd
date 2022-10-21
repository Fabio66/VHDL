library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity switches_controller is
    Generic(
        CLK_FREQ : integer := 100_000_000;
        N_SWITCHES : integer range 1 to 16;
        WORD_BYTES : integer range 1 to 16;

        TIME_TO_COUNT : integer := 1
    );
    port (
        areset : in std_logic;
        aclk   : in std_logic;

        switches : in std_logic_vector(N_SWITCHES-1 downto 0);

        m_axis_tvalid : out std_logic;
        m_axis_tdata  : out std_logic_vector(8*WORD_BYTES-1 downto 0);
        m_axis_tready : in std_logic;
        m_axis_tlast  : out std_logic
    );
end switches_controller;

architecture Behavioral of switches_controller is

    constant clk_cycles : integer := CLK_FREQ/TIME_TO_COUNT;
    constant n_transactions : integer := N_SWITCHES/WORD_BYTES - 1;

    signal time_counter : integer range 0 to clk_cycles-1;

    type STATE is (IDLE, WAITING, SETTING, SENDING);

    signal engine : STATE := IDLE;

    signal switch_reg : std_logic_vector(N_SWITCHES-1 downto 0);

begin
    
    with engine select m_axis_tvalid <=
        '0' when IDLE,
        '0' when WAITING,
        '0' when SETTING,
        '1' WHEN SENDING;

    process (aclk, areset)
    begin
        if areset = '1' then
            engine <= IDLE;
            time_counter <= 0;

        elsif rising_edge(aclk) then
            case engine is 
                when IDLE =>
                    engine <= WAITING;
                
                when WAITING =>
                    time_counter <= time_counter + 1;

                    if time_counter = clk_cycles then 
                        time_counter <= 0;
                        switch_reg <= switches;

                        engine  <= SETTING;
                    end if;
                
                when SETTING =>
                    time_counter <= time_counter + 1;
                    m_axis_tdata <= switch_reg(switches'HIGH downto 8);

                    if time_counter = n_transactions then
                        m_axis_tdata <= switch_reg(8 downto 0);
                        m_axis_tlast <= '1';
                    end if;

                    engine <= SENDING;
                    
                when SENDING =>
                        if m_axis_tready = '1' then
                            engine <= SETTING;

                            if time_counter = n_transactions + 1 then
                                time_counter <= 0;
                                engine <= WAITING;
                            end if;

                        end if;
            end case;
        end if;
    end process;
    

end architecture;