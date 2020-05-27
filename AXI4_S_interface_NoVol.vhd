library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity no_vol_dx_sx is 
    generic(
        WORD_BYTES      : positive         := 2
    );
    port(
        aclk        : in std_logic;
        aresetn     : in std_logic;

        mute_left        : in std_logic;
        mute_right        : in std_logic;

        --AXI4_S interfaces
        --SLAVE
        s_axis_tdata       :  in std_logic_vector(8*WORD_BYTES-1 downto 0);
        s_axis_tvalid      :  in std_logic;
        s_axis_tready      :  out std_logic;
        s_axis_tlast       :  in std_logic;

        --MASTER
        m_axis_tvalid      :  out std_logic;
        m_axis_tready      :  in std_logic;
        m_axis_tdata       :  out std_logic_vector(8*WORD_BYTES-1 downto 0);
        m_axis_tlast       :  out std_logic
    );
end no_vol_dx_sx;

architecture Behavioral of no_vol_dx_sx is

    constant    nosound         :       std_logic_vector(8*WORD_BYTES-1 downto 0)   := (others => '0');
    signal      button_pres     :       std_logic_vector(2 downto 0)      := "000";
    signal      reset           :       std_logic;

    type FSM_STATES is (IDLE, SAMPLING, CHOOSING, SENDING);
    signal STATE : FSM_STATES := IDLE;
    
    signal m_axis_tdata_sampled : std_logic_vector(8*WORD_BYTES-1 downto 0) := nosound;

begin

    reset <= not aresetn;

    with STATE select s_axis_tready <=
        '0' when IDLE,
        '1' when SAMPLING,
        '0' when CHOOSING,
        '0' when SENDING;

    with STATE select m_axis_tvalid <=
        '0' when IDLE,
        '0' when SAMPLING,
        '0' when CHOOSING,
        '1' when SENDING;
    
    process(aclk)

    begin 
        if reset = '1' then
            STATE <= IDLE;

        elsif rising_edge(aclk) then
            
            --button_pres <= (mute_left or mute_right) & s_axis_tlast; --sampling to avoid oscillations

            case STATE is 

                when IDLE =>
                    STATE <= SAMPLING;

                when SAMPLING =>
                    if s_axis_tvalid = '1' then
                       
                        m_axis_tlast                <= s_axis_tlast; --Possiamo farlo qui, tanto rimane invariato
                        m_axis_tdata_sampled        <= s_axis_tdata;
                        --We can set the output m_axis_tdata to the right value without waiting for something in particular, 
                        --the important part is that we can't change it until the handshake
                       
                        button_pres <= mute_left & mute_right & s_axis_tlast;
                        --button_pres(2 downto 2)     <= mute_left;
                        --button_pres(1 downto 1)     <= mute_right;
                        --button_pres(0 downto 0)     <= s_axis_tlast;
                        
                        --In this State, we sample s_axis_tlast and s_axis_tdata and we set the path control variable to the "right" value--

                        STATE <= CHOOSING;

                    end if;

                when CHOOSING =>
                    
                    case button_pres is 

                        --  In these cases we simply have to put the input to the output --
                            --when "000" =>
                            --when "001" =>
                            --when "010" =>
                            --when "101" =>
                        -- We put them in when others so that even in the other case of std_logic we have all specified

                        when "100" =>
                            m_axis_tdata <= nosound;
                        when "011" =>
                            m_axis_tdata <= nosound;
                        when "110" =>
                            m_axis_tdata <= nosound;
                        when "111" =>
                            m_axis_tdata <= nosound;
                        when others =>
                            m_axis_tdata <= m_axis_tdata_sampled;
                    
                    end case;  

                    STATE <= SENDING;

                when SENDING => 
                    if m_axis_tready = '1' then
                        STATE <= SAMPLING;
                    end if;
            end case;
        end if;
    end process;

end Behavioral;