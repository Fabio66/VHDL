---------- DEFAULT LIBRARY ---------
library IEEE;
	use IEEE.STD_LOGIC_1164.all;
	use IEEE.NUMERIC_STD.ALL;

entity PulseWidthModulator is
	Generic(					
		BIT_LENGTH	:	INTEGER	RANGE	1 TO 16 := 8;	-- Bit used  inside PWM. This value limit the lowest reacheable PWM frequency.
														-- Assuming a target PWM frequency of 10KHz and a clk of 100MHz the Period value has to be 10_000.
														-- This can be reached with a 14 bit BIT_LENGHT. Using 16 bit BIT_LENGHT will provide more headroom.
		
		T_ON_INIT	:	INTEGER	      := 64;				-- Init of Ton
		PERIOD_INIT	:	POSITIVE	  := 128;				-- Init of Periof
		
		PWM_INIT	:	STD_LOGIC:= '0'					-- Init of PWM
	);
	Port ( 
		reset	:	IN	STD_LOGIC;
		clk		:	IN	STD_LOGIC;		

		Ton		:	IN	STD_LOGIC_VECTOR(BIT_LENGTH-1 downto 0);		-- clk at PWM = '1'
		--Period	:	IN	STD_LOGIC_VECTOR(BIT_LENGTH-1 downto 0);	-- clk per period of PWM, removed. No need to change Period in operation
		
		PWM		:	OUT	STD_LOGIC		-- PWM signal	
	);
end PulseWidthModulator;

architecture Behavioral of PulseWidthModulator is

	------------------ CONSTANT DECLARATION -------------------------
	
	constant	T_ON_INIT_UNS	:	UNSIGNED(BIT_LENGTH-1 downto 0)	:= to_unsigned(T_ON_INIT-1, BIT_LENGTH);	
	constant	PERIOD_INIT_UNS	:	UNSIGNED(BIT_LENGTH-1 downto 0) := to_unsigned(PERIOD_INIT -1, BIT_LENGTH);	

	---------------------------- SIGNALS ----------------------------

	------ Sync Process --------	
	signal	Ton_reg		:	UNSIGNED(BIT_LENGTH-1 downto 0)	:= T_ON_INIT_UNS;		--The Ton signal is created, max value (2^BIT_LENGHT)-1
	signal	Period_reg	:	UNSIGNED(BIT_LENGTH-1 downto 0)	:= PERIOD_INIT_UNS;		--The period signal is created, max value (2^BIT_LENGHT)-1.
	
	signal	count		:	UNSIGNED(BIT_LENGTH-1 downto 0)	:= (Others => '0');		--The clock counter signal is created, max value (2^BIT_LENGHT)-1
	
	signal	pwm_reg		:	STD_LOGIC	:= PWM_INIT;

begin

	PWM		<= pwm_reg;

	process(reset, clk)	
	begin

		if reset = '1' then							-- Reset 
			Ton_reg		<= T_ON_INIT_UNS;
			Period_reg	<= PERIOD_INIT_UNS;		
			
			count		<= (Others => '0');
			
			pwm_reg		<= PWM_INIT;
	
		elsif rising_edge(clk) then
			count	<= count + 1;					-- Count the clock pulses
			
			if count = unsigned(Period_reg) then	-- Define the period (Period +1 clk pulses				
				count		<= (Others => '0');		-- Reset count
								
				pwm_reg	<= PWM_INIT;				-- Toggle the output (set on)
				
				--Period_reg	<=	unsigned(Period);	-- Sample Period and Ton to guarantee glitch-less behavior inside a period and on rising_edge(clk).
														-- Period sampling removed. No need to change period in operation
				Ton_reg		<=	unsigned(Ton);
				
			end if;
			
			if count = Ton_reg-1 then				-- Define the duty cycle (Ton clk pulses), (* required if Ton = 2**BIT_LENGTH -1)				
				pwm_reg	<= not PWM_INIT;			-- Toggle the output
				
			end if;
							
			if Ton_reg = 0 then						-- If duty cycle = 0
				pwm_reg	<= not PWM_INIT;
			end if;
					
			if Ton_reg > Period_reg then			-- if duty cycle = 1
				pwm_reg	<= PWM_INIT;
			end if;				
		end if;
	end process;
	
end Behavioral;