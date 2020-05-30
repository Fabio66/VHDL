library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity AXI4_interface_FSM is 
    Generic(
        IIR_MEAN        : positive         := 5;  --2**IIR_MEAN = number of elements to weight
        WORD_BYTES      : positive         := 2;  --Length in bytes of the words in input
        IIR_INIT_VAL    : integer          := 0   --Initial Value of the filter, just if for some reason we do not want to begin with 0.
    );
    Port(
        aclk            : in std_logic;
        resetn          : in std_logic;

        --AXI4-S Interface pins
        --SLAVE_interface
        s_axis_tvalid   : in  std_logic;
        s_axis_tready   : out std_logic;
        s_axis_tdata    : in  std_logic_vector(8*WORD_BYTES-1 downto 0);
        s_axis_tlast    : in  std_logic;
        
        --MASTER_interface
        m_axis_tvalid   : out std_logic;
        m_axis_tready   : in  std_logic;
        m_axis_tdata    : out std_logic_vector(8*WORD_BYTES-1 downto 0);
        m_axis_tlast    : out std_logic
    );
end AXI4_interface_FSM;

architecture Behavioral of AXI4_interface_FSM is 
   
    component IIR is 
        Generic (
            TO_EXTEND   : positive      := 5; 
            WORD_BYTES  : positive      := 2;
            INIT        : integer       := 0
        );
        Port (
            clk         : in    std_logic;
            reset       : in    std_logic;

            CE          : in    std_logic;

            Data_in     : in    std_logic_vector(8*WORD_BYTES-1 downto 0);
            Data_out    : out   std_logic_vector(8*WORD_BYTES-1 downto 0)
        );
    end component;

    --Defining the fsm states needed in order to have a good behavior for this module.
    type FSM_STATE is (IDLE, READING, WAIT_IIR, SENDING) ;
    signal STATUS : FSM_STATE := IDLE;

    signal Data_in_SX : std_logic_vector(8*WORD_BYTES-1 downto 0);
    signal Data_in_DX : std_logic_vector(8*WORD_BYTES-1 downto 0);
 
    signal chip_en_SX   : std_logic := '0';
    signal chip_en_DX   : std_logic := '0';

    signal SX_IIR_Dout  : std_logic_vector(8*WORD_BYTES-1 downto 0);
    signal DX_IIR_Dout  : std_logic_vector(8*WORD_BYTES-1 downto 0);

    --  "Flow control signals"
    signal path_cntrl               : std_logic;
    signal m_axis_tlast_sampled     : std_logic;

    signal reset        : std_logic; 

begin

    reset <= not resetn; -- we cannot compute the not resetn during the port map, so we do it here.

    --We want path_cntrl not to be in dataflow!
    --path_cntrl <= chip_en_SX or chip_en_DX;

    --INSTANTIATE THE FIRST IIR FILTER  (for the first audio channel)
    IIR_SX_CHANNEL : IIR 
    Generic map(
        TO_EXTEND       => IIR_MEAN,
        WORD_BYTES      => WORD_BYTES,
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
        WORD_BYTES      => WORD_BYTES,
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
            --count   <= 0;
        elsif rising_edge(aclk) then 
            
            case STATUS is

                when IDLE =>
                    STATUS <= READING;

                when READING =>
                    if s_axis_tvalid = '1' then

                        m_axis_tlast_sampled <= s_axis_tlast;

                        --Looking at tlast we choose if the s_axis_tdata should go to the IIR_DX or IIR_SX                       
                        --Done with case-select to avoid priority

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


                        --Done with if else construct (with priority)
                        
                        -- if s_axis_tlast = '0'
                        --     Data_in_SX  <= s_axis_tdata;   --in this way, the next cycle the IIR filter will consider the new input as something
                        --     chip_en_SX  <= '1';            --to weight and, the cycle after will not.
                        -- elsif s_axis_tlast = '1'
                        --     Data_in_DX  <= s_axis_tdata;   --Same as before for the SX filter.
                        --     chip_en_DX  <= '1';
                        -- else
                        --     --null;
                        -- end if;

                        STATUS <= WAIT_IIR;

                    --end if;
                    else 
                        --nothing, just wait here.
                        --STATUS <= READ
                    end if;
                
                --THE IIRS NEED TWO ACLK CYCLEs TO PROVIDE THE CORRECT OUTPUT    
                when WAIT_IIR =>       
                    --Without using 2 differents clocks, and withouth distinguishing between the two cases to use less hardware 
                    --and in order to reduce the propagation delay of our logic between the flip flops, to have a greater slack in this particular path
                    --we implemented a "Chip Enable" that tells the iir when to read and compute something.
                    
                    chip_en_SX <= '0';
                    chip_en_DX <= '0';

                    --COMMENTARE
                    path_cntrl <= (chip_en_DX or chip_en_DX);

                    m_axis_tlast <= m_axis_tlast_sampled;  --could we put this under to avoid sampling it every time we are in this state?

                    --The IIRst time we are here, path_cntrl will for sure be high, 
                    --but as we can see here above, the seocond time will be for sure low
                    
                    if ((chip_en_DX or chip_en_SX) or path_cntrl )= '1' then
                        STATUS <= WAIT_IIR;
                    
                    elsif (chip_en_DX or chip_en_SX) = '0' then  --to eliminate the check we could just use else and eliminate the else under this elsif, less hardware too and 
                        
                        --We use the sampled s_axis_tlast, that is our m_axis_tlast_sampled, to use the right signal, cause after we exit the CHOOSING state 
                        --the master of the previous device can change it's outputs and prepare at this device slave interface the next word 
                        --that will always (except errors) have a different s_axis_tlast. WE NEED THE m_axis_tlast_sampled SINCE m_axis_tlast IS AN OUTPUT PORT, AND WE CANNOT READ AN OUTPUT PORT.
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
                    else 
                        --nothing, Since path_cntrl is a std_logic, it could happen that his value could be different from 0 or 1
                    end if;
                
                when SENDING =>
                    if m_axis_tready = '1' then 
                        STATUS <= READING;
                    end if;

            end case;
        end if;
    end process;
end Behavioral;