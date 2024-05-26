----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 20.04.2024 15:34:44
-- Design Name: 
-- Module Name: topROM - Behavioral
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

USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

entity topROM is
  Port (   CLK : in  STD_LOGIC;
           RST : in  STD_LOGIC;
           HS : out  STD_LOGIC;
           VS : out  STD_LOGIC;
           POS : in  STD_LOGIC_VECTOR (7 downto 0);
           PB : in STD_LOGIC_VECTOR (1 downto 0);
           VEL : in STD_LOGIC_VECTOR (1 downto 0);
           seed_sw: in STD_LOGIC_VECTOR (5 downto 0);
           T_Game : in STD_LOGIC_VECTOR (1 downto 0);
           RGB : out  STD_LOGIC_VECTOR (11 downto 0)           
           );
end topROM;

architecture Behavioral of topROM is

--------------Declarar componetes----------------------------
-------------------------------------------------------------
component vga_ctrl_640x480_60Hz is
    port(
       rst         : in std_logic;
       clk         : in std_logic;
       rgb_in      : in std_logic_vector(11 downto 0);
       HS          : out std_logic;
       VS          : out std_logic;
       hcount      : out std_logic_vector(10 downto 0);
       vcount      : out std_logic_vector(10 downto 0);
       rgb_out     : out std_logic_vector(11 downto 0);--R3R2R1R0GR3GR3GR3GR3B3B2B1B0
       blank       : out std_logic
    );
end component;

component image is
  Port (     
    pix_x : in STD_LOGIC_VECTOR (10 downto 0);
    pix_y : in STD_LOGIC_VECTOR (10 downto 0);
    paint: out std_logic;
    POSX: in INTEGER:= 0;
    POSY: in INTEGER:= 0
    );
end component;

component image2 is
  Port (     
    pix_x : in STD_LOGIC_VECTOR (10 downto 0);
    pix_y : in STD_LOGIC_VECTOR (10 downto 0);
    paint: out std_logic;
    POSX: in INTEGER:= 0;
    POSY: in INTEGER:= 0
    );
end component;

COMPONENT display 
GENERIC ( LW: INTEGER:=10;
             DW: INTEGER:=50;
             DL: INTEGER:=100;
             POSX: INTEGER:= 0;
             POSY: INTEGER:= 0
        ); 
PORT (  HCOUNT : in  STD_LOGIC_VECTOR (10 downto 0);
       VCOUNT : in  STD_LOGIC_VECTOR (10 downto 0);
       VALUE : in  STD_LOGIC_VECTOR (3 downto 0);
       PAINT : out  STD_LOGIC);
end COMPONENT;

COMPONENT BIN2BCD_0a999
PORT(
    BIN : IN std_logic_vector(9 downto 0);          
    BCD2 : OUT std_logic_vector(3 downto 0);
    BCD1 : OUT std_logic_vector(3 downto 0);
    BCD0 : OUT std_logic_vector(3 downto 0)
    );
END COMPONENT;

COMPONENT display34segm is
   generic ( SG_WD : integer range 0 to 31 := 5; --Segment width
            DL : integer range 0 to 511 := 100  --DYSPLAY_LENGTH
           );  
    port(   posx : in integer range 0 to 639; 
            posy : in integer range 0 to 480;
            segments : in STD_LOGIC_VECTOR (33 downto 0);
            hcount : in  STD_LOGIC_VECTOR (10 downto 0);
            vcount : in  STD_LOGIC_VECTOR (10 downto 0);
            paint : out  STD_LOGIC);
END COMPONENT display34segm;

--------------Senales internas-------------------------------
-------------------------------------------------------------
signal clk_interno: std_logic;
signal rgb_aux: std_logic_vector(11 downto 0);
signal hcount : STD_LOGIC_VECTOR (10 downto 0);
signal vcount : STD_LOGIC_VECTOR (10 downto 0);
signal paintIng: std_logic;
signal paint_b1 : STD_LOGIC;
signal paint_b2 : STD_LOGIC;
signal paint_b3: STD_LOGIC;


signal paint_num: STD_LOGIC_VECTOR(2 downto 0);
signal paint_pts: STD_LOGIC_VECTOR(2 downto 0);

