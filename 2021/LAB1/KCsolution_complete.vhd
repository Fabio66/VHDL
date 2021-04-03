library IEEE;
	use IEEE.STD_LOGIC_1164.all;
	use IEEE.NUMERIC_STD.ALL;

entity KittCar is
	Generic (
		CLK_PERIOD_NS			:	POSITIVE	RANGE	1	TO	100     := 10;	-- clk period in nanoseconds
		MIN_KITT_CAR_STEP_MS	:	POSITIVE	RANGE	1	TO	2000    := 1;	-- Minimum step period in milliseconds (i.e., value in milliseconds of Delta_t)

		NUM_OF_SWS		:	INTEGER	RANGE	1 TO 16 := 16;	-- Number of input switches
		NUM_OF_LEDS		:	INTEGER	RANGE	1 TO 16 := 16	-- Number of output LEDs
	);
	Port (
		reset	:	IN	STD_LOGIC;
		clk		:	IN	STD_LOGIC;

		sw		:	IN	STD_LOGIC_VECTOR(NUM_OF_SWS-1 downto 0);	-- Switches avaiable on Basys3
		leds	:	OUT	STD_LOGIC_VECTOR(NUM_OF_LEDS-1 downto 0)	-- LEDs avaiable on Basys3
	);
end KittCar;

architecture Behavioral of KittCar is

	constant	KITT_CAR_RIGHT	:	STD_LOGIC_VECTOR(leds'RANGE) := '1' & (leds'high-1 downto 0 => '0');	-- 10...0
	constant	KITT_CAR_LEFT	:	STD_LOGIC_VECTOR(leds'RANGE) := (leds'high downto 1 => '0') & '1';		-- 0...01

	constant	KITT_CAR_INIT	:	STD_LOGIC_VECTOR(leds'RANGE) := KITT_CAR_RIGHT;

	---------- TIMER -----------
	constant	RANGE_COUNT_FINE	:	POSITIVE	:= ((MIN_KITT_CAR_STEP_MS * 1_000_000) / CLK_PERIOD_NS);	-- Implementation
	--constant	RANGE_COUNT_FINE	:	POSITIVE	:= ((MIN_KITT_CAR_STEP_MS*1)/CLK_PERIOD_NS);				-- Test Bench

	constant	RANGE_COUNT_COARSE	:	POSITIVE	:= 2**NUM_OF_SWS -1;

	---- Kitt Car Registers ----
	type direction_type is (MOVE_LEFT, MOVE_RIGHT);
	signal	direction		:	direction_type	:=	MOVE_LEFT;
	signal	kitt_car		:	STD_LOGIC_VECTOR(leds'RANGE)	:= KITT_CAR_INIT;
	signal	go_kitt_car		:	STD_LOGIC	:=	'0';

	----- Counter Registers ----
	signal	count_fine			:	INTEGER	RANGE	0	TO	RANGE_COUNT_FINE-1		:= 0;
	signal	count_coarse		:	INTEGER	RANGE	0	TO	RANGE_COUNT_COARSE-1	:= 0;
	signal	select_speed		:	INTEGER	RANGE	0	TO	RANGE_COUNT_COARSE-1	:= 1;
	signal	select_speed_reg	:	INTEGER	RANGE	0	TO	RANGE_COUNT_COARSE-1	:= 1;

begin

	leds    <= kitt_car;

	process(reset, clk)
	begin

		-- Reset
		if reset = '1' then
			kitt_car		<= KITT_CAR_INIT;
			count_fine		<= 0;
			count_coarse	<= 0;
			go_kitt_car		<= '0';
			direction		<= MOVE_LEFT;

			select_speed     <= 1;
			select_speed_reg <= 1;

		elsif rising_edge(clk) then

			-- Sample switches to guarantee stability on rising_edge(clk)
			select_speed	    <= to_integer(unsigned(sw));
			select_speed_reg    <= select_speed;

			-- Count the clock pulses (fine)
			count_fine	<= count_fine +1;

			-- go_kitt_car always low, unless overridden in the following if
			go_kitt_car	<= '0';

			-- Counter "fine" end (MIN_KITT_CAR_STEP_MS)
			if count_fine = RANGE_COUNT_FINE-1 then
				count_fine		<= 0;
				count_coarse	<= count_coarse	+1;

				-- Counter "coarse" end (MIN_KITT_CAR_STEP_MS*switches)
				if count_coarse = select_speed then
					count_coarse	<= 0;
					go_kitt_car		<= '1';
				end if;

			end if;

			-- Restart, reset settings
			if select_speed /= select_speed_reg then
				count_fine		<= 0;
				count_coarse	<= 0;
				go_kitt_car		<= '0';
			end if;

			-- Execute the Shift each go_kitt_car (MIN_KITT_CAR_STEP_MS*switches)
			if go_kitt_car = '1' then

				-- Shift to the left
				if direction = MOVE_LEFT then
					kitt_car	<= kitt_car(NUM_OF_LEDS-2 downto 0) & '0';

				-- Shift to the right
				elsif direction = MOVE_RIGHT then
					kitt_car	<= '0' & kitt_car(NUM_OF_LEDS-1 downto 1);

				end if;

				-- If reached the end, toggle the direction of the shift
				if kitt_car(kitt_car'high) = '1' then
					direction	<= MOVE_RIGHT;
					kitt_car	<= '0' & kitt_car(NUM_OF_LEDS-1 downto 1);

				elsif kitt_car(0) = '1' then
					direction	<= MOVE_LEFT;
					kitt_car	<= kitt_car(NUM_OF_LEDS-2 downto 0) & '0';

				end if;
			end if;
		end if;
	end process;
end Behavioral;