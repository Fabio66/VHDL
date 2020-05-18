library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

    -- So, in this project we want to retrive bytes from the pc, (through) the master AXI4-S interface
    -- m00_axis_rx_tvalid => m00_axis_rx_tvalid,
    -- m00_axis_rx_tdata => m00_axis_rx_tdata,
    -- m00_axis_rx_tready => m00_axis_rx_tready,
    -- and then sum this bytes, giving them back to the pc through the slave AXI4-S interface of our module
    -- s00_axis_tx_tready => s00_axis_tx_tready,
    -- s00_axis_tx_tdata => s00_axis_tx_tdata,
    -- s00_axis_tx_tvalid => s00_axis_tx_tvalid


entity top is
    --it is nice to have the generic list to change the addition value, the constant that we want to add to the incoming
    --bytes (from the PC)
    Generic(
        --A number with a fixed range to be summed with the incoming signal
        SUM_VALUE : integer range 0 to 255 --; --only sensed value cause the incoming values are 8 bit numbers, so they
        --will overflow if there is not a limit to the constant that we are adding
    );
    Port (
        clk       : in std_logic;
        btnC      : in std_logic;
        --even if we don't need a reset in the design, ideally, we should always put one
        -- in general it is good to add a reset
        
        RsRx      : in std_logic;
        RsTx      : out std_logic
        -- ports to communicate with the serial communication
    );
end top;

architecture Behavioral of top is

    -- this tells vivado that the components has this ports
    COMPONENT AXI4Stream_UART_0
      PORT (
        clk_uart : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        UART_TX : OUT STD_LOGIC;
        UART_RX : IN STD_LOGIC;

        m00_axis_rx_aclk : IN STD_LOGIC;
        m00_axis_rx_aresetn : IN STD_LOGIC;
        m00_axis_rx_tvalid : OUT STD_LOGIC;
        m00_axis_rx_tdata : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        m00_axis_rx_tready : IN STD_LOGIC;
        
        s00_axis_tx_aclk : IN STD_LOGIC;
        s00_axis_tx_aresetn : IN STD_LOGIC;
        s00_axis_tx_tready : OUT STD_LOGIC;
        s00_axis_tx_tdata : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        s00_axis_tx_tvalid : IN STD_LOGIC
      );

    END COMPONENT;
      
    signal reset    : std_logic;
    -- we need a negative reset
    signal resetn   : std_logic;
    
    --called in the same name as in the module/component just for clarity
    signal m00_axis_rx_tready : std_logic;
    signal m00_axis_rx_tvalid : std_logic;
    signal m00_axis_rx_tdata  : std_logic_vector(7 downto 0);
    
    signal s00_axis_tx_tready : std_logic;
    signal s00_axis_tx_tvalid : std_logic;
    signal s00_axis_tx_tdata  : std_logic_vector(7 downto 0);

    type state_type is (IDLE, RECEIVE, TRANSMIT);

    signal STATE              : state_type  := IDLE; --initialization to IDLE, so that automatically starts from IDLE
      
