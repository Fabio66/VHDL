library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TopEntity is
    Generic(

        NUM_OF_SWS					:	INTEGER		RANGE	1   TO  16      := 16;		-- Number of input switches
        NUM_OF_LEDS					:	INTEGER		RANGE	1 	TO 	16 		:= 16;		-- Number of output LEDs
        TAIL_LENGTH					:	INTEGER		RANGE	1 	TO 	16		:= 8;		-- Tail LEDs

        CLK_PERIOD_NS			    :	POSITIVE	RANGE	1	TO	100     := 10;	    -- clk period in nanoseconds
        MIN_KITT_CAR_STEP_MS		:	POSITIVE	RANGE	1	TO	20000   := 1000;	-- Minimum step period in milliseconds (i.e., value in milliseconds of Delta_t)
        DEFAULT_KITT_CAR_STEP_MS	: 	POSITIVE	RANGE	1	TO	2000    := 100;

        PWM_FREQUENCY_KHZ		    :	POSITIVE 	RANGE	1   TO  100		:= 10;		-- PWM frequency in KHz
        T_ON_INIT	                :	INTEGER	        := 64;  				        -- Init of Ton
        PERIOD_INIT	                :	POSITIVE	    := 128;				            -- Init of Period
        PWM_INIT	                :	STD_LOGIC       := '1';					        -- Init of PWM
        SR_DEPTH                    :   INTEGER         := 16                           -- DEFINITION OF THE SR
        
    );
    Port ( 
        clk				: in    std_logic;
        reset			: in    std_logic;

        sw    			: in     std_logic_vector(NUM_OF_SWS-1 downto 0);
        leds			: out 	 std_logic_vector(NUM_OF_LEDS-1 downto 0)
    );
end TopEntity;

architecture Behavioral of TopEntity is

    constant PWM_PERIOD				:	INTEGER	    :=	1_000_000/(CLK_PERIOD_NS * PWM_FREQUENCY_KHZ);
    constant TON_STEP_VALUE			:	INTEGER	    :=	PWM_PERIOD/TAIL_LENGTH;
    
    constant NullPeriod				:   std_logic_vector(NUM_OF_SWS-1 downto 0)   := (others => '0');

    component Switch is
        Generic(
            NUM_OF_SWS					:	INTEGER		RANGE	1	TO  16 			:= 16;							
            DEFAULT_KITT_CAR_STEP_MS	: 	POSITIVE	RANGE	1	TO	2000    	:= 100  
        );	
        port(    
            clk				: in std_logic;
            reset			: in std_logic;    

            SwitchState     : in std_logic_vector(NUM_OF_SWS-1 downto 0);

            LedPeriod		: out std_logic_vector(NUM_OF_SWS-1 downto 0)			-- Output in ms        
        );
    end component;

    component PWM_Driver is 
        Generic(
            BIT_LENGTH	:	INTEGER ;
            T_ON_INIT	:	INTEGER ;			
            PERIOD_INIT	:	POSITIVE ;			
            PWM_INIT	:	STD_LOGIC
        );
        
        Port ( 
            clk				: in std_logic;
            reset			: in std_logic;

            Ton		        : in  std_logic_vector(BIT_LENGTH-1 downto 0);
            
            LedDriver       : out std_logic
        );
    end component;
    

    type local_mem is array(NUM_OF_LEDS-1 downto 0) of std_logic_vector(TAIL_LENGTH-1 downto 0);

    signal  tail_initialization		:	INTEGER 	RANGE 0 TO 	NUM_OF_LEDS 	:= TAIL_LENGTH;

    -- Input in ms
    signal  LedPeriod		        :   std_logic_vector(NUM_OF_SWS-1 downto 0);	                

    signal  LocalCounter		    :	integer     := 0;
    signal  LedPeriodInternal       :	integer     := 0;

    type LED_Ton_array is array(NUM_OF_LEDS-1 downto 0) of std_logic_vector(SR_DEPTH-1 downto 0);

    signal LED_Ton 		         : LED_Ton_array     := (others => (others => '0'));
    signal LED_Ton_up 	         : LED_Ton_array     := (others => (others => '0'));
    signal LED_Ton_down          : LED_Ton_array     := (others => (others => '0'));	


