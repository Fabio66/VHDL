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
        s_axis_tdata    : in  std_logic_vector(8*WORD_BYTES-1 downto 0);
        s_axis_tlast    : in  std_logic;
        
        --MASTER_interface
        m_axis_tvalid   : out std_logic;
        m_axis_tready   : in  std_logic;
        m_axis_tdata    : out std_logic_vector(8*WORD_BYTES-1 downto 0);
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

            CE          : in    std_logic;

            Data_in     : in    std_logic_vector(8*WORD_BYTES-1 downto 0);
            Data_out    : out   std_logic_vector(8*WORD_BYTES-1 downto 0)
        );
    end component;

    type FSM_STATE is (IDLE, READING, WAIT_FIR, SENDING) ;
    signal STATUS : FSM_STATE := IDLE;

    signal Data_in_SX : std_logic_vector(8*WORD_BYTES-1 downto 0);
    signal Data_in_DX : std_logic_vector(8*WORD_BYTES-1 downto 0);
    
    --signal count        : positive := 0; --range 0 to 4 := 0;
    
    signal chip_en_SX   : std_logic := 0;
    signal chip_en_DX   : std_logic := 0;

    signal SX_FIR_Dout  : std_logic_vector(8*WORD_BYTES-1 downto 0);
    signal DX_FIR_Dout  : std_logic_vector(8*WORD_BYTES-1 downto 0);

    signal path_cntrl   : std_logic_vector;

begin

    path_cntrl <= chip_en_SX or chip_en_DX;

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

        CE              => chip_en_SX,

        Data_in         => Data_in_SX,
        Data_out        => SX_FIR_Dout
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

        CE              => chip_en_DX,

        Data_in         => Data_in_DX,
        Data_out        => DX_FIR_Dout
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

                        --rimarrà m_axis_tlast = s_axis_tlast fino all'handshake, ok!
                        m_axis_tlast <= s_axis_tlast;

                        --Looking at tlast we choose if the s_axis_tdata should go to the FIR_DX or FIR_SX
                        
                        --Done with case select to avoid priority

                        case s_axis_tlast is
                            
                            when '0' =>
                                Data_in_SX  <= s_axis_tdata;   --in this way, the next cycle the FIR filter will consider the new input as something
                                chip_en_SX  <= '1';            --to weight and, the cycle after will not.
                            
                            when '1' =>
                                Data_in_DX  <= s_axis_tdata;   --Same as before for the SX filter.
                                chip_en_DX  <= '1';
                            
                            when others =>
                                --null ?

                        end case;


                        --Done with if else construct (with priority)
                        
                        -- if s_axis_tlast = '0'
                        --     Data_in_SX  <= s_axis_tdata;   --in this way, the next cycle the FIR filter will consider the new input as something
                        --     chip_en_SX  <= '1';            --to weight and, the cycle after will not.
                        -- elsif s_axis_tlast = '1'
                        --     Data_in_DX  <= s_axis_tdata;   --Same as before for the SX filter.
                        --     chip_en_DX  <= '1';
                        -- else
                        --     --null;
                        -- end if;

                        STATUS <= WAIT_FIR;

                    end if;
                    else 
                        --nothing, just wait here.
                        --STATUS <= READ
                    end if;
                
                --THE FIRS NEED ONE ACLK CYCLE TO PROVIDE THE CORRECT OUTPUT    
                when WAIT_FIR =>       
                    --Without using 2 differents clocks, and withouth distinguishing between the two cases to use less hardware 
                    --and reducing the propagation delay
                    
                    chip_en_SX <= '0';
                    chip_en_DX <= '0';

                    --The first time we are here, path_cntrl will be for sure high, 
                    --but as we can see here above, the seocond time will be for sure low
                    
                    if path_cntrl = '1' then
                        STATUS <= WAIT_FIR;
                    
                    elsif path_cntrl = '0' then
                        
                        --We use the sampled s_axis_tlast, that is our m_axis_tlast, to use the right signal, cause after we exit the CHOOSING state 
                        --the master of the previous device can change it's outputs and prepare at this device slave interface the next word 
                        --that will always (except errors) have a different s_axis_tlast.
                        case m_axis_tlast is
                            
                            when 0 =>
                                m_axis_tdata <= SX_FIR_Dout;
                                STATUS <= SENDING;
                            
                            when 1 =>
                                m_axis_tdata <= DX_FIR_Dout;
                                STATUS <= SENDING;          
                            
                            when others =>
                                --null ?
                                reset <= '1';
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