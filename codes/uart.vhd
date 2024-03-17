
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY uart IS
  GENERIC(
    baud_rate :  INTEGER    := 9600                         --Generic baud rate
  );       
  PORT(
    clk      :  IN   STD_LOGIC;                             --System clock
    reset_n  :  IN   STD_LOGIC;                             --Ascynchronous reset
    tx_ena   :  IN   STD_LOGIC;                             --Enable transmission
    tx_data  :  IN   STD_LOGIC_VECTOR(7 DOWNTO 0);          --Byte to transmitt
    tx       :  OUT  STD_LOGIC);                            --Transmit pin
END uart;
    
ARCHITECTURE logic OF uart IS
  TYPE   tx_machine IS(idle, transmit);                                         --State machine
  SIGNAL tx_state     :  tx_machine := idle;                                    --State machine starts in idle
  SIGNAL baud_pulse   :  STD_LOGIC := '0';                                      --A baud pulse is generated every 1/baud_rate second
  SIGNAL tx_buffer    :  STD_LOGIC_VECTOR(9 DOWNTO 0) := (OTHERS => '1');       --Byte to be transmitted. Data is loaded into this buffer before entring to the transmitt state.
BEGIN

 
  PROCESS(reset_n, clk)                                                         --Baud pulse generator
    VARIABLE count_baud :  INTEGER RANGE 0 TO 100000000/baud_rate-1 := 0;       --Counter for baud rate period (clock cyles in one baud period)
      BEGIN
        IF(reset_n = '0') THEN                                                  --Asynchronous reset
          baud_pulse <= '0';                              
          count_baud := 0;                                
        ELSIF(clk'EVENT AND clk = '1') THEN
          IF(count_baud < 100000000/baud_rate-1) THEN         --count up one baud_pulse
            count_baud := count_baud + 1;                     --increment baud period counter
            baud_pulse <= '0';                                 
          ELSE                                                --baud period reached
            count_baud := 0;                                  --reset baud period counter
            baud_pulse <= '1';                                --generate a baud pulse
          END IF;
      
        END IF;
  END PROCESS;
    

  PROCESS(reset_n, clk)
    VARIABLE tx_count :  INTEGER RANGE 0 TO 11 := 0;       --count bits transmitted (1 start bit + 8 data bits + end bit) one missing???????????????????
  BEGIN
    IF(reset_n = '0') THEN                                      --asynch reset for the state machine
      tx_count := 0;                                            --reset transmit bit counter
      tx <= '1';                                                --set tx pin to idle value of high (a start bit is 0, so when its 1 the PC(reciver) knows nothing is happening
      tx_state <= idle;                                         --set tx state machine to the idel state
      
    ELSIF(clk'EVENT AND clk = '1') THEN
      CASE tx_state IS
        WHEN idle =>                                                  --idle state
          IF(tx_ena = '1') THEN                                       --enable new transaction 
            tx_buffer(9 DOWNTO 0) <=  tx_data & '0' & '1';            --latch in data for transmission and stop bit, 0 is the start bit, 1 is a dummy value, since tx_buffer(0) is coontinously sent. See line 74..
            tx_count := 0;                                            --clear transmit bit count
            tx_state <= transmit;                                     --proceed to transmit state
          ELSE                                                        --No new transaction started
            tx_state <= idle;                                         --Remain in idle state
          END IF;
          
        WHEN transmit =>                                          --transmit state
          IF(baud_pulse = '1') THEN                              
            tx_count := tx_count + 1;                             --inc transmit bit counter
            tx_buffer <= '1' & tx_buffer(9 DOWNTO 1);             --shift transmit buffer to output next bit. We shift in 1 since 1 is the stop bit.
          END IF;
          IF(tx_count < 11) THEN                                      --not all bits transmitted
            tx_state <= transmit;                                     --so remain in transmit state
          ELSE                                                        --all bits transmitted
            tx_state <= idle;                                         --so return to idle state
          END IF;
      END CASE;
      tx <= tx_buffer(0);                                       --output LSB! (the serial connection starts with LSB and ends with MSB)
    END IF;
  END PROCESS;  
END logic;
