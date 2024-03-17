library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.NUMERIC_STD.ALL;


entity logic_controller is
  PORT(
    clk_top     : IN      STD_LOGIC;                   --System clock
    reset_top   : IN      STD_LOGIC;                   --Reset
    
    --switches
     mode       : IN  STD_LOGIC;                       --Switch for selecting "mode" between X and Y
    
    --LCD I/O
    rw, rs, e   : OUT STD_LOGIC;                       --read/write, setup/data, and enable for lcd
    lcd_data    : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);    --data signals for lcd
    
    --Acceleromter I/O
    ACL_MISO    : IN STD_LOGIC;
    ACL_CSN     : OUT STD_LOGIC;
    ACL_SCLK    : OUT STD_LOGIC;
    ACL_MOSI    : OUT STD_LOGIC;
    
    --7-seg
    AN               : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    seg7_data        : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    
    --UART
    tx_top       :  OUT  STD_LOGIC                     --Bit to send over UART
    );
end logic_controller;

architecture Behavioral of logic_controller is
    
    --Signals for receiving acceleration values in the 3 different axes from the acceleromter_controller
    SIGNAL signal_acc_x : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL signal_acc_y : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL signal_acc_z : STD_LOGIC_VECTOR(15 DOWNTO 0);

    COMPONENT accelerometer_controller IS
        PORT(
            clk            : IN STD_LOGIC;                           --System clock
            reset_n        : IN      STD_LOGIC;                      --Synchronous reset
            miso           : IN      STD_LOGIC;                      --SPI bus: master in, slave out
            sclk           : OUT     STD_LOGIC;                      --SPI bus: serial clock
            cs             : OUT     STD_LOGIC;                      --SPI bus: slave select
            mosi           : OUT     STD_LOGIC;                      --SPI bus: master out, slave in
            acceleration_x : OUT     STD_LOGIC_VECTOR(15 DOWNTO 0);   --x-axis acceleration data
            acceleration_y : OUT     STD_LOGIC_VECTOR(15 DOWNTO 0);   --y-axis acceleration data 
            acceleration_z : OUT     STD_LOGIC_VECTOR(15 DOWNTO 0)    --z-axis acceleration data
        );
    END COMPONENT accelerometer_controller;
    
    -- Signals for uart
    SIGNAL signal_tx_ena   :  STD_LOGIC;                              --Temp for enable of UART
    SIGNAL signal_tx_data  :  STD_LOGIC_VECTOR(7 DOWNTO 0);           --Temp signal for the angle to output to via the UART converted to binary
    
    COMPONENT uart IS
        PORT(
            clk      :  IN   STD_LOGIC;                               --System clock                         
            reset_n  :  IN   STD_LOGIC;                               --Synchronous reset     
            tx_ena   :  IN   STD_LOGIC;                               --Enable
            tx_data  :  IN   STD_LOGIC_VECTOR(7 DOWNTO 0);            --Byte message for the component to send             
            tx       :  OUT  STD_LOGIC                                --Bit of data being transmitted
        );
    END COMPONENT uart;

    COMPONENT lcd_controller IS
    PORT(
       clk        : IN  STD_LOGIC;                                   --system clock
       reset_n    : IN  STD_LOGIC;                                   --synchronous reset
       in_angle   : IN  INTEGER;                                     --Number to display on the lcd
       rw, rs, e  : OUT STD_LOGIC;                                   --read/write, setup/data, and enable for lcd
       lcd_data   : OUT STD_LOGIC_VECTOR(7 DOWNTO 0));               --Data to send to the lcd
    END COMPONENT;
  
  COMPONENT seven_seg is
    Port ( 
        clk                   :  IN  STD_LOGIC;                     --system clock
        reset_n               :  IN  STD_LOGIC;                     --TODO
        number_to_display     :  IN  INTEGER;                       --Number to display on the 7-seg
        AN                    :  OUT STD_LOGIC_VECTOR(7 DOWNTO 0);  --Active low. Select which digit on the display to light up
        data                  :  OUT STD_LOGIC_VECTOR(7 DOWNTO 0)   --Binary coded decimal being sent to the 7-seg
    );
   END COMPONENT;
   
   COMPONENT bin_to_int is
    Port (
        bin_in_y     : IN STD_LOGIC_VECTOR(8 DOWNTO 0);             --Acceleration value of X
        bin_in_x     : IN STD_LOGIC_VECTOR(8 DOWNTO 0);             --Acceleration value of Y
        int_out      : OUT INTEGER;                                 --The absolute integer value of the selected acceleration value (X or Y)
        switcher     : IN STD_LOGIC                                 --Switch output mode between X and Y
    );
    END COMPONENT;
     
    SIGNAL selected_signal: INTEGER;                                --The output of the bin_to_inte selector is stored in this value

    COMPONENT angle_converter IS
    Port (
        in_val     : IN  INTEGER;                                   --The acceleration of the selected axes in the form of an integer
        z_MSB      : IN  STD_LOGIC;                                 --The most significant bit(which is the sign-bit) of the Z acceleration data
        angle      : OUT INTEGER                                    --The corresponding angle (in range 0-180)
    );
    END COMPONENT;  

    SIGNAL signal_angle : INTEGER;                                  --The angle is temporary stored in this signal before being outputted to the graphic displays and UART
    
    
BEGIN
   acceleromter_controller_0: accelerometer_controller
    PORT MAP(
        clk => clk_top,
        reset_n => reset_top,
        miso => ACL_MISO, 
        sclk => ACL_SCLK, 
        cs => ACL_CSN,  
        mosi => ACL_MOSI,
        acceleration_x => signal_acc_x,
        acceleration_y => signal_acc_y,
        acceleration_z => signal_acc_z
    );
    
    uart_0: uart
    PORT MAP(
        clk => clk_top,
        reset_n => reset_top,
        tx_ena => signal_tx_ena,
        tx_data => signal_tx_data,
        tx => tx_top  
    );
    
    
     
lcd_controller_0: lcd_controller
    PORT MAP(clk => clk_top,
             reset_n => reset_top,
             in_angle => signal_angle,
             rw => rw,
             rs => rs,
             e => e,
             lcd_data => lcd_data
     );
    
    seven_seg_0: seven_seg
    PORT MAP ( 
        clk => clk_top,
        reset_n => reset_top,
        number_to_display => signal_angle,
        AN => AN,         
        data => seg7_data
    );
    
    
    bin_to_int_0: bin_to_int
    PORT MAP(
        bin_in_x => signal_acc_x(11 DOWNTO 3),
        bin_in_y => signal_acc_y(11 DOWNTO 3),
        int_out => selected_signal,
        switcher => mode
    );
    
    
    angle_converter_0 : angle_converter
    PORT MAP (
        in_val => selected_signal,
        z_MSB => signal_acc_z(11),
        angle => signal_angle
    );
    
--Process for setting the UART output rate to 1 message (binary representation of angle) per second.
PROCESS(clk_top)
  VARIABLE cntr: integer := 0;
    BEGIN 
    
       IF RISING_EDGE(clk_top) THEN
          IF (cntr < 100_000_000) THEN 
            cntr := cntr +1;
            signal_tx_ena <= '0';
          ELSE
            cntr := 0;
            signal_tx_ena<= '1';        
          END IF;
       END IF;

END PROCESS;

    signal_tx_data <=  STD_LOGIC_VECTOR(TO_UNSIGNED(signal_angle, 8));

END Behavioral;