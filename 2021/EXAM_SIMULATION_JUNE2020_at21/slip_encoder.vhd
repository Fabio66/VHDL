library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity slip_encoder is
    Generic (
        WORD_BYTES : positive range 1 to 2
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
end slip_encoder;

architecture Behavioral of slip_encoder is

    type STATE is (IDLE, GET_WORD, SEND_WORD, SEND_ESC, SEND_ESC_END, SEND_ESC_ESC);

    signal STATUS : STATE := IDLE;

    signal previous_word : std_logic_vector(8*WORD_BYTES-1 downto 0);
    -- signal current_word  : std_logic_vector(8*WORD_BYTES-1 downto 0);

    signal tlast_reg : std_logic := '0';
    -- signal tlast_regreg : std_logic := '0';

begin

    process (aclk,areset)
    begin
        if areset ='1' then

        elsif rising_edge(aclk) then
            
            case STATUS is
                when IDLE =>
                    STATUS <= GET_WORD;

                when GET_WORD       =>
                    if s_axis_tvalid = '1' then
                        previous_word <= s_axis_tdata;
                        tlast_reg     <= s_axis_tlast;
                        if s_axis_tdata = x"C0" or s_axis_tdata = x"DB" then
                            m_axis_tdata <= x"DB"; 
                            STATUS <= SEND_ESC;
                        else
                            m_axis_tdata <= s_axis_tdata;
                            STATUS <= SEND_WORD;
                        end if;
                    end if;
                
                when SEND_WORD      =>
                    if m_axis_tready = '1' then    
                        if tlast_reg = '0' then 
                            STATUS <= GET_WORD;
                        else 
                            previous_word <= x"00"; -- giusto per sicurezza
                            m_axis_tdata <= x"C0";
                            m_axis_tlast <= '1';

                            STATUS <= SEND_ESC;
                        end if;
                    end if;

                when SEND_ESC       =>
                    if m_axis_tready = '1' then

                        STATUS <= GET_WORD;

                        if previous_word = x"C0" then
                            m_axis_tdata <= x"DC";
                            STATUS <= SEND_ESC_ESC;
                        end if;
                        
                        if previous_word = x"DB" then
                            m_axis_tdata <= x"DD";
                            STATUS <= SEND_ESC_END;
                        end if;
                        
                        previous_word <= x"00";
                            
                    end if;

                when SEND_ESC_END   =>
                        if m_axis_tready = '1' then
                            if tlast_reg = '0' then
                                STATUS <= GET_WORD;
                            end if;
                            if tlast_reg = '1' then
                                m_axis_tdata <= x"C0";
                                m_axis_tlast <= '1';

                                STATUS <= SEND_ESC;
                            end if;
                        end if;

                when SEND_ESC_ESC   =>
                        if m_axis_tready = '1' then
                            if tlast_reg = '0' then
                                STATUS <= GET_WORD;
                            end if;
                            if tlast_reg = '1' then
                                m_axis_tdata <= x"C0";
                                m_axis_tlast <= '1';
                                
                                STATUS <= SEND_ESC;
                            end if;
                        end if;                          

                end case;

        end if;
    end process;

end architecture;