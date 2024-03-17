LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY lcd_controller IS
  PORT(
    clk        : IN   STD_LOGIC;                     --system clock
    reset_n    : IN   STD_LOGIC;                     --active high reinitializes lcd
    in_angle    : IN   INTEGER;                      --angle to display
    rw, rs, e  : OUT  STD_LOGIC;                     --read/write, setup/data, and enable for lcd
    lcd_data   : OUT  STD_LOGIC_VECTOR(7 DOWNTO 0)); --data signals for lcd
END lcd_controller;



ARCHITECTURE controller OF lcd_controller IS
  TYPE CONTROL IS(power_up, initialize, ready, send);
  SIGNAL  state  : CONTROL;
  TYPE char_mappings IS ARRAY(0 TO 9) OF STD_LOGIC_VECTOR(7 DOWNTO 0);  --Charachter codes for number 0-9
  CONSTANT char_mapping : char_mappings := (
                    "00110000", --0
                    "00110001", --1
                    "00110010", --2
                    "00110011", --3
                    "00110100", --4
                    "00110101", --5
                    "00110110", --6
                    "00110111", --7
                    "00111000", --8
                    "00111001"); --9
BEGIN
  PROCESS(clk) --add reset
    VARIABLE cntr2     : INTEGER := 0;  
    VARIABLE clk_count : INTEGER := 0;          --Event counter for timing
    VARIABLE output    : INTEGER := 0;          --What command to send to display (goes from 0 to 3, 0=clear display, 1=output hundreds, 2= output tens, 3=output ones)
  BEGIN
    IF(clk'EVENT and clk = '1') THEN

      CASE state IS
         
        --wait 50 ms to ensure Vdd has risen and required LCD wait is met
        WHEN power_up =>
          IF(clk_count < (5_000_000)) THEN           --wait 50 ms 50000
            clk_count := clk_count + 1;
            state <= power_up;
          ELSE                                       --power-up complete
            clk_count := 0;
            rs <= '0';
            rw <= '0';
            lcd_data <= "00110000";
            state <= initialize;
          END IF;
          
        --cycle through initialization sequence  
        WHEN initialize =>
          clk_count := clk_count + 1; 
          IF(clk_count < (10 * 100)) THEN              --function set
            lcd_data <= "0011" & "1" & "0" & "00";     --0011 & displaylines & charachterfont & "00"
            e <= '1';
            state <= initialize;
          ELSIF(clk_count < (6_000)) THEN        --wait 50 us
            lcd_data <= "00000000";
            e <= '0';
            state <= initialize;
          ELSIF(clk_count < (7_000)) THEN        --display on/off control
            lcd_data <= "00001100";              --00001 & on/off & cursor & blink
            e <= '1';
            state <= initialize;
          ELSIF(clk_count < (12_000)) THEN       --wait 50 us
            lcd_data <= "00000000";
            e <= '0';
            state <= initialize;
          ELSIF(clk_count < (13_000)) THEN       --display clear
            lcd_data <= "00000001";
            e <= '1';
            state <= initialize;
          ELSIF(clk_count < (213_000)) THEN      --wait 2 ms
            lcd_data <= "00000000";
            e <= '0';
            state <= initialize;
          ELSIF(clk_count < (214_000)) THEN      --entry mode set
            lcd_data <= "00000110";              --000001 & inc/dec & shift
            e <= '1';
            state <= initialize;
          ELSIF(clk_count < (220_000)) THEN  --wait 60 us
            lcd_data <= "00000000";
            e <= '0';
            state <= initialize;
          ELSE                                       --initialization complete
            clk_count := 0;
            state <= ready;
          END IF;    
       
        --wait for the enable signal and then latch in the instruction
        WHEN ready =>
          IF (clk_count = 1_000_000) THEN
              IF (output = 0) THEN
                    rs <= '0';
                    rw <= '0';
                    lcd_data <= "00000001";                         --Clear         
                    state <= send;
                    output := output + 1;
                    clk_count := 0;      
              ELSIF (output = 1) THEN
                    rs <= '1';
                    rw <= '0';
                    lcd_data <= char_mapping(in_angle/100);         --Write Xxx         
                    state <= send;
                    output := output + 1;
                    clk_count := 0;      
              ELSIF (output = 2) THEN
                    rs <= '1';
                    rw <= '0';
                    lcd_data <= char_mapping((in_angle/10) mod 10); --Write xXx       
                    state <= send;
                    output := output + 1;
                    clk_count := 0;      
              ELSIF (output = 3) THEN
                    rs <= '1';
                    rw <= '0';
                    lcd_data <= char_mapping(in_angle mod 10);      --Write xxX       
                    state <= send;
                    output := output + 1;
                    clk_count := 0; 
               ELSE
                    clk_count := 0;
                    IF(cntr2 = 100) THEN
                        output := 0;
                        cntr2 := 0;
                    ELSE 
                        cntr2 := cntr2 + 1;
                    END IF;           
              END IF;
          ELSE 
            clk_count := clk_count + 1;
          END IF;   
        
        --send instruction to lcd        
        WHEN send =>
          IF(clk_count < (50 * 100)) THEN       --do not exit for 50us
            IF(clk_count < 100) THEN              --negative enable
              e <= '0';
            ELSIF(clk_count < (14 * 100)) THEN    --positive enable half-cycle
              e <= '1';
            ELSIF(clk_count < (27 * 100)) THEN    --negative enable half-cycle
              e <= '0';
            END IF;
            clk_count := clk_count + 1;
            state <= send;
          ELSE
            clk_count := 0;
            state <= ready;
          END IF;

      END CASE;    
  
      --reset
      IF(reset_n = '0') THEN
          state <= power_up;
          clk_count := 0;
          output := 0;
      END IF;
    
    END IF;
  END PROCESS;
END controller;