signal paint34seg: STD_LOGIC;

-- Senales de caída
signal fall_1 : INTEGER:=100;
signal fall_2 : INTEGER:=100;
signal fall_3 : INTEGER:=100;
signal count_clk_fall : INTEGER:=0;
signal CLK_fall : STD_LOGIC:='0';
signal v_fall : INTEGER:=0;

signal end1 : boolean:= false;
signal end2 : boolean:= false;
signal end3 : boolean:= false;

signal p1 : INTEGER:=100;
signal p2 : INTEGER:=300;
signal p3 : INTEGER:=500;

-- Numeros Aleatorios
signal random_value1: INTEGER range 0 to 605;
signal random_value2: INTEGER range 0 to 605;
signal random_value3: INTEGER range 0 to 605;
signal seedn: INTEGER;
constant c_increment : integer := 1013904223;

constant c_modulus : INTEGER := 2**15 - 1;  -- Módulo, debe ser un número primo grande
constant c_multiplier : INTEGER := 13;     -- Multiplicador, debe ser un número primo
signal seed1 : INTEGER := 135642789; 
signal seed2 : INTEGER := 624159837; 
signal seed3 : INTEGER := 472189635;

-- Relojes PB
signal count_clk : INTEGER:=0;
signal CLK_nHz : STD_LOGIC:='0';
signal conteo : INTEGER:=320;

-- Contadores de Puntuación y tiempo
signal count_clk1 : INTEGER:=0;
signal t_vector : std_logic_vector(9 downto 0);
signal clk_1Hz : STD_LOGIC:='0';
constant t_max : integer := 100;
signal t_counter : INTEGER:= t_max;
signal end_t : boolean:= false;

signal points : integer := 0;
signal p_vector : std_logic_vector(9 downto 0) := "0000000000";

signal unidades_t : std_logic_vector(3 downto 0);
signal decenas_t : std_logic_vector(3 downto 0);
signal centenas_t : std_logic_vector(3 downto 0);

signal unidades_p : std_logic_vector(3 downto 0);
signal decenas_p : std_logic_vector(3 downto 0);
signal centenas_p : std_logic_vector(3 downto 0);

begin

-- Velocidad de caída y tiempo de juego
v_fall <=  to_integer(unsigned(VEL));

-- Semilla del Dispositivo
seedn <= to_integer(unsigned(seed_sw));

Rnd_valn: process(CLK,end1,end2,end3)
		variable rand_temp : std_logic_vector(9 downto 0):=(9 => '1',others => '0');
		variable temp : std_logic := '0';
		variable rand_int: integer;
	begin
		if rising_edge(CLK) then
		--for random no generation
			temp := rand_temp(9) xor rand_temp(8);
			rand_temp(9 downto 1) := rand_temp(8 downto 0);
			rand_temp(0) := temp;
			rand_int := to_integer(unsigned(rand_temp));
			
			if end1 then
			     p1 <= rand_int mod 606;
			elsif end2 then
			     p2 <= (p1 + count_clk) mod 606;
			elsif end3 then
			     p3 <= (p2 - count_clk) mod 606;
		    end if;
		end if;
		
	end process;

