LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

--Controller for the seven segment display, loads incoming BCDs every 1/4s and has a refreshrate of 10ms
--WE ONLY NEED AN 0-
ENTITY seven_seg IS
    PORT ( 
        clk     :  IN   STD_LOGIC;                     --System clock
        reset_n :  IN   STD_LOGIC;                     --System reset
        number_to_display : IN INTEGER;                --Number to display on the 7 segment display 
        AN      :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0);  --Select which of the 8 display to activate. Active low.
        data    :  OUT  STD_LOGIC_VECTOR(7 DOWNTO 0)   --Number to display
    );
END seven_seg;



ARCHITECTURE Behavioral of seven_seg IS
SIGNAL seg1_load : STD_LOGIC_VECTOR(7 DOWNTO 0);                     --For storing hundred-digit
SIGNAL seg2_load : STD_LOGIC_VECTOR(7 DOWNTO 0);                     --For stroing ten-digit
SIGNAL seg3_load : STD_LOGIC_VECTOR(7 DOWNTO 0);                     --For storing one-digit

TYPE bcd_mappings IS ARRAY(0 TO 9) OF STD_LOGIC_VECTOR(7 DOWNTO 0);  --BCD mappings
   CONSTANT bcd_mapping : bcd_mappings := (
                    "11000000", --0
                    "11111001", --1
                    "10100100", --2
                    "10110000", --3
                    "10011001", --4
                    "10010010", --5
                    "10000010", --6
                    "11111000", --7
                    "10000000", --8
                    "10010000"); --9
BEGIN
PROCESS(clk)
    VARIABLE counter : integer := 0;        --Counter to distribute the "light-up-time" between the digits on the display.
    VARIABLE to_display : integer := 0;     --
    VARIABLE load_counter : integer := 0;   --Counter for timing when to latch in data
    
    BEGIN
        IF rising_edge(clk) THEN
            
            --Latches in the angle to its buffers every 25_000_000 clk cycles (0,25s) and splits upp the digits into hundreds, tens and ones.
            load_counter := load_counter + 1;
            IF load_counter > 25_000_000 THEN
                seg3_load <= bcd_mapping(number_to_display / 100);              --Hundreds
                seg2_load <= bcd_mapping((number_to_display / 10) mod 10);      --Tens
                seg1_load <= bcd_mapping(number_to_display mod 10);             --Ones
                load_counter := 0;                                              
            END IF;
            
            
            counter := counter + 1;
            IF(counter = 333_333) THEN  --Switches display every 10ms/3 to get a refresh rate of 10ms 
                counter := 0;
                to_display := to_display + 1;
                IF (to_display = 4) THEN
                    to_display := 1;
                END IF;     
            END IF;
            
            
            -- Control which display is active and load the correct data
            CASE to_display IS
                WHEN 1 =>
                    AN(0) <= '0';
                    AN(1) <= '1';
                    AN(2) <= '1';
                    AN(3) <= '1';
                    AN(4) <= '1';
                    AN(5) <= '1';
                    AN(6) <= '1';
                    AN(7) <= '1';
                    data <= seg1_load;

                WHEN 2 =>
                   AN(0) <= '1';
                    AN(1) <= '0';
                    AN(2) <= '1';
                    AN(3) <= '1';
                    AN(4) <= '1';
                    AN(5) <= '1';
                    AN(6) <= '1';
                    AN(7) <= '1';
                    data <= seg2_load;
                    
                WHEN 3 =>
                    AN(0) <= '1';
                    AN(1) <= '1';
                    AN(2) <= '0';
                    AN(3) <= '1';
                    AN(4) <= '1';
                    AN(5) <= '1';
                    AN(6) <= '1';
                    AN(7) <= '1';
                    data <= seg3_load;
                
                --(Unreachable)
                WHEN OTHERS =>
                    AN(0) <= '1';
                    AN(1) <= '1';
                    AN(2) <= '1';
                    AN(3) <= '1';
                    AN(4) <= '1';
                    AN(5) <= '1';
                    AN(6) <= '1';
                    AN(7) <= '1';
                    data <= "10101010";
            END CASE;
        END IF;
    END PROCESS;

END Behavioral;
