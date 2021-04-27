library IEEE;
	use IEEE.STD_LOGIC_1164.all;
	use IEEE.NUMERIC_STD.ALL;

entity divisor is 
    Generic(
        PACKET_BITS : positive := 8    --number of bits inside a single serial packet
    );
    Port(
        clk         : in    std_logic;
        resetn      : in    std_logic;

        --AXI4-S Interfaces
        --Slave Interface
        s_axis_tvalid   : in    std_logic;
        s_axis_tready   : out   std_logic;
        s_axis_tdata    : in    std_logic_vector(PACKET_BITS-1 downto 0);

        --Master Interface
        m_axis_tvalid   : out   std_logic;
        m_axis_tready   : in    std_logic;
        m_axis_tdata    : out   std_logic_vector(PACKET_BITS-1 downto 0)
    );
end divisor;

architecture Behavioral of divisor is

    type FSM_Div is (IDLE, GATHERING, DIVISION, TRANSMIT);

    signal STATE    : FSM_Div   := IDLE;

    signal counter  : integer range 0 to 2;

    signal p_sum_1         : unsigned(2*PACKET_BITS downto 0)  := (Others => '0');
    signal p_sum_2         : unsigned(2*PACKET_BITS downto 0)  := (Others => '0');
    signal sum             : unsigned(2*PACKET_BITS downto 0)  := (Others => '0');
    
begin

    with STATE select s_axis_tready <=
        '0' when IDLE,
        '1' when GATHERING,
        '0' when DIVISION,
        '0' when TRANSMIT;
    
    with STATE select m_axis_tvalid <=
        '0' when IDLE,
        '0' when GATHERING,
        '0' when DIVISION,
        '1' when TRANSMIT; 

    process (clk, resetn)
        variable temp_sum : unsigned(2*PACKET_BITS downto 0) := (Others =>'0');

    begin
        if resetn = '0' then
            STATE   <= IDLE;
            sum         <= (Others => '0');
            counter     <= 0;
        elsif rising_edge(clk) then
            
            case STATE is 

                when IDLE =>
                    STATE <= GATHERING;

                when GATHERING =>

                    if s_axis_tvalid = '1' then
                        counter <= counter + 1;
                        sum     <= sum+unsigned(s_axis_tdata);
                        
                        if counter = 2 then
                            STATE <= DIVISION;
                            counter <= 0;
                        end if;
                    end if;
                
                when DIVISION =>
                    if counter = 0 then

                        counter <= counter + 1;

                        p_sum_1 <= sum+(sum sll 1)+(sum sll 3);
                        p_sum_2 <= (sum sll 5)+(sum sll 7);
                        
                    elsif counter = 1 then
                        
                        --temp_sum := (p_sum_1+p_sum_2) srl 9;
                        --m_axis_tdata <= std_logic_vector(temp_sum(PACKET_BITS-1 downto 0));
                        temp_sum := (p_sum_1 + p_sum_2);
                        m_axis_tdata <= std_logic_vector(temp_sum(2*PACKET_BITS downto PACKET_BITS+1));

                        --Cleaning for next Cycle of FSM
                        counter     <= 0;
                        temp_sum    := (Others => '0'); --not really needed
                        p_sum_1     <= (Others => '0');
                        p_sum_2     <= (Others => '0');
                        sum         <= (Others => '0');

                        STATE <= TRANSMIT;

                    end if;

                when TRANSMIT =>                    
                    if m_axis_tready = '1' then
                        STATE <= GATHERING;
                    end if;

            end case;
        end if;
    end process;
end Behavioral;