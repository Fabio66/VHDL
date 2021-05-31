library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity volume_controller is
	Generic(
        --  VOLUME_MAX > VOLUME_INIT > VOLUME_MIN
        --  VOLUME_MAX - VOLUME_MIN < 16
        WORD_BIT        : positive := 16;

		VOLUME_0DB   	: positive := 7;		--Volume central value (no amplitude increase nor decrease)
		VOLUME_MAX		: positive := 15; 	    --Maximum volume value
		VOLUME_MIN 		: integer  := 0 	    --Minimum volume value
	);
	Port (
		aclk			: in 	std_logic;
		aresetn			: in 	std_logic;

		s_axis_tvalid	: in 	std_logic;
		s_axis_tdata	: in 	std_logic_vector(WORD_BIT-1 downto 0);
		s_axis_tlast	: in 	std_logic;
		s_axis_tready	: out 	std_logic;

		m_axis_tvalid	: out 	std_logic;
		m_axis_tdata	: out 	std_logic_vector(WORD_BIT-1 downto 0);
		m_axis_tlast	: out 	std_logic;
		m_axis_tready	: in 	std_logic;

		volume_level	: out	std_logic_vector(VOLUME_MAX downto VOLUME_MIN);
		volume_down 	: in 	std_logic;		        --Input port to decrease volume
		volume_up 		: in 	std_logic 		        --Input port to increase volume
	);
end volume_controller;

architecture Behavioral of volume_controller is

    type state_type is (IDLE, RECEIVE, COMPUTE, CLAMP, SEND);

	signal state 	: 	state_type;

	--signal tdata_int	    :	std_logic_vector(WORD_BIT-1 downto 0);
	signal tlast_int 	    : 	std_logic;

    constant data_max 	            :   signed(WORD_BIT-1 downto 0) :=  to_signed(2**(WORD_BIT-1)-1, WORD_BIT); -- clip max
    constant data_min 	            :   signed(WORD_BIT-1 downto 0) :=  to_signed(-2**(WORD_BIT-1), WORD_BIT);	-- clip min

	signal current_volume		    : 	natural range 0 to 15 := VOLUME_0DB;
	signal current_volume_int	    : 	natural range 0 to 15 := VOLUME_0DB;

begin

	volume_level <= std_logic_vector((shift_left(to_unsigned(1,16),current_volume + 1))-1);  	--Show the volume level on LEDs

	with state select s_axis_tready <=
		'0' when IDLE,
		'1' when RECEIVE,
		'0' when COMPUTE,
		'0' when CLAMP,
		'0' when SEND;

	with state select m_axis_tvalid <=
		'0' when IDLE,
		'0' when RECEIVE,
		'0' when COMPUTE,
		'0' when CLAMP,
		'1' when SEND;

	process (aclk,aresetn)
    -- We need to enlarge the data by the difference vmax - v0db, since the problem of loosing information arises
    -- only in the multiplication case. Dividing leads to no loss of info (if we start with a number and we divide it,
    -- it cannot require more bits than the previous one, even in negative case)
	variable amplified_data : signed(WORD_BIT-1 + VOLUME_MAX-VOLUME_0DB downto 0);

	begin
		if aresetn = '0' then		
			state		<= IDLE;

		elsif rising_edge(aclk) then		
			case state is

				when IDLE =>		
					state <= RECEIVE;

				when RECEIVE =>			
					if s_axis_tvalid = '1' then		    --Sample data and move to CLAMP state when the input data are valid
						state <= COMPUTE;

						--tdata_int <= s_axis_tdata;
						tlast_int <= s_axis_tlast;
						current_volume_int <= current_volume;		            --Sample the volume level
                        amplified_data := (VOLUME_MAX-VOLUME_0DB-1 downto 0 => s_axis_tdata(s_axis_tdata'high)) & (signed(s_axis_tdata));		--Convert to integer the input data
					end if;

				when COMPUTE =>		
					state <= CLAMP;
					m_axis_tlast <= tlast_int;		                    --Directly move tlast data to output

					if (current_volume_int < VOLUME_0DB) then		    --Decrease amplitude
						
                        --Decrease the volume by shifting right the integer value (shif_right allow for arithmetic shift)
						amplified_data := shift_right(amplified_data, VOLUME_0DB - current_volume_int);
					
                    elsif (current_volume_int > VOLUME_0DB) then		--Increase amplitude
						
                        --Increase the volume by shifting left the integer value (shif_left allow for arithmetic shift)
						amplified_data := shift_left(amplified_data, current_volume_int - VOLUME_0DB);
					
                    end if;

				when CLAMP =>	
					state <= SEND;

                    -- Since by dividing a negative number we cannot get 0 but at max -1, we set int his case the output to 0
                    -- even admitting a small (negligible) error in the case that it is really -1 to be transmitted
                    if (amplified_data = to_signed(-1,amplified_data'length)) then
                        m_axis_tdata <= (Others => '0');
                    end if;

					if (amplified_data > data_max) then
						m_axis_tdata    <=  std_logic_vector(data_max);		--Clamp data to maximum positive value in 16bit signed if higher than it			
                    elsif (amplified_data < data_min) then			
                        m_axis_tdata    <=  std_logic_vector(data_min); 	--Clamp data to minimum negative value in 16bit signed if lower than it				
                    else
                        --Move the computed value to output converting it in std_logic_vector
					    m_axis_tdata     <= std_logic_vector(amplified_data(WORD_BIT-1 downto 0)); 
                    end if;
                    
				when SEND =>		
					if m_axis_tready = '1' then		    --Move to RECEIVE state when the next AXIS module has received the data
						state <= RECEIVE;
					end if;
			end case;
		end if;
	end process;

	process (aclk,aresetn)
	begin
		if aresetn = '0' then
			current_volume <= VOLUME_0DB;

		elsif rising_edge(aclk) then
			if (volume_up = '1') and (current_volume < VOLUME_MAX) then
				current_volume <= current_volume + 1;
			elsif (volume_down = '1') and (current_volume > VOLUME_MIN) then
				current_volume <= current_volume - 1;
			end if;
		end if;
	end process;
end Behavioral;