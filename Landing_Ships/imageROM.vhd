----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 21.04.2024 07:23:58
-- Design Name: 
-- Module Name: imageROM - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity imageROM is
    Port ( addRom : in STD_LOGIC_VECTOR (3 downto 0);
           dataRom : out STD_LOGIC_VECTOR (31 downto 0));
end imageROM;

architecture Behavioral of imageROM is

type ROM_B is array (0 to 15) of std_logic_vector(31 DOWNTO 0);
  constant rom:ROM_B:=( "00000000000000000000000000000000", -- 0  Espacio vacío
                        "00000000000000000000000000000000", -- 1  Espacio vacío
                        "00000000000000000000000000000000", -- 2  Espacio vacío
                        "00000000000000000000000000000000", -- 3  Espacio vacío
                        "00000000000000000000000000000000", -- 4  Espacio vacío
                        "00000000000000000000000000000000", -- 5  Espacio vacío
                        "00000000000000000000000000000000", -- 6  Espacio vacío
                        "01111111111111111111111111111110", -- 7  Borde superior del aro
                        "01111111111111111111111111111110", -- 8  Cuerpo del aro
                        "01111111111111111111111111111110", -- 9  Cuerpo del aro
                        "00011111111111111111111111111000", -- 10 Cuerpo del aro
                        "00000111111111111111111111100000", -- 11 Cuerpo del aro
                        "00000001111111111111111110000000", -- 12 Cuerpo del aro
                        "00000000011111111111111000000000", -- 13 Cuerpo del aro
                        "00000000000000000000000000000000", -- 14 Cuerpo del aro
                        "00000000000000000000000000000000");  -- 15 Borde inferior del aro
begin

dataRom<= rom(conv_integer (addRom));

end Behavioral;