-- generador de reloj de 50 MHZ
    clk_div1: process (CLK)
    begin  
        if (CLK'event and CLK = '1') then
            clk_interno <= NOT clk_interno;
        end if;
    end process;

--Proceso para generar señal de reloj de n-HZ
	CLK_DIV: process(clk_interno)
	begin
		if(clk_interno'event and clk_interno='1') then
			if (count_clk = (6000000-1)) then
				count_clk <= 0;
				CLK_nHz <= not CLK_nHz;
			else
				count_clk <= count_clk +1;
			end if;
		end if;
	end process;
	
--Proceso para generar señal de reloj de los balones
	CLK_DIV2: process(clk_interno)
	begin
		if(clk_interno'event and clk_interno='1') then
			if (count_clk_fall = (5000000-1)) then
				count_clk_fall <= 0;
				CLK_fall <= not CLK_fall;
			else
				count_clk_fall <= count_clk_fall + 1;
			end if;
		end if;
	end process;

--Proceso para generar señal de reloj de 1-HZ
	CLK_DIV3: process(CLK)
	begin
		if(clk_interno'event and clk_interno='1') then
			if (count_clk1 = (10000000-1)) then
				count_clk1 <= 0;
				clk_1hz <= not clk_1hz;
			else
				count_clk1 <= count_clk1 + 1;
			end if;
		end if;
	end process;
	
--Contador para el botón que mueve la canasta
	CONT: process(CLK_nHz)
	begin
		if (CLK_nHz'event and CLK_nHz='1') then
			if(PB(1)='1') then
				if (conteo <= 605) then
					conteo <= conteo + 32;
				else    
					conteo <= conteo;
			    end if;
			    
		    elsif(PB(0)='1') then
		    
		        if (conteo <= 0) then
					conteo <= conteo;
				else    
					conteo <= conteo - 32;
			    end if;
			    			
			else
				conteo <= conteo;
			end if;
		end if;
	end process;
	
--Contador para mover el balon 1
	CONT2: process(CLK_fall)
	begin
		if (CLK_fall'event and CLK_fall='1') then
			if(fall_1 < 440) then
				fall_1 <= fall_1 + v_fall*10;
				end1 <= false;
				
		    elsif(fall_1 + 12 > 440 and (p1 >= conteo - 16 and p1 < conteo + 16) ) then
				points <= points + 1;
				fall_1 <= 100;
				end1 <= true;	
							 
            else    
                fall_1 <= 100;
                end1 <= true;
            end if;
		end if;
		
		p_vector <= std_logic_vector(RESIZE(to_unsigned(points, 10), 10));
		
	end process;

--Contador para mover el balon 2
	CONT3: process(CLK_fall)
	begin
		if (CLK_fall'event and CLK_fall='1') then
			if(fall_2 < 440) then
				fall_2 <= fall_2 + v_fall*24;
				end2 <= false;
							 
            else    
                fall_2 <= 100;
                end2 <= true;
            end if;
		end if;
		
	end process;
	
--Contador para mover el balon 3
	CONT4: process(CLK_fall)
	begin
		if (CLK_fall'event and CLK_fall='1') then
			if(fall_3 < 440) then
				fall_3 <= fall_3 + v_fall*32;
				end3 <= false; 
            else    
                fall_3 <= 100;
                end3 <= true;
            end if;
		end if;
		
	end process;
	
--Contador para actualizar el tiempo
	CONT5: process(clk_1hz)
	begin
		if (clk_1hz'event and clk_1hz='1') then
			if(t_counter > 0) then
				t_counter <= t_counter - 1 ;
            else    
                t_counter <= t_counter;
                end_t <= true;
            end if;
		end if;
		
		t_vector <= std_logic_vector(RESIZE(to_unsigned(t_counter, 10), 10));
	end process;	
    
--Instancia controlador VGA    
ctrlVga: vga_ctrl_640x480_60Hz
    port map(
       rst => rst,
       clk => clk_interno,
       rgb_in => rgb_aux,
       HS => HS,
       VS => VS,
       hcount => hcount,
       vcount => vcount,
       rgb_out => RGB, --R3R2R1R0GR3GR3GR3GR3B3B2B1B0
       blank => Open);

--Instancia para dibujar la canasta
drawIng: image
  Port map(     
    pix_x => hcount,
    pix_y => vcount,
    paint => paintIng,
    POSX => conteo,
    POSY => 440);
    
--Instancia para dibujar el balon 1
Ball1: image2
  Port map(     
    pix_x => hcount,
    pix_y => vcount,
    paint => paint_b1,
    POSX => p1,
    POSY => fall_1);

--Instancia para dibujar el balon 2
Ball2: image2
  Port map(     
    pix_x => hcount,
    pix_y => vcount,
    paint => paint_b2,
    POSX => p2,
    POSY => fall_2);    
    
--Instancia para dibujar el balon 3
Ball3: image2
  Port map(     
    pix_x => hcount,
    pix_y => vcount,
    paint => paint_b3,
    POSX => p3,
    POSY => fall_3);

-- Instancia de componente encargado de convertir el valor de conteo a BCD 	
	BIN2BCD1: BIN2BCD_0a999 PORT MAP(
		BIN => t_vector,
		BCD2 => centenas_t,
		BCD1 => decenas_t,
		BCD0 => unidades_t
	);
	
-- Instancia de componente encargado de convertir el valor de conteo a BCD 	
	BIN2BCD2: BIN2BCD_0a999 PORT MAP(
		BIN => p_vector,
		BCD2 => centenas_p,
		BCD1 => decenas_p,
		BCD0 => unidades_p
	);

-- Instancia de display de 7 segmento para visualizar el valor de las unidades	
	Display0: Display 
	GENERIC MAP (
		LW => 2,
		DW => 12,
		DL => 20,
		POSX => 100,
		POSY => 0)
	PORT MAP(
		HCOUNT => hcount,
		VCOUNT => vcount,
		VALUE => centenas_t,
		PAINT => paint_num(0)
	);

-- Instancia de display de 7 segmento para visualizar el valor de las decenas	
	Display1: Display 
	GENERIC MAP (
		LW => 2,
		DW => 12,
		DL => 20,
		POSX => 125,
		POSY => 0)
	PORT MAP(
		HCOUNT => hcount,
		VCOUNT => vcount,
		VALUE => decenas_t,
		PAINT => paint_num(1)
	);
	
-- Instancia de display de 7 segmento para visualizar el valor de las centenas	
	Display2: Display 
	GENERIC MAP (
		LW => 2,
		DW => 12,
		DL => 20,
		POSX => 150,
		POSY => 0)
	PORT MAP(
		HCOUNT => hcount,
		VCOUNT => vcount,
		VALUE => unidades_t,
		PAINT => paint_num(2)
	);
	
-- Instancia de display de 7 segmento para visualizar el valor de las unidades	
	Display3: Display 
	GENERIC MAP (
		LW => 2,
		DW => 12,
		DL => 20,
		POSX => 400,
		POSY => 0)
	PORT MAP(
		HCOUNT => hcount,
		VCOUNT => vcount,
		VALUE => centenas_p,
		PAINT => paint_pts(0)
	);

-- Instancia de display de 7 segmento para visualizar el valor de las decenas	
	Display4: Display 
	GENERIC MAP (
		LW => 2,
		DW => 12,
		DL => 20,
		POSX => 425,
		POSY => 0)
	PORT MAP(
		HCOUNT => hcount,
		VCOUNT => vcount,
		VALUE => decenas_p,
		PAINT => paint_pts(1)
	);
	
-- Instancia de display de 7 segmento para visualizar el valor de las centenas	
	Display5: Display 
	GENERIC MAP (
		LW => 2,
		DW => 12,
		DL => 20,
		POSX => 450,
		POSY => 0)
	PORT MAP(
		HCOUNT => hcount,
		VCOUNT => vcount,
		VALUE => unidades_p,
		PAINT => paint_pts(2)
	);

-- Instancia de display de 34 segmento para visualizar una letra del abecedario "C"	
	display34_0: display34segm
    generic map (   SG_WD => 10, --Segment width
                    DL => 100)  --DYSPLAY_LENGTH  
    port map(   posx => 500, 
                posy => 10,
                segments => "1111100000111110000011111000001111",
                hcount => hcount,
                vcount => vcount,
                paint => paint34seg);
	
--Multiplexor para seleccionar color RGB
rgb_aux <= X"FF0" when paint_b1='1' else -- Senal de activación balon 1
           X"FF0" when paint_b2='1' else -- Senal de activación balon 2
           X"FF0" when paint_b3='1' else -- Senal de activación balon 3
           X"8F0" when paintIng = '1' else -- Señal de activación canasta
           X"6F4" when paint_num(0) = '1' else -- Señal de activación unidades
           X"6F4" when paint_num(1) = '1' else -- Señal de activación decenas
           X"6F4" when paint_num(2) = '1' else -- Señal de activación centenas
           X"6F4" when paint_pts(0) = '1' else -- Señal de activación unidades
           X"6F4" when paint_pts(1) = '1' else -- Señal de activación decenas
           X"6F4" when paint_pts(2) = '1' else -- Señal de activación centenas
           X"000";
           
end Behavioral;
