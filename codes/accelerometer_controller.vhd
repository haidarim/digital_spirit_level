-------------------------------------------------------
--This component controlls what adress to send what data to using
--the master_spi component. It also sets configurations in the accelerometer such as
--read mode, data rate and data range.
--After setting up, the accelerometer_controller continously read from the adresses
--0x0E to 0x13 by using the burst read which auto increments the adress counter in the accelerometer.
--It does this in a loop until it is reset.
--It outputs 3 16 bits of data, one for each axis.
-------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY accelerometer_controller IS
  GENERIC(
    data_rate  : STD_LOGIC_VECTOR := "011";               --data rate code to configure the accelerometer	
    data_range : STD_LOGIC_VECTOR := "00");               --data range code to configure the accelerometer
  PORT(
    clk             : IN      STD_LOGIC;                      --system clock
    reset_n         : IN      STD_LOGIC;                      --active low asynchronous reset
    miso            : IN      STD_LOGIC;                      --SPI bus: master in, slave out
    sclk            : OUT     STD_LOGIC;                      --SPI bus: serial clock
    cs              : OUT     STD_LOGIC;                      --SPI bus: slave select
    mosi            : OUT     STD_LOGIC;                      --SPI bus: master out, slave in
    acceleration_x  : OUT     STD_LOGIC_VECTOR(15 DOWNTO 0);  --x-axis acceleration data
    acceleration_y  : OUT     STD_LOGIC_VECTOR(15 DOWNTO 0); --y-axis acceleration data
    acceleration_z  : OUT     STD_LOGIC_VECTOR(15 DOWNTO 0)
  );
END accelerometer_controller;

ARCHITECTURE behavior OF accelerometer_controller IS
  TYPE machine IS(start, pause, configure, read_data, output_result); --needed states
  SIGNAL state              : machine := start;                       --state machine
  SIGNAL parameter          : INTEGER RANGE 0 TO 3;                   --parameter being configured
  SIGNAL parameter_addr     : STD_LOGIC_VECTOR(5 DOWNTO 0);           --register address of configuration parameter
  SIGNAL parameter_data     : STD_LOGIC_VECTOR(7 DOWNTO 0);           --value of configuration parameter
  SIGNAL spi_busy_prev      : STD_LOGIC;                              --previous value of the SPI component's busy signal, so we can se when busy just has been deasserted
  SIGNAL spi_busy           : STD_LOGIC;                              --busy signal from SPI component
  SIGNAL spi_ena            : STD_LOGIC;                              --enable for SPI component
  SIGNAL spi_cont           : STD_LOGIC;                              --continuous mode signal for SPI component
  SIGNAL spi_tx_data        : STD_LOGIC_VECTOR(7 DOWNTO 0);           --transmit data for SPI component
  SIGNAL spi_rx_data        : STD_LOGIC_VECTOR(7 DOWNTO 0);           --received data from SPI component
  SIGNAL acceleration_x_int : STD_LOGIC_VECTOR(15 DOWNTO 0);          --internal x-axis acceleration data buffer
  SIGNAL acceleration_y_int : STD_LOGIC_VECTOR(15 DOWNTO 0);          --internal y-axis acceleration data buffer
  SIGNAL acceleration_z_int : STD_LOGIC_VECTOR(15 DOWNTO 0);          --internal z-axis acceleration data buffer
 
  --declare SPI Master component
  COMPONENT master_spi IS
     PORT(
        clock   : IN     STD_LOGIC;                             --system clock
        reset_n : IN     STD_LOGIC;                             --asynchronous reset
        enable  : IN     STD_LOGIC;                             --initiate transaction
        cont    : IN     STD_LOGIC;                             --continuous mode command
        tx_data : IN     STD_LOGIC_VECTOR(7 DOWNTO 0);  	    --data to transmit
        miso    : IN     STD_LOGIC;                             --master in, slave out
        sclk    : OUT    STD_LOGIC;                             --spi clock
        cs      : OUT    STD_LOGIC;       			            --slave select
        mosi    : OUT    STD_LOGIC;                             --master out, slave in
        busy    : OUT    STD_LOGIC;                             --busy / data ready signal
        rx_data : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0)	 	    --data received
     );
  END COMPONENT master_spi;

BEGIN
  --instantiate the SPI Master component
  master_spi_0:  master_spi
    PORT MAP(
	clock => clk,
	reset_n => reset_n,
	enable => spi_ena,
	cont => spi_cont,
	tx_data => spi_tx_data,
	miso => miso,
    sclk => sclk,
	cs => cs,
	mosi => mosi,
	busy => spi_busy,
	rx_data => spi_rx_data
  );

