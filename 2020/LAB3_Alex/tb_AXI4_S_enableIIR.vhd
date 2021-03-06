library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
    -- Port();
end top;

architecture Behavioral of top is 

    --------------------CONSTANTS-------------------
    
    constant PERIOD     : time := 10ns;
    
    constant IIR_MEAN       : positive := 5;
    constant WORD_BIT       : positive := 16;
    constant IIR_INIT_VAL   : integer  := 0;


    --------------------SIGNALS---------------------
    
    signal aclk             : std_logic := '1';
    signal resetn           : std_logic := '0';

    signal enable_filter    : std_logic := '1';

    --AXI4-S Interface signals

    --SLAVE_interface signals
    signal s_axis_tvalid   : std_logic := '0';
    signal s_axis_tready   : std_logic := '0';
    signal s_axis_tdata    : std_logic_vector(WORD_BIT-1 downto 0) := "0000000000000000"; -- := x"0000";
    signal s_axis_tlast    : std_logic := '0';
            
    --MASTER_interface signals
    signal m_axis_tvalid   : std_logic := '0';
    signal m_axis_tready   : std_logic := '0';
    signal m_axis_tdata    : std_logic_vector(WORD_BIT-1 downto 0) := "0000000000000000";
    signal m_axis_tlast    : std_logic := '0';

    component AXI4_S_interface_FSM is 
        Generic(
            IIR_MEAN        : positive         := 5;  --2**IIR_MEAN = number of elements to weight
            WORD_BIT        : positive         := 16; --Length in bytes of the words in input
            IIR_INIT_VAL    : integer          := 0   --Initial Value of the filter, just if for some reason we do not want to begin with 0.
        );
        Port(
            aclk            : in std_logic;
            resetn          : in std_logic;
    
            enable_filter   : in std_logic;
            
            --AXI4-S Interface pins
            --SLAVE_interface
            s_axis_tvalid   : in  std_logic;
            s_axis_tready   : out std_logic;
            s_axis_tdata    : in  std_logic_vector(WORD_BIT-1 downto 0);
            s_axis_tlast    : in  std_logic;
            
            --MASTER_interface
            m_axis_tvalid   : out std_logic;
            m_axis_tready   : in  std_logic;
            m_axis_tdata    : out std_logic_vector(WORD_BIT-1 downto 0);
            m_axis_tlast    : out std_logic
        );
    end component;

begin

    ------ACLK-----------------------
    aclk <= (not aclk) after PERIOD/2;
    ---------------------------------

    --INSTANTIATION

    FSM_AXI4_S_interface_IIRs_tb : AXI4_S_interface_FSM
        
        generic map(    
            IIR_MEAN        => IIR_MEAN,
            WORD_BIT        => WORD_BIT,
            IIR_INIT_VAL    => IIR_INIT_VAL       
        )        
        port map(
            aclk            => aclk,
            resetn          => resetn,

            enable_filter   => enable_filter,

            s_axis_tvalid   => s_axis_tvalid,
            s_axis_tready   => s_axis_tready,
            s_axis_tdata    => s_axis_tdata,
            s_axis_tlast    => s_axis_tlast,
            
            m_axis_tvalid   => m_axis_tvalid,
            m_axis_tready   => m_axis_tready,
            m_axis_tdata    => m_axis_tdata,
            m_axis_tlast    => m_axis_tlast
        );

    stimulus : process
    
    begin

        wait for 100ns;
        resetn <= '1';
        wait for PERIOD;

        ---NB!!---  We obviously can drive only the input pins  ---NB!---
        --s_axis_tvalid   <= '0';  --correct!! it is indeed an input
        --s_axis_tready   <= '1';  it is not an input!
        
        --WE WILL SET THE TDATA INPUT AT THIS VALUE FOR ALL THE SIMULATION

        ---------------------------
        s_axis_tdata    <= x"00f0"; 
        ---------------------------
        --s_axis_tlast    <= '0';

        s_axis_tvalid <= '1';
        wait for 100ns;

        --SX IIR TEST

        for I in 0 to 2*2**IIR_MEAN loop
            
            s_axis_tvalid <= not s_axis_tvalid;
            wait until rising_edge(aclk);
            m_axis_tready <= '1';
            wait until rising_edge(aclk);
            m_axis_tready <= '0';
            wait for 4*PERIOD;
        end loop;

        --DX IIR TEST
        
        s_axis_tlast <= not s_axis_tlast;
        wait for 10*PERIOD;

        for I in 0 to 2*2**IIR_MEAN loop

            s_axis_tvalid <= not s_axis_tvalid;
            wait until rising_edge(aclk);
            m_axis_tready <= '1';
            wait until rising_edge(aclk);
            m_axis_tready <= '0';
            wait for 4*PERIOD;
        end loop;

        --Filter not enable, input ot output "directly"
        enable_filter <= '0';
        s_axis_tdata  <= x"4321";
        wait for 10ns;
        --Try on SX
        s_axis_tlast <= '0';
        wait for 10ns;

        for I in 0 to 2*2**IIR_MEAN loop

            s_axis_tvalid <= not s_axis_tvalid;
            wait until rising_edge(aclk);
            m_axis_tready <= '1';
            wait until rising_edge(aclk);
            m_axis_tready <= '0';
            wait for 4*PERIOD;
        end loop;
        
        m_axis_tready <= '1';  
        s_axis_tlast <= '1';
        wait for 10ns;
        
        for I in 0 to 2*2**IIR_MEAN loop

            s_axis_tvalid <= not s_axis_tvalid;
            wait until rising_edge(aclk);
            
        end loop;

        wait;
    end process stimulus;




end Behavioral;