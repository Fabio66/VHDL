library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.NUMERIC_STD.ALL;

entity led_controller is
    Generic(
        WORD_BYTES : positive range 1 to 2; -- otherwise n of leds of basys3 not sufficient to display the information
        --N_WORDS    : positive;
        M_LEDS     : positive range 1 to 16
    );
    Port(
        areset : in std_logic;
        aclk   : in std_logic;

        -- m_axis_tvalid : out std_logic;
        -- m_axis_tdata  : out std_logic_vector(8*WORD_BYTES-1 downto 0);
        -- m_axis_tready : in std_logic;
        -- m_axis_tlast  : out std_logic

        s_axis_tvalid : in std_logic;
        s_axis_tdata  : in std_logic_vector(8*word_bytes-1 downto 0);
        s_axis_tready : out std_logic;
        s_axis_tlast  : in std_logic;

        led           : out std_logic_vector(8*WORD_BYTES-1 downto 0)
    );
end led_controller;

architecture Behavioral of led_controller is

    type STATE is (IDLE, GATHERING);
    
    signal engine : STATE := IDLE;

    -- signal prev_word : std_logic_vector(8*WORD_BYTES-1 downto 0) := (Others => '0');

begin

    with engine select s_axis_tready <=
    '0' when IDLE,        
    '1' when GATHERING;
        
    

    process (aclk, areset)
        variable prev_word : std_logic_vector(8*WORD_BYTES-1 downto 0);
    begin
        if areset = '1' then 
            engine <= IDLE;
            led    <= (Others => '0');

        elsif rising_edge(aclk) then
            
            case engine is 
                
                when IDLE =>
                    engine <= GATHERING;
                
                when GATHERING =>
                    if s_axis_tvalid = '1' and s_axis_tlast = '0' then
                        prev_word := s_axis_tdata & (others => '0');
                    
                    elsif s_axis_tvalid = '1' and s_axis_tlast = '0' then
                        prev_word(7 downto 0) := s_axis_tdata;
                        led <= prev_word;
                    end if;
            end case;
        end if;

    end process;

end architecture;
