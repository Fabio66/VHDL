
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity AXI4Stream_GPI is
Generic (
    DATA_WIDTH		:   positive	  := 16
);
Port (

    ------ Reset/Clock ---------
    aclk			: in std_logic;
    aresetn			: in std_logic;
    ----------------------------

    -------- AXIS Inout --------
    trigger			: in std_logic;
    gpi				: in std_logic_vector(DATA_WIDTH-1 DOWNTO 0);
    ----------------------------

    -------- AXIS Output --------
    m_axis_tvalid	: out std_logic;
    m_axis_tdata	: out std_logic_vector(((DATA_WIDTH-1)/8+1)*8-1 downto 0);
    m_axis_tready	: in std_logic
    ----------------------------
);
end AXI4Stream_GPI;

architecture Behavioral of AXI4Stream_GPI is

signal  trigger_old	:   std_logic;

begin

process(aclk)
begin

    if aresetn = '0' then

        trigger_old		<= '1';

    elsif rising_edge(aclk) then

        -- Keep sampling "trigger"
        trigger_old	<=  trigger;

        -- If tready is high, reset tvalid (unless overridden later)
        if m_axis_tready = '1' then
            m_axis_tvalid	<= '0';
        end if;

        -- If trigger was 0 and now is 1, set tvalid and send the data
        if trigger = '1' and trigger_old = '0' then
            m_axis_tvalid			 <= '1';

            m_axis_tdata(gpi'range)	 <= (Others => '0');
            m_axis_tdata(gpi'range)	 <= gpi;
        end if;

    end if;

end process;



end Behavioral;
