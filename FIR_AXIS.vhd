library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is 
    Generic(
        FIR_MEAN        : positive         := 5;
        WORD_BYTES      : positive         := 2;
        FIR_INIT_VAL    : integer          := 0;
    );
    Port(
        aclk            : in std_logic;
        aclk2           : in std_logic;  --half of the speed for the FIR
        resetn          : in std_logic;

        --AXI4-S Interface pins
        --SLAVE_interface
        s_axis_tvalid   : in  std_logic;
        s_axis_tready   : out std_logic;
        s_axis_tdata    : in  unsigned(8*WORD_BYTES-1 downto 0);
        s_axis_tlast    : in  std_logic;
        
        --MASTER_interface
        m_axis_tvalid   : out std_logic;
        m_axis_tready   : in  std_logic;
        m_axis_tdata    : out unsigned(8*WORD_BYTES-1 downto 0);
        m_axis_tlast    : out std_logic;
    );
end top;

architecture Behavioral of top is 
   
    component FIR is 
        Generic (
            TO_EXTEND   : positive      := 5; 
            WORD_BYTES  : positive      := 2;
            INIT        : integer       := 0
        );
        Port (
            clk         : in    std_logic;
            reset       : in    std_logic;

            Data_in     : in    signed(8*WORD_BYTES-1 downto 0);
            Data_out    : out   signed(8*WORD_BYTES-1 downto 0)
        );
    end component;

    type FSM_STATE is (IDLE, READING, WAIT_FIR, SENDING) ;
    signal STATUS : FSM_STATE := IDLE;

    signal Data_in_SX : unsigned(8*WORD_BYTES-1 downto 0);
    signal Data_in_DX : unsigned(8*WORD_BYTES-1 downto 0);
    
    signal count : positive := 0; --range 0 to 4 := 0;

begin

    --INSTANTIATE THE FIRST FIR FILTER  (for the first audio channel)
    FIR_SX_CHANNEL : FIR 
    Generic map(
        TO_EXTEND       => FIR_MEAN,
        WORD_BYTES      => WORD_BYTES,
        INIT            => FIR_INIT_VAL
    )
    Port map(
        clk             => aclk,
        reset           => not resetn,

        Data_in         => Data_in_SX,
        Data_out        => m_axis_tdata
    );

    --INSTANTIATE THE SECOND FIR FILTER  (for the second audio channel)
    FIR_DX_CHANNEL : FIR 
    Generic map(
        TO_EXTEND       => FIR_MEAN,
        WORD_BYTES      => WORD_BYTES,
        INIT            => FIR_INIT_VAL
    )
    Port map(
        clk             => aclk,
        reset           => not resetn,

        Data_in         => Data_in_DX,
        Data_out        => m_axis_tdata
    );


    with STATUS select s_axis_tready =>
        '0' when IDLE,
        '1' when READING,
        '0' when WAIT_FIR,
        '0' when SENDING;

    with STATUS select m_axis_tvalid =>
        '0' when IDLE,
        '0' when READING,
        '0' when WAIT_FIR,
        '1' when SENDING;

    FSM_ENGINE : process(aclk)

    begin
        if resetn = '0' then
            STATUS  <= IDLE;
            count   <= 0;
        elsif rising_edge(clk) then 
            
            case STATUS is

                when IDLE =>
                    STATUS <= READING;

                when READING =>
                    if s_axis_tvalid = '1' then
                        --Looking at tlast we choose if the s_axis_tdata should go to the FIR_DX or FIR_SX
                        if s_axis_tlast = '0'
                            Data_in_SX  <= s_axis_tdata;
                        else
                            Data_in_DX  <= s_axis_tdata;
                        end if;
                            --rimarrà m_axis_tlast = s_axis_tlast fino all'handshake, ok!
                            m_axis_tlast <= s_axis_tlast;
                            STATUS <= WAIT_FIR;
                    end if;
                    else 
                        --nothing, just wait here.
                        --STATUS <= READ
                    end if;
                
                when WAIT_FIR =>
                    --WAIT FOR TWO ACLK TICKS, SO FOR ONE ACLK2 TICK
                    if count = 0 then
                        STATUS <= WAIT_FIR;
                        count <= 77;
                    else
                        STATUS <= SENDING;
                        count <= 0;
                    end if;

                when SENDING =>
                    if m_axis_tready = '1' then 
                        STATUS <= READING;
                    end if;

        end if;
    end process;
end Behavioral;