PROCESS(clk)
    VARIABLE count : INTEGER := 0; --universal counter
  BEGIN
    IF(reset_n = '0') THEN                --reset activated
      spi_busy_prev <= '0';               --clear previous value of SPI component's busy signal
      spi_ena <= '0';                     --clear SPI component enable
      spi_cont <= '0';                    --clear SPI component continuous mode signal
      spi_tx_data <= (OTHERS => '0');     --clear SPI component transmit data
      acceleration_x <= (OTHERS => '0');  --clear x-axis acceleration data
      acceleration_y <= (OTHERS => '0');  --clear y-axis acceleration data
      acceleration_z <= (OTHERS => '0');  --clear y-axis acceleration data
      state <= start;                     --restart state machine

    ELSIF(clk'EVENT AND clk =  '1') THEN   
      CASE state IS                        

        --entry state
        WHEN start =>
          count := 0;      --clear universal counter
          parameter <= 0;  --clear parameter indicator
          state <= pause;
          
        --pauses 200ns between SPI transactions and selects SPI transaction
        WHEN pause =>
          IF(spi_busy = '0') THEN                                      --SPI component not busy
            IF(count < 20) THEN                                        --less than 200ns
              count := count + 1;        
              state <= pause;                   
            ELSE                                                        --200ns has elapsed
              count := 0;                        
              CASE parameter IS                                         --select SPI transaction
                WHEN 0 =>                                               --SPI transaction to set range and data rate
                  parameter <= parameter + 1;                           --increment parameter for next transaction
                  parameter_addr <= "101100";                           --register address with range and data rate settings
                  parameter_data <= data_range & "010" & data_rate;     --data to set specified range and date rate
                  state <= configure;                                   --proceed to start SPI transaction
                WHEN 1 =>                                               --SPI transaction to enable measuring
                  parameter <= parameter + 1;                           --increment parameter for next transaction
                  parameter_addr <= "101101";                           --register address with enable measurement setting
                  parameter_data <= "00000010";                         --data to enable measurement
                  state <= configure;                                   --proceed to SPI transaction
                WHEN 2 =>                                               --SPI transaction to read data
                  state <= read_data;                                   --proceed to SPI transaction
                WHEN OTHERS => NULL;
              END CASE;        
            END IF;
          END IF;

        --performs SPI transactions that write to configuration registers  
        WHEN configure =>
          spi_busy_prev <= spi_busy;                            --capture the value of the previous spi busy signal
          IF(spi_busy_prev = '1' AND spi_busy = '0') THEN       --spi busy just went low				           
		      count := count + 1;                             --counts times busy goes from high to low during transaction
          END IF;
          
          CASE count IS                                   --number of times busy has gone from high to low
            WHEN 0 =>                                       --no busy deassertions
              IF(spi_busy = '0') THEN                         --transaction not started
                spi_cont <= '1';                                --set to continuous mode
                spi_ena <= '1';                                 --enable SPI transaction
                spi_tx_data <= "00001010";                      --first information to send (write command)
              ELSE	                                                        --transaction latched in
                spi_tx_data <= "00" & parameter_addr;           --second information to send (register address) 00101100
              END IF;
            WHEN 1 =>
                spi_tx_data <= parameter_data;                    --third information to send (write data)  
            WHEN 2 =>                                         --first busy deassertion
		        spi_cont <= '0';                                --clear continous mode to end transaction
                spi_ena <= '0';                                 --clear SPI transaction enable
                count := 0;
                state <= pause;                                 --return to pause state
            WHEN OTHERS => NULL;
          END CASE;

        --performs SPI transactions that read acceleration data registers  
        WHEN read_data =>
          spi_busy_prev <= spi_busy;                        --capture the value of the previous spi busy signal
          IF(spi_busy_prev = '1' AND spi_busy = '0') THEN   --spi busy just went low
            count := count + 1;                               --counts the times busy goes from high to low during transaction
          END IF;
                    
          CASE count IS                                     --number of times busy has gone from high to low
            WHEN 0 =>                                         --no busy deassertions
                IF(spi_busy = '0') THEN                           --transaction not started
                    spi_cont <= '1';                                  --set to continuous mode
                    spi_ena <= '1';                                   --enable SPI transaction
                    spi_tx_data <= "00001011";                        --first information to send (read command)
                ELSE                                             --transaction latched in
                    spi_tx_data <= "00001110";                        --second information to send (register address)
                END IF;
            WHEN 1 =>                                         --3rd busy deassertion
             spi_tx_data <= "00000000";                        --third information to send
            WHEN 3 =>                                         --4th busy deassertion
              acceleration_x_int(7 DOWNTO 0) <= spi_rx_data;    --latch in first received acceleration data    
            WHEN 4 =>                                         --5th busy deassertion
              acceleration_x_int(15 DOWNTO 8) <= spi_rx_data;   --latch in second received acceleration data
            WHEN 5 =>
                acceleration_y_int(7 DOWNTO 0) <= spi_rx_data;                          --clear SPI transaction enable
            WHEN 6 =>
                acceleration_y_int(15 DOWNTO 8) <= spi_rx_data; 
            WHEN 7 =>
              acceleration_z_int(7 DOWNTO 0) <= spi_rx_data;    --latch in third received acceleration data         
              spi_cont <= '0';                                  --clear continuous mode to end transaction
              spi_ena <= '0';                                   --clear SPI transaction enable
            WHEN 8 =>                                         --6th busy deassertion
              acceleration_z_int(15 DOWNTO 8) <= spi_rx_data;   --latch in fourth received acceleration data
               count := 0;                                       --clear universal counter
              state <= output_result; 
            WHEN OTHERS => NULL;
          END CASE;
  
        --outputs acceleration data
        WHEN output_result =>
            acceleration_x <= acceleration_x_int(15 DOWNTO 0);  --output x-axis data
            acceleration_y <= acceleration_y_int(15 DOWNTO 0);  --output y-axis data
            acceleration_z <= acceleration_z_int(15 DOWNTO 0);  --output z-axis data
            state <= pause;                                     --return to pause state
        
        --default to start state
        WHEN OTHERS => 
          state <= start;

      END CASE;      
    END IF;

END PROCESS;

END behavior;