begin
    reset  <= btnC;
    resetn <= not reset;
    --WE WILL USE MOORE FSM, SO THE OUTPUTS DEPEND ONLY ON THE STATE IN WHICH WE ARE AT THAT PARTICULAR CLOCK CYCLE
    --In the receive state we wants to receive a byte and we do not want to transmit anything!
    -- In this state (RECEIVE) m00_axis_tvalid will be 0 and s00_axis_tready will be 1
    --m00_axis_tvalid  = 0 means that we are still receiving the data that will be put inside the FPGA through the 
    --AXI4-Stream interface (master)
    --s00_axis_tvalid = 1 means that we are waiting (putting ourselves in the Slave interface) for a valid data coming 
    --from the inside of the FPGA or, in the case of the loopback configuration, from the Master interface.
    --"REMEMBER THAT WE ALWAYS HAVE TO PUT AN IDLE STATE THAT WILL BE NEEDED TO BE ABLE TO RESET CORRECTLY THE FSM"
    --We have to stay in the RECEIVE state as long as there is not incoming data and we move to the TRANSMIT state when
    --there is new data coming to us.
    --In the TRANSMIT state everything is symmetrical  : while m00_axis_tready = 0 we stay in the current state
    --until m00_axis_tready = 1, that means we have to go back to te RECEIVE state.
    --m00_axis_tvalid = 1 means that the master interface ( the one that is receiving from the PC) has is output valid
    --that is, data can be trasnmitted through the internal circuitry
    --s00_axis_tready = 0 means that the slave interface , the one that will be sending back the Data to the pc
    --is not ready to perform a  transition and take in data.


    uart : AXI4Stream_UART_0
      PORT MAP (
        clk_uart => clk,
        rst => reset,
        UART_TX => RsTx,
        UART_RX => RsRx,
        ----------------------------------------
        m00_axis_rx_aclk => clk,
        m00_axis_rx_aresetn => resetn,
        m00_axis_rx_tvalid => m00_axis_rx_tvalid,
        m00_axis_rx_tdata => m00_axis_rx_tdata,
        m00_axis_rx_tready => m00_axis_rx_tready,
        -----------------------------------------
        s00_axis_tx_aclk => clk,
        s00_axis_tx_aresetn => resetn,
        s00_axis_tx_tready => s00_axis_tx_tready,
        s00_axis_tx_tdata => s00_axis_tx_tdata,
        s00_axis_tx_tvalid => s00_axis_tx_tvalid
      );

    -- So, in this project we want to retrive bytes from the pc, (through) the master AXI4-S interface
    -- m00_axis_rx_tvalid => m00_axis_rx_tvalid,
    -- m00_axis_rx_tdata => m00_axis_rx_tdata,
    -- m00_axis_rx_tready => m00_axis_rx_tready,
    -- and then sum this bytes, giving them back to the pc through the slave AXI4-S interface of our module
    -- s00_axis_tx_tready => s00_axis_tx_tready,
    -- s00_axis_tx_tdata => s00_axis_tx_tdata,
    -- s00_axis_tx_tvalid => s00_axis_tx_tvalid



    --the two AXI4-Stream interfaces are connected to each other
    s00_axis_tx_tdata <= m00_axis_rx_tdata;
    --when the master tvalid goes high, the slave tvalid goes high.
    s00_axis_tx_tvalid <= m00_axis_rx_tvalid;
    --when the slave is ready, the m00_axis_rx_tready goes high.
    m00_axis_rx_tready <= s00_axis_tx_tready;
    

    -- THERE ARE MANY WAYS TO DO THE EXERCISE, IN THIS WAY WE LOOSE A CLOCK CYCLE SO IT IS NOT THE BEST WAY 
    -- ONE WAY IS THROUGH THE FSM (finite state machines), THAT IS VERY FORMATIVE

    --n00_axis_rx_tready
    --s00_axis_tx_tvalid

    with STATE select m00_axis_rx_tready <= 
        '0' when IDLE,
        '1' when RECEIVE,
        '0' when TRANSMIT;

    with STATE select s00_axis_tx_tvalid <= 
        '0' when IDLE,
        '0' when RECEIVE,
        '1' when TRANSMIT;
    --with this 8 lines we describe what is in the circle diagram of FSM
    -- so the outputs signals for now have been defined with these combinatorial logic

    --here we describe how we move through these states.
    FSM_engine : process(clk, reset)
    
    begin

        if reset = '1' then

        elsif rising_edge(clk) then

            case STATE is 
                when IDLE =>
                    STATE <= RECEIVE;
                when RECEIVE =>
                    if m00_axis_rx_tvalid = '1' then
                        --operation to do here?
                            --we cannot sum std_logic_vectors! They are just chuncks of bit
                            --no need to convert to unsigned, unsigned + integer is allowed!!
                            --s00_axis_tx_tdata  <= std_logic_vector(unsigned(m00_axis_rx_tdata) + to_unsigned(SUM_VALUE,m00_axis_rx_tdata'LENGTH));
                        s00_axis_tx_tdata   <= std_logic_vector(unsigned(m00_axis_rx_tdata) + SUM_VALUE);
                        --next state is 
                        STATE <= TRANSMIT;
                    end if;
                when TRANSMIT =>
                    --WHEN s00_axis_tx_tready = 1 THE TRANSACTIONS HAS BEEN COMPLETED! WE CAN GO BACK TO RECEIVE!!
                    if s00_axis_tx_tready = '1' then
                        STATE  <= RECEIVE;
                    end if;
    end process FSM_engine; --FSM_engine not really needed

end Behavioral;
