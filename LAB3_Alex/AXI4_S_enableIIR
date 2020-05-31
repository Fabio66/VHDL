library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity AXI4_S_interface_FSM is 
    Generic(
        IIR_MEAN        : positive         := 5;  --2**IIR_MEAN = number of elements to weight
        WORD_BIT        : positive         := 16;  --Length in bit of the words in input
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
end AXI4_S_interface_FSM;

architecture Behavioral of AXI4_S_interface_FSM is 
   
    component IIR is 
        Generic (
            TO_EXTEND   : positive      := 5; 
            WORD_BIT    : positive      := 2;
            INIT        : integer       := 0
        );
        Port (
            clk         : in    std_logic;
            reset       : in    std_logic;

            CE          : in    std_logic;

            Data_in     : in    std_logic_vector(WORD_BIT-1 downto 0);
            Data_out    : out   std_logic_vector(WORD_BIT-1 downto 0)
        );
    end component;

    --Defining the fsm states needed in order to have a good behavior for this module.
    type FSM_STATE is (IDLE, READING, WAIT_IIR, SENDING) ;
    signal STATUS : FSM_STATE := IDLE;

    signal Data_in_SX : std_logic_vector(WORD_BIT-1 downto 0);
    signal Data_in_DX : std_logic_vector(WORD_BIT-1 downto 0);
      
    signal chip_en_SX   : std_logic := '0';
    signal chip_en_DX   : std_logic := '0';

    signal SX_IIR_Dout  : std_logic_vector(WORD_BIT-1 downto 0);
    signal DX_IIR_Dout  : std_logic_vector(WORD_BIT-1 downto 0);

    --  "Flow control signals"
    signal count                    : unsigned(1 downto 0)   := "00"; 
    signal m_axis_tlast_sampled     : std_logic;

    signal reset        : std_logic; 

begin

    reset <= not resetn; 

    --INSTANTIATE THE FIRST IIR FILTER  (for the first audio channel)
    IIR_SX_CHANNEL : IIR 
    Generic map(
        TO_EXTEND       => IIR_MEAN,
        WORD_BIT        => WORD_BIT,
        INIT            => IIR_INIT_VAL
    )
    Port map(
        clk             => aclk,
        reset           => reset,

        CE              => chip_en_SX,

        Data_in         => Data_in_SX,
        Data_out        => SX_IIR_Dout
    );

    --INSTANTIATE THE SECOND IIR FILTER  (for the second audio channel)
    IIR_DX_CHANNEL : IIR 
    Generic map(
        TO_EXTEND       => IIR_MEAN,
        WORD_BIT        => WORD_BIT,
        INIT            => IIR_INIT_VAL
    )
    Port map(
        clk             => aclk,
        reset           => reset,

        CE              => chip_en_DX,

        Data_in         => Data_in_DX,
        Data_out        => DX_IIR_Dout
    );


    with STATUS select s_axis_tready <=
        '0' when IDLE,
        '1' when READING,
        '0' when WAIT_IIR,
        '0' when SENDING;

    with STATUS select m_axis_tvalid <=
        '0' when IDLE,
        '0' when READING,
        '0' when WAIT_IIR,
        '1' when SENDING;

    FSM_ENGINE : process(aclk)

    begin
        if resetn = '0' then
            STATUS  <= IDLE;
            count   <= "00";

        elsif rising_edge(aclk) then 
            
            case STATUS is

                when IDLE =>
                    STATUS <= READING;

                when READING =>
                    if s_axis_tvalid = '1' then

                        if enable_filter = '1' then
                            m_axis_tlast_sampled <= s_axis_tlast;
                            STATUS          <= WAIT_IIR;
                        else 
                            m_axis_tlast    <= s_axis_tlast;
                            m_axis_tdata    <= s_axis_tdata;
                            STATUS          <= SENDING;                        
                        end if;
                        
                        case s_axis_tlast is                                
                            when '0' =>
                                Data_in_SX  <= s_axis_tdata;   --in this way, the next cycle the IIR filter will consider the new input as something
                                chip_en_SX  <= '1';            --to weight and, the cycle after will not.
                            
                            when '1' =>
                                Data_in_DX  <= s_axis_tdata;   --Same as before for the SX filter.
                                chip_en_DX  <= '1';
                            
                            when others =>
                                --null ?

                        end case;


                    else 
                        --STATUS <= READ
                    end if;
                
                --THE IIRS NEED TWO ACLK CYCLEs TO PROVIDE THE CORRECT OUTPUT    
                when WAIT_IIR =>       
                    
                    chip_en_SX <= '0';
                    chip_en_DX <= '0';

                    m_axis_tlast <= m_axis_tlast_sampled;  
                    
                    if count <= "01" then
                        STATUS <= WAIT_IIR;
                        count <= count + 1;
                    else 
                        
                        count <= "00";

                        case m_axis_tlast_sampled is
                            
                            when '0' =>
                                m_axis_tdata <= SX_IIR_Dout;
                                STATUS <= SENDING;
                            
                            when '1' =>
                                m_axis_tdata <= DX_IIR_Dout;
                                STATUS <= SENDING;          
                            
                            when others =>
                                --null ?
                        end case;
                    end if;
                
                when SENDING =>

                    chip_en_SX <= '0';
                    chip_en_DX <= '0';
     
                    if m_axis_tready = '1' then 
                        STATUS <= READING;
                    end if;

            end case;
        end if;
    end process;
end Behavioral;