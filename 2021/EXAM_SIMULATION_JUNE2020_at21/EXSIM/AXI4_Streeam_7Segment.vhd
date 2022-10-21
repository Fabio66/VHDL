library IEEE;
	use IEEE.STD_LOGIC_1164.ALL;
	use IEEE.NUMERIC_STD.ALL;

entity AXI4Stream_7Segment is
	Generic (
		NUM_OF_DIGITS	:	POSITIVE	:= 4;
		ANODE_TICKS		:	POSITIVE	:= 20_000
	);
	Port (

		------ Reset/Clock ---------
		aresetn	:	IN	STD_LOGIC;
		clk		:	IN	STD_LOGIC;
		----------------------------

		-------- AXIS Inout --------
		s00_axis_tvalid	:   IN  STD_LOGIC;
		s00_axis_tdata	:   IN  STD_LOGIC_VECTOR((((NUM_OF_DIGITS*4-1)/8+1)*8)-1 DOWNTO 0);
		s00_axis_tready	:   OUT STD_LOGIC;
		----------------------------

		--- LEDs Display 7-seg. ---
		digit_select_anode	:	OUT	STD_LOGIC_VECTOR(NUM_OF_DIGITS-1 downto 0);
		seven_segment_led	:	OUT	STD_LOGIC_VECTOR(7-1 downto 0)
		---------------------------
	);
end AXI4Stream_7Segment;

architecture Behavioral of AXI4Stream_7Segment is

	------------------- TYPE DECLRATION --------------
    type SEVEN_SEGMENT_DIGIT_TYPE is array (NUM_OF_DIGITS-1 downto 0) of integer range 0 to 16;
    type SEVEN_SEGMENT_LUT_TYPE is array(0 to 16) of std_logic_vector(7-1 downto 0);
    ---------------------------------------------------

	-------------------- CONSTANTS --------------------
	constant NibbleTo7Segment	: SEVEN_SEGMENT_LUT_TYPE := (
		"0000001",	-- "0"
		"1001111",	-- "1"
		"0010010",	-- "2"
		"0000110",	-- "3"
		"1001100",	-- "4"
		"0100100",	-- "5"
		"0100000",	-- "6"
		"0001111",	-- "7"
		"0000000",	-- "8"
		"0000100",	-- "9"
		"0001000",	-- A
		"1100000",	-- b
		"0110001",	-- C
		"1000010",	-- d
		"0110000",	-- E
		"0111000",	-- F
		"1111111"	-- All OFF
	);
	constant BLANK		: integer := NibbleTo7Segment'high;
	---------------------------------------------------

	--------------------- SIGNALS ---------------------
	-- Nibble values
	signal nibbles					: SEVEN_SEGMENT_DIGIT_TYPE := (others => 16);

	-- Nibble counter
	signal next_nibble_index		: integer range 0 to NUM_OF_DIGITS - 1 := 1;

	-- Anode Shift-register
	signal mux_cnt 					: integer range 0 to ANODE_TICKS - 1 := 0;

	-- Internal signals copy
	signal s00_axis_tready_int		: std_logic := '0';
	signal digit_select_anode_int	: std_logic_vector(NUM_OF_DIGITS-1 downto 0) := (NUM_OF_DIGITS-1 downto 1 => '1') & "0";
	---------------------------------------------------

begin

	digit_select_anode	<= digit_select_anode_int;
	s00_axis_tready		<= s00_axis_tready_int;

	------------------ SYNC PROCESS -------------------
	process (clk)
	begin

	   if aresetn = '0' then
			-- All the Display Off
			nibbles					<= (others => BLANK);
			next_nibble_index		<= 1;

			mux_cnt					<= 0;
			s00_axis_tready_int		<= '0';
			digit_select_anode_int	<= (NUM_OF_DIGITS-1 downto 1 => '1') & "0";

			-- We must also set seven_segment_led, to clear the display
			seven_segment_led		<= NibbleTo7Segment(BLANK);

		elsif rising_edge(clk) then

			s00_axis_tready_int <=  '1';

			-------- Save Digits --------
			if s00_axis_tvalid = '1' and s00_axis_tready_int = '1' then

				for I in NUM_OF_DIGITS-1 downto 0 loop
					nibbles(I)	<= to_integer(unsigned(s00_axis_tdata((I+1)*4 -1 downto I*4)));
				end loop;

			end if;
			-----------------------------

			----- Digit multiplexing ----
			mux_cnt	<=	mux_cnt + 1;

			if mux_cnt = ANODE_TICKS - 1 then

				mux_cnt	<= 0;

				-- Select the next anode
				digit_select_anode_int	<=
					digit_select_anode_int(digit_select_anode_int'high-1 downto 0) &
					digit_select_anode_int(digit_select_anode_int'high);

				-- Select the next digit
				seven_segment_led		<= NibbleTo7Segment(nibbles(next_nibble_index));

				-- Increment the nibble counter (with roll-back)
				next_nibble_index	<= next_nibble_index + 1;
				if next_nibble_index = NUM_OF_DIGITS - 1 then
					next_nibble_index	<= 0;
				end if;

			end if;
			-----------------------------
		end if;

	end process;
	---------------------------------------------------

end Behavioral;
