
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity AXI4Stream_Depacketizer is
Generic (
    HEADER				: std_logic_vector(7 downto 0) := x"c0";
    FOOTER				: std_logic_vector(7 downto 0) := x"51";

    BYTES_PER_RX_PACKET	: positive	:= 2
);
Port (

    ------ Reset/Clock ---------
    aclk			: in std_logic;
    aresetn			: in std_logic;
    ----------------------------

    -------- AXIS Inout --------
    s_axis_tvalid	: in std_logic;
    s_axis_tdata	: in std_logic_vector(7 downto 0);
    s_axis_tready	: out std_logic;
    ----------------------------

    -------- AXIS Output --------
    m_axis_tvalid	: out std_logic;
    m_axis_tdata	: out std_logic_vector(BYTES_PER_RX_PACKET*8-1 downto 0);
    m_axis_tready	: in std_logic
    ----------------------------
);
end AXI4Stream_Depacketizer;

architecture Behavioral of AXI4Stream_Depacketizer is

type state_type is (IDLE, WAIT_HEADER, RECEIVE_DATA, WAIT_FOOTER, SEND_DATA);
signal state			: state_type;

signal data_sr			: std_logic_vector(BYTES_PER_RX_PACKET*8 -1 downto 0);

signal rx_bytes_counter	: integer range 0 to BYTES_PER_RX_PACKET - 1;

begin

m_axis_tdata	<= data_sr;

with state select s_axis_tready <=
    '0' when IDLE,
    '1' when WAIT_HEADER,
    '1' when RECEIVE_DATA,
    '1' when WAIT_FOOTER,
    '0' when SEND_DATA;

with state select m_axis_tvalid <=
    '0' when IDLE,
    '0' when WAIT_HEADER,
    '0' when RECEIVE_DATA,
    '0' when WAIT_FOOTER,
    '1' when SEND_DATA;

process(aclk)
    variable new_word:	std_logic_vector(15 downto 0);
begin

    if aresetn = '0' then

        state		<= IDLE;

    elsif rising_edge(aclk) then

        case state is

            when IDLE =>
                state	<= WAIT_HEADER;


            when WAIT_HEADER =>
                if s_axis_tvalid = '1' then
                    if s_axis_tdata = HEADER then
                        rx_bytes_counter	<= 0;
                        state				<= RECEIVE_DATA;
                    else
                        -- We were expecting a header: ignore this byte
                        -- and stay in this state
                    end if;
                end if;


            when RECEIVE_DATA =>
                if s_axis_tvalid = '1' then

                    data_sr		<= data_sr(data_sr'high - s_axis_tdata'length downto 0) & s_axis_tdata;

                    if rx_bytes_counter = BYTES_PER_RX_PACKET - 1 then
                        state	<= WAIT_FOOTER;
                    end if;

                    rx_bytes_counter	<= rx_bytes_counter + 1;

                end if;


            when WAIT_FOOTER =>
                if s_axis_tvalid = '1' then
                    if s_axis_tdata = FOOTER then
                        state				<= SEND_DATA;
                    else
                        -- We were expecting a footer: restart without
                        -- sending the data
                        state				<= WAIT_HEADER;
                    end if;
                end if;


            when SEND_DATA =>
                if m_axis_tready = '1' then
                    state			<= WAIT_HEADER;
                end if;

        end case;

    end if;

end process;

end Behavioral;
