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
        s_axis_tdata       :  in signed(8*WORD_BYTES-1 downto 0);
        s_axis_tvalid      :  in std_logic;
        s_axis_tready      :  out std_logic;
        s_axis_tlast       :  in std_logic;

        --MASTER
        m_axis_tvalid      :  out std_logic;
        m_axis_tready      :  in std_logic;
        m_axis_tdata       :  out signed(8*WORD_BYTES-1 downto 0);
        m_axis_tlast       :  in std_logic;

    );
end no_vol;

architecture Behavioral of no_vol_dx_sx is

    constant    nosound         :       signed(8*WORD_BYTES-1 downto 0)   := (others => '0');
    signal      button_pres     :       std_logic                         := 0;
    signal      reset           :       std_logic;

    type FSM_STATES is (IDLE, CHOOSING, SENDING);
    signal STATE : FSM_STATES := IDLE;

    signal swap_m : std_logic_vector(1 downto 0) := '00'; --not muting at all at the reset state

begin

    reset <= not aresetn;

    with STATE select s_axis_tready =>
        '0' IDLE,
        '1' CHOOSING,
        '0' SENDING;

    with STATE select m_axis_tvalid =>
        '0' IDLE,
        '0' CHOOSING,
        '1' SENDING;

    
    process(clk)

    begin 
        if reset = '1' then
            STATE <= IDLE;
            swap_m <= '00';

        elsif rising_edge(clk) then
            
            button_pres <= mute_left or mute_right; --sampling to avoid oscillations

            case STATE is 

                when IDLE =>
                    STATE <= CHOOSING;

                when CHOOSING =>
                    if s_axis_tvalid = '1' then
                       
                        m_axis_tlast <= s_axis_tlast; --Possiamo farlo qui, tanto rimane invariato
                        
                        --We can set the output m_axis_tdata to the right value without waiting for something in particular, 
                        --the important part is that we can't change it until the handshake

                        --s_axis_tlast = '1' => RIGHT CHANNEL 
                        --s_axis_tlast = '0' => LEFT CHANNEL 

                        if mute_left = '1' & mute_right = '0' & s_axis_tlast = '0' then    -- mute dx
                            m_axis_tdata <= (others => '0'); 
                        
                        elsif mute_right = '1' & mute_left = '1' & s_axis_tlast = '1' then -- mute sx
                            m_axis_tdata <= (others => '0'); 
                        
                        elsif button_pres = '1' then  --mute both
                            m_axis_tdata <= (others => '0');
                        
                        else 
                            m_axis_tdata <= s_axis_tdata; -- do not mute at all                       
                        end if;

                        STATE <= SENDING;

                    end if;

                when SENDING => 
                    if m_axis_tready = '1' then
                        STATE <= CHOOSING;
                    end if;

        end if;



    end process;

end Behavioral;