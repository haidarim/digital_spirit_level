
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

ENTITY master_spi IS
    
  PORT(
    clock   : IN     STD_LOGIC;                             --system clock
    reset_n : IN     STD_LOGIC;                             --asynch reset
    enable  : IN     STD_LOGIC;                             --enable transaction
    cont    : IN     STD_LOGIC;                             --continuous mode. ADXL362 automatically increment adress. Used for burst reads.
    tx_data : IN     STD_LOGIC_VECTOR(7 DOWNTO 0);          --data to transmit to ADXL362
    miso    : IN     STD_LOGIC;                             --master in  
    sclk    : OUT     STD_LOGIC;                            --spi clock  
    cs      : OUT    STD_LOGIC;                             --chip select
    mosi    : OUT    STD_LOGIC;                             --master out
    busy    : OUT    STD_LOGIC;                             --busy / data ready signal
    rx_data : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0));         --data received
END master_spi;



ARCHITECTURE logic OF master_spi IS
  TYPE machine IS(ready, execute);                           --state machine data type
  SIGNAL state       : machine;                              --current state
  SIGNAL clk_ratio   : INTEGER;                              --current clk_div
  SIGNAL count       : INTEGER;                              --counter to trigger sclk from system clock, set to 5MHz
  SIGNAL clk_toggles : INTEGER RANGE 0 TO 17;                --count spi clock toggles
  SIGNAL assert_data : STD_LOGIC;                            --'1' is tx sclk toggle, '0' is rx sclk toggle
  SIGNAL continue    : STD_LOGIC;                            --flag to continue transmitting whitout leaving execute state
  SIGNAL rx_buffer   : STD_LOGIC_VECTOR(7 DOWNTO 0);	     --receive data buffer
  SIGNAL tx_buffer   : STD_LOGIC_VECTOR(7 DOWNTO 0);         --transmit data buffer
  SIGNAL last_bit_rx : INTEGER RANGE 0 TO 16;                --last rx data bit location
  
  SIGNAL cs_internal : STD_LOGIC;               --TODO: REMOVE ALL INSTANCES OF THIS
  SIGNAL sclk_internal : STD_LOGIC := '0';      --Used as a substitute for sclk so that we can use it in internal condition statements, since sclk cant be used as it because it is an output signal
BEGIN

  PROCESS(clock, reset_n)
    CONSTANT clk_div : INTEGER := 10;                        --system clock cycles per 1/2 period of sclk
                                                             -- The ADXL362 works in the SPI clock speed range 1MHz to 8MHz
                                                             -- So by dividing system clock by 10 we get 100_000_000/10 = 10MHz for half a cycle
                                                             -- and 5MHz for a whole cycle 
  BEGIN
    
    IF(reset_n = '0') THEN        --reset system
      busy <= '1';                --set busy signal
      cs_internal <='1';          --deassert slave (active low) 
      mosi <= 'Z';                --set master out to high impedance
      rx_data <= (OTHERS => '0'); --clear receive data port
      state <= ready;

    ELSIF(clock'EVENT AND clock = '1') THEN
      CASE state IS              

        WHEN ready =>              --Ready to start transaction
          busy <= '0';             --Ready to take orders from top component
          sclk_internal <= '0';    --clear internal clock
          cs_internal <= '1';      --set chip select to high (active low) 
          mosi <= 'Z';             --set mosi output high impedance
          continue <= '0';         --clear continue flag

          --user input to initiate transaction
          IF(enable = '1') THEN       
            busy <= '1';             --set busy signal         
            count <= clk_div;        --initiate system-to-spi clock counter 
            tx_buffer <= tx_data;    --clock in data for transmit into buffer
            clk_toggles <= 0;        --initiate clock toggle counter
            last_bit_rx <= 15;       --set last rx data bit
            assert_data <= '1';      --'1' is TX sclk toggle, '0' is RX sclk toggle
            state <= execute;        --proceed to execute state
          
          ELSE
            state <= ready;          --remain in ready state
          END IF;

        WHEN execute =>
          busy <= '1';     		                --set busy signal
          cs_internal <= '0';			        --set slave select low
          
          --system clock to sclk ratio is met
          IF(count = clk_div) THEN        
            count <= 1;                         --reset system-to-spi clock counter
            assert_data <= NOT assert_data;     --switch transmit/receive indicator
            IF(clk_toggles = 17) THEN           
              clk_toggles <= 0;                 --reset spi clock toggles counter
            ELSE
              clk_toggles <= clk_toggles + 1;   --increment spi clock toggles counter
            END IF;
            
            --spi clock toggle needed
            IF(clk_toggles <= 16) THEN 
              sclk_internal <= NOT sclk_internal; --toggle spi clock
            END IF;
            
            --receive spi clock toggle
            IF(assert_data = '0' AND clk_toggles < last_bit_rx + 1 AND cs_internal = '0') THEN 
              rx_buffer <= rx_buffer(6 DOWNTO 0) & miso; --shift in received bit
            END IF;
            
            --transmit spi clock toggle
            IF(assert_data = '1' AND clk_toggles < last_bit_rx) THEN 
              mosi <= tx_buffer(7);                     --clock out data bit
              tx_buffer <= tx_buffer(6 DOWNTO 0) & '0'; --shift data transmit buffer
            END IF;
            
            --last data receive, but continue
            IF(clk_toggles = last_bit_rx AND cont = '1') THEN 
              tx_buffer <= tx_data;                       --reload transmit buffer
              clk_toggles <= last_bit_rx - 15; --reset spi clock toggle counter
              continue <= '1';                            --set continue flag
            END IF;
            
            --normal end of transaction, but continue
            IF(continue = '1') THEN  
              continue <= '0';      --clear continue flag
              busy <= '0';          --clock out signal that first receive data is ready
              rx_data <= rx_buffer; --clock out received data to output port    
            END IF;
            
            --end of transaction
            IF(clk_toggles = 17 AND cont = '0') THEN 
              busy <= '0';             --clock out not busy signal
              cs_internal <= '1';      --set all slave selects high
              mosi <= 'Z';             --set mosi output high impedance
              rx_data <= rx_buffer;    --clock out received data to output port
              state <= ready;          --return to ready state
              
            ELSE                       --not end of transaction
              state <= execute;        --remain in execute state
            END IF;
          
          ELSE                    --system clock to sclk ratio not met
            count <= count + 1;   --increment counter
            state <= execute;     --remain in execute state
          END IF;

      END CASE;
    END IF;
  END PROCESS; 
	cs <= cs_internal;
	sclk <= sclk_internal;
END logic;

