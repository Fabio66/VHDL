library IEEE;
use IEEE.STD_LOGIC_1164.ALL;





entity mute_controller is
	Port (
		aclk			: in 	std_logic;
		aresetn			: in 	std_logic;

		s_axis_tvalid	: in 	std_logic;
		s_axis_tdata	: in 	std_logic_vector(15 downto 0);
		s_axis_tlast	: in 	std_logic;
		s_axis_tready	: out 	std_logic;

		m_axis_tvalid	: out 	std_logic;
		m_axis_tdata	: out 	std_logic_vector(15 downto 0);
		m_axis_tlast	: out 	std_logic;
		m_axis_tready	: in 	std_logic;

		mute_left 		: in 	std_logic;
		mute_right 		: in 	std_logic
	);
end mute_controller;





architecture Behavioral of mute_controller is

----------------------------TYPE DECLARATION---------------------------------
type state_type is (IDLE, RECEIVE, MUTE, SEND);		--FSM Type
-----------------------------------------------------------------------------


---------------------------SIGNAL DECLARATION--------------------------------
signal state 	: 	state_type;

signal tdata_int	:	std_logic_vector(15 downto 0);
signal tlast_int 	: 	std_logic;

signal mute_left_int 	: 	std_logic;
signal mute_right_int 	: 	std_logic;
-----------------------------------------------------------------------------

begin

--------------------------------DATA FLOW------------------------------------

-----------------------------------------------------------------------------


-------------------------------FSM OUTPUTS-----------------------------------
	with state select s_axis_tready <=
		'0' when IDLE,
		'1' when RECEIVE,
		'0' when MUTE,
		'0' when SEND;

	with state select m_axis_tvalid <=
		'0' when IDLE,
		'0' when RECEIVE,
		'0' when MUTE,
		'1' when SEND;
-----------------------------------------------------------------------------


-----------------------------------FSM---------------------------------------
	process (aclk,aresetn)
	begin

		if aresetn = '0' then		--Reset condition
			state		<= IDLE;


		elsif rising_edge(aclk) then	--Normal operation

			case state is

				when IDLE =>		--State IDLE

					state <= RECEIVE; 	



				when RECEIVE =>		--State RECEIVE
					
					if s_axis_tvalid = '1' then		--Sample data and move to MUTE state when the input data are valid
						state <= MUTE;

						tdata_int <= s_axis_tdata; 		
						tlast_int <= s_axis_tlast;
						mute_right_int <= mute_right;		--Sample mute inputs
						mute_left_int <= mute_left;

					end if;



				when MUTE =>		--State MUTE

					state <= SEND;

					m_axis_tlast <= tlast_int;		--Directly move tlast data to output

					if (tlast_int = '1') and (mute_right_int = '1') then		--Selectively mute right channel, left channel or both
						m_axis_tdata <= x"0000";
					elsif (tlast_int = '0') and (mute_left_int = '1') then
						m_axis_tdata <= x"0000";
					else
						m_axis_tdata <= tdata_int;		--Move the computed value to output
					end if;



				when SEND =>		--State SEND

					if m_axis_tready = '1' then		--Move to RECEIVE state when the next AXIS module ha received the data
						state <= RECEIVE;

					end if;



			end case;



		end if;

	end process;
-----------------------------------------------------------------------------



end Behavioral;