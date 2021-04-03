library IEEE;
	use IEEE.STD_LOGIC_1164.all;
	use IEEE.NUMERIC_STD.ALL;

-- Just BASIC version withouth PWM, GENERICS : Switches and LEDs number.

entity KITT is 
    Generic(
        SW_N        : integer range 0 to 16     := 16;
        LED_N       : integer range 2 to 16     := 16
    );
    Port(
        clk         :   in std_logic;
        reset       :   in std_logic;

        switches    :   in std_logic_vector(SW_N-1 downto 0);
        LEDs        :   out std_logic_vector(0 to LED_N-1)
    );
end KITT;


architecture Behavioral of KITT is

    constant init_ledr   : std_logic_vector(0 to LED_N-1)       := (0 => '1', Others => '0');
    constant init_ledl   : std_logic_vector(LED_N-1 downto 0)   := (0 => '1', Others => '0');


    -- No need to create a new type since we need a "monodim" shift reg, only one input! (WORD WIDTH = 1)
    signal shift_r       : std_logic_vector(0 to LED_N -1)      := (0 => '1', Others => '0');
    signal shift_l       : std_logic_vector(LED_N-1 downto 0)   := (0 => '1', Others => '0');

    signal sw_smpl       : unsigned(SW_N-1 downto 0)            := (Others => '0');
    
    signal count_dir     : unsigned(5 downto 0)                 := (Others => '0');  -- basterebbero 5 bit ??
    signal count_dt      : unsigned(SW_N-1 downto 0)            := (Others => '0');  
    signal dt            : unsigned(SW_N downto 0)              := (Others => '0');
    

begin

    --dt <= (sw_smpl+1)*to_unsigned(SW_N,count_dt'LENGTH);
    dt <= '0'&sw_smpl+1;

    kitt : process(clk, reset)
    begin
        if reset = '1' then
            count_dir   <=  (Others => '0');
            count_dt    <=  (Others => '0');
            LEDs        <=  init_ledr;
            shift_l     <=  init_ledl;
            shift_r     <=  init_ledr;
            sw_smpl     <=  unsigned(switches);

        elsif rising_edge(clk) then
            
            -- we sample the swithces in order to do not get strange behaviors during one clk cycle (glitches)
            sw_smpl <= unsigned(switches);

            -- i opted for a counter to select which shiftregister should be linked with the LEDs of the board
            count_dt <= count_dt + 1;
            -- if count < 15dt (starting from 0) we have to shift rightwards, otherwise leftwards, until count < 31 dt, then count = 0
            -- we need two counters, one to select the shiftergister and one to count unitl a dt : one makes the register shift, whilst one "selects the direction"

            if count_dir < LED_N then   -- LED_N-1 if <= 
                if count_dt = (dt-1) then
                    
                    shift_r     <= '0'&shift_r(0 to LED_N-2);
                    count_dir   <= count_dir + 1;
                    count_dt    <= (Others => '0');

                end if;
            else 
                if count_dt = (dt-1) then
                
                    shift_l     <= shift_l(LED_N-2 downto 0)&'0';
                    count_dir   <= count_dir + 1;
                    count_dt    <= (Others => '0');

                end if;
            end if;
            
        ----------------------------------------------------------------------

            if count_dir = to_unsigned(LED_N-1,5) then

                LEDs        <=  shift_l;
                shift_r     <=  init_ledr;
            
            elsif count_dir = to_unsigned(2*LED_N-1,5) then

                LEDs        <=  shift_r;
                shift_l     <=  init_ledl;
                count_dir   <=  (Others => '0');

            end if;
        end if;
    end process;
end Behavioral;