LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- Turns signed 9-bit accelerometer data into the absolute value integer
ENTITY bin_to_int IS
    PORT (
        bin_in_y  : IN   STD_LOGIC_VECTOR(8 DOWNTO 0);   --Acceleration data of xaxis
        bin_in_x  : IN   STD_LOGIC_VECTOR(8 DOWNTO 0);   --Acceleration data of y axis
        switcher  : IN   STD_LOGIC;                      --Switch to choose mode
        int_out   : OUT  INTEGER                         --Output of the selected mode as an absolute value integer of the binary acceleration data
    );
END bin_to_int;



ARCHITECTURE Behavioral OF bin_to_int IS

    SIGNAL selected : STD_LOGIC_VECTOR(8 DOWNTO 0);      --Temp for the selected mode

    BEGIN
    selected <=  bin_in_y WHEN (switcher = '1') ELSE bin_in_x;  --Select mode (X/Y)
    
    PROCESS(bin_in_y, bin_in_x, switcher)                       --Update when x or y value updates, or if a switch of mode is made
        BEGIN
            IF(selected(8) = '1') THEN                          --The MSB is the sign bit. If it is one it means it is a negative binary number
                int_out <= -to_integer(signed(selected));       --Negate it, since we only want to deal with positive angles
            ELSE
                int_out <= to_integer(signed(selected));        
            END IF;
    END PROCESS;
    

END Behavioral;