begin

    Switch_inst1 : Switch
        generic map(
            NUM_OF_SWS					=> NUM_OF_SWS,	
            DEFAULT_KITT_CAR_STEP_MS	=> DEFAULT_KITT_CAR_STEP_MS
        )
        port map(
            clk				=> clk,
            reset			=> reset,

            SwitchState     => sw,

            LedPeriod		=> LedPeriod
        );

    PWM_GEN :   for Index in 0 to NUM_OF_LEDS-1 generate    
                PWMx : PWM_Driver
                    generic map(   
                        BIT_LENGTH	=> SR_DEPTH,
                                                                        
                        T_ON_INIT	=> T_ON_INIT,				
                        PERIOD_INIT	=> PWM_PERIOD,			
                        
                        PWM_INIT	=> PWM_INIT
                    )
                    port map(
                        clk				=> clk,
                        reset			=> reset,

                        Ton		        => LED_Ton(Index),

                        LedDriver       => leds(Index)
                    );
                end generate PWM_GEN;

    process(clk, reset)
    begin

        --------------------------------- Output Update---------------------------------------------
        -- copy in led state the two buffers. if some leds are superimposed, select the brighter one         
        for I in 0 to NUM_OF_LEDS-1 loop
            -- looking at libraries the cast is not strictly needed
            if LED_Ton_up(I) >= LED_Ton_down(I) then

                LED_Ton(I) 	<=	LED_Ton_up(I);
            else 
                LED_Ton(I) 	<=	LED_Ton_down(I);
            end if;
        
        end loop;
              
        if reset = '1' then        
            -- reset the register with the initial values
            tail_initialization	<=	TAIL_LENGTH;
            LED_Ton_up 			<=	(others =>  (others => '0'));
            LED_Ton_down		<=	(others =>  (others => '0'));
            
            -- sample again the switch state and set the Led step period accordingly. Manage separately the case with all switch off to avoid /0
            if LedPeriod = NullPeriod then      
                LedPeriodInternal       <= 		((MIN_KITT_CAR_STEP_MS*10_000_000)/(CLK_PERIOD_NS));  

            elsif LedPeriod > NullPeriod then         
                LedPeriodInternal       <= 		((MIN_KITT_CAR_STEP_MS*10_000_000)/(CLK_PERIOD_NS)) / (to_integer(unsigned(LedPeriod)));          
            
            end if;
                    
        elsif rising_edge(clk) then
        
            --------------------------------------- SR Logic --------------------------------------
            LocalCounter <= LocalCounter + 1;
            
            -- if it's time to shift the leds :  
            if LocalCounter >= LedPeriodInternal-1 then
            
                -- reset the counter and sample again the switch state, reset the Led Step period accordingly.
                LocalCounter <= 0;
                
                if LedPeriod = NullPeriod then
                    LedPeriodInternal <= 		((MIN_KITT_CAR_STEP_MS * 1_000_000)/(CLK_PERIOD_NS)); 
                else      
                    LedPeriodInternal <= 		((MIN_KITT_CAR_STEP_MS * 1_000_000)/(CLK_PERIOD_NS)) / (to_integer(unsigned(LedPeriod)));
                end if; 
                    
                ----------------------------------------- Register Shift Logic -----------------------------------------------
                -- Register First Injection is managed separatly. Inject the "first" value until all tail LEDs initialized
        
                if tail_initialization /= 0 then					

                    --  LED(0) 
                    LED_Ton_up(0)	   		                  <=	std_logic_vector(to_unsigned(tail_initialization*TON_STEP_VALUE, SR_DEPTH));
                    
                    --  LEFT-SHIFT
                    LED_Ton_up(LED_Ton_up'HIGH downto 1)      <=	LED_Ton_up((LED_Ton_up'HIGH-1) downto 0);  
                    tail_initialization	                      <=	tail_initialization - 1;

                -- After First Injection perform the shift (until reset)
                elsif tail_initialization = 0 then					

                    -- LEFT-SHIFT
                    LED_Ton_up 		    <= 	    LED_Ton_up(LED_Ton_up'HIGH-1 downto 0) & LED_Ton_down(LED_Ton_down'LOW);
                    
                    -- RIGHT-SHIFT
                    LED_Ton_down	    <= 	    LED_Ton_up(LED_Ton_up'HIGH) & LED_Ton_down(LED_Ton_down'HIGH downto 1);
                    
                end if;
            end if;				
        end if;
    end process;
end Behavioral;