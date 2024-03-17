LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

--Komponent för att få BCD (binary coded decimal) för att lysa upp rätt
--segment på 7-segment displayen
--Kan skriva ut tal i intervallet [000-999]

ENTITY binary_coded_decimal IS
    PORT (
       in_angle       :   IN INTEGER;     
       seg_output100  :   OUT STD_LOGIC_VECTOR(7 DOWNTO 0); --BCD för hundratalet
       seg_output10   :   OUT STD_LOGIC_VECTOR(7 DOWNTO 0); --BCD för tiotalet
       seg_output1    :   OUT STD_LOGIC_VECTOR(7 DOWNTO 0)  --BCD för entalet 
    );
END binary_coded_decimal;



ARCHITECTURE Behavioral OF binary_coded_decimal IS
    
BEGIN
   
   PROCESS(in_angle)
    VARIABLE temp100 : INTEGER;
    VARIABLE temp10 : INTEGER;
    VARIABLE temp1 : INTEGER;
    
    BEGIN
        -- Första siffran (hundratal)
        temp100 := in_angle / 100;
        CASE temp100 IS
            WHEN 1 => seg_output100 <= "11111001";
            WHEN 2 => seg_output100 <= "10100100";
            WHEN 3 => seg_output100 <= "10110000";
            WHEN 4 => seg_output100 <= "10011001";
            WHEN 5 => seg_output100 <= "10010010";
            WHEN 6 => seg_output100 <= "10000010";
            WHEN 7 => seg_output100 <= "11111000";
            WHEN 8 => seg_output100 <= "10000000";
            WHEN 9 => seg_output100 <= "10010000";
            WHEN OTHERS => seg_output100 <= "11000000";
         END CASE;

        -- Andra siffran (tiotal)
        temp10 := (in_angle / 10) mod 10;
        CASE temp10 IS
            WHEN 1 => seg_output10 <= "11111001";
            WHEN 2 => seg_output10 <= "10100100";
            WHEN 3 => seg_output10 <= "10110000";
            WHEN 4 => seg_output10 <= "10011001";
            WHEN 5 => seg_output10 <= "10010010";
            WHEN 6 => seg_output10 <= "10000010";
            WHEN 7 => seg_output10 <= "11111000";
            WHEN 8 => seg_output10 <= "10000000";
            WHEN 9 => seg_output10 <= "10010000";
            WHEN OTHERS => seg_output10 <= "11000000";
         END CASE;

        -- Tredje siffran (ental)
        temp1 := in_angle mod 10;
        CASE temp1 IS
            WHEN 1 => seg_output1 <= "11111001";
            WHEN 2 => seg_output1 <= "10100100";
            WHEN 3 => seg_output1 <= "10110000";
            WHEN 4 => seg_output1 <= "10011001";
            WHEN 5 => seg_output1 <= "10010010";
            WHEN 6 => seg_output1 <= "10000010";
            WHEN 7 => seg_output1 <= "11111000";
            WHEN 8 => seg_output1 <= "10000000";
            WHEN 9 => seg_output1 <= "10010000";
            WHEN OTHERS => seg_output1 <= "11000000";
         END CASE;
    END PROCESS;

END Behavioral;
