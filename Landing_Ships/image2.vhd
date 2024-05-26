----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 20.04.2024 23:25:00
-- Design Name: 
-- Module Name: image - Behavioral
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity image2 is
  Port (     
    pix_x : in STD_LOGIC_VECTOR (10 downto 0);
    pix_y : in STD_LOGIC_VECTOR (10 downto 0);
    paint: out std_logic;
    POSX: in INTEGER:= 0;
    POSY: in INTEGER:= 0
    );
end image2;

architecture Behavioral of image2 is

--------------Declarar componetes----------------------------
-------------------------------------------------------------
component imageROM is
    Port ( addRom : in STD_LOGIC_VECTOR (3 downto 0);
           dataRom : out STD_LOGIC_VECTOR (31 downto 0));
end component;

--------------Senales internas-------------------------------
-------------------------------------------------------------
signal addRom_sig : STD_LOGIC_VECTOR (3 downto 0);
signal dataRom_sig : STD_LOGIC_VECTOR (31 downto 0);

signal rowRom: integer; --Senal para recorrer las filas del la imagen almacenada en la ROM
signal colRom: integer; --Senal para recorrer las columnas del la imagen almacenada en la ROM

-------------Tamano de la ROM--------------------------------
constant sizeColRom : integer :=32;
constant sizeRowRom : integer :=16;


begin
--Instancias de la ROM, contiene la imagen.  
img1 : imageROM
    port map(
        addRom => addRom_sig,
        dataRom => dataRom_sig
    );
--Procesos para dibujar la imagen que se encuentra en la ROM
process(pix_x,pix_y)
begin
    
    if(pix_y>=POSY) AND (pix_y<(POSY+sizeRowRom))AND(pix_x>=POSX) AND (pix_x<(POSX+sizeColRom)) then
        rowRom <= conv_integer(pix_y - POSY);
        addRom_sig <= std_logic_vector(to_unsigned(rowRom,addRom_sig'length));
        colRom <= conv_integer(not(pix_x-POSX)); 
        paint <= dataRom_sig(colRom);
    else paint <='0';
    end if;
end process;

end Behavioral;