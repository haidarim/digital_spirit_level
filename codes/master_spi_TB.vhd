LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;


entity master_spi_TB is end master_spi_TB;


architecture behavioral of master_spi_TB is 

component master_spi is
port 
(
	clock   : IN     STD_LOGIC;                             --system clock
    reset_n : IN     STD_LOGIC;                             --asynchronous reset
    enable  : IN     STD_LOGIC;                             --initiate transaction
    cont    : IN     STD_LOGIC;                             --continuous mode command
    tx_data : IN     STD_LOGIC_VECTOR(7 DOWNTO 0);          --data to transmit
    miso    : IN     STD_LOGIC;                             --master in, slave out
    
    sclk    : BUFFER     STD_LOGIC;                         --spi clock
    cs      : BUFFER    STD_LOGIC;                          --chip select
    mosi    : OUT    STD_LOGIC;                             --master out, slave in
    busy    : OUT    STD_LOGIC;                             --busy / data ready signal
    rx_data : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0) --data received
);

end component; 

signal clk_tst: std_logic;
signal reset_tst: std_logic;
signal enable_tst: std_logic;
signal cont_tst: std_logic;
signal tx_data_tst: std_logic_vector(7 downto 0);
signal miso_tst: std_logic;
signal sclk_tst: std_logic;
signal cs_tst: std_logic;
signal mosi_tst: std_logic;
signal busy_tst: std_logic;
signal rx_data_tst: std_logic_vector(7 downto 0);
begin 

master_spi_tst: 
component master_spi port map
(
	clock => clk_tst,                             --system clock
    reset_n => reset_tst,                            --asynchronous reset
    enable => enable_tst,                             --initiate transaction
    cont => cont_tst,                             --continuous mode command
    tx_data => tx_data_tst,           --data to transmit
    miso => miso_tst,                            --master in, slave out
    
    sclk => sclk_tst,                        --spi clock
    cs  => cs_tst,                         --chip select
    mosi => mosi_tst,                             --master out, slave in
    busy => busy_tst,                             --busy / data ready signal
    rx_data => rx_data_tst --data received
);

	enable_tst <= '1';
  clk_proc:

   PROCESS
   BEGIN
      WAIT FOR 50 ns;
      clk_tst<=NOT(clk_tst);
   END PROCESS clk_proc;



end behavioral; 
