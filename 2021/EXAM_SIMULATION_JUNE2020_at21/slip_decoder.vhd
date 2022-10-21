library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity slip_decoder is
    Generic (
            word_bytes : positive range 1 to 2
    );
    Port (
        areset : in std_logic;
        aclk   : in std_logic;

        m_axis_tvalid : out std_logic;
        m_axis_tdata  : out std_logic_vector(8*WORD_BYTES-1 downto 0);
        m_axis_tready : in std_logic;
        m_axis_tlast  : out std_logic;

        s_axis_tvalid : in std_logic;
        s_axis_tdata  : in std_logic_vector(8*word_bytes-1 downto 0);
        s_axis_tready : out std_logic;
        s_axis_tlast  : in std_logic
    );
end slip_decoder;

architecture Behavioral of slip_decoder is

    type STATE is (IDLE, GET_WORD_1, GET_WORD_2, SEND_WORD);
    signal decoder_state : STATE := IDLE;

    signal current_word : std_logic_vector(8 downto 0);
    signal previous_word : std_logic_vector(8 downto 0);

    signal packet_end : std_logic := '0';

begin   

process (aclk,areset)
begin
    if areset = '1' then
        decoder_state <= IDLE;

    elsif rising_edge(aclk) then
        case decoder_state is
            when IDLE =>
                decoder_state <= GET_WORD_1;

            when GET_WORD_1 =>

                packet_end <= '0';

                if s_axis_tvalid = '1' then
                    current_word  <= s_axis_tdata;
                    if s_axis_tdata = x"C0" then 
                        packet_end <= '1';
                    end if;

                    decoder_state <= GET_WORD_2;
                end if;

            when GET_WORD_2 =>
                if packet_end = '1' then
                    --Il pacchetto non ha elementi
                    decoder_state <= GET_WORD_1;
                end if;

                if s_axis_tvalid = '1' then 
                    previous_word <= s_axis_tdata;
                    if current_word = x"DB" and s_axis_tdata = x"DC" then
                        current_word <= x"C0";
                        decoder_state <= GET_WORD_2;
                    elsif current_word = x"DB" and s_axis_tdata = x"DD" then 
                        current_word  <= x"DB";
                        decoder_state <= GET_WORD_2;
                    else 
                        m_axis_tdata <= current_word;
                        decoder_state <= SEND_WORD;
                    end if;
                    if s_axis_tdata = x"C0" then
                        m_axis_tlast <='1';
                    else
                        m_axis_tlast <= '0';
                    end if;
                end if;

            when SEND_WORD =>
                if m_axis_tready = '1' then
                    if previous_word = x"C0" then
                        decoder_state <= GET_WORD_1;
                    else 
                        current_word <= previous_word;
                        decoder_state <= GET_WORD_2;
                    end if;
                end if;
        end case;
    end if;
end process;

    

end architecture;