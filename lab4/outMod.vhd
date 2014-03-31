-- Output module for use with 15 puzzle game
-- Jon Turner, 2/2010
--
-- This display module uses the LCD display to show the values
-- of outputs puzlTime and bestTime from the fifteenPuzzle module.
--
-- The display will look something like
--
-- puzlTime  123456
-- bestTime  345678
--
-- Note, the labels are required.
--
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.commonDefs.all;

entity outMod is port(
   clk, reset: in std_logic;
   puzlTime, bestTime: in bcdVec(5 downto 0);
   -- signals for controlling LCD display 
   lcd: out lcdSigs);
end entity outMod;

architecture a1 of outMod is

component lcdDisplay port(
   clk, reset : in std_logic;
   -- internal interface for controlling display
   update: in std_logic;                        -- update a stored value
   selekt: in std_logic_vector(4 downto 0);      -- character to replace
   nuChar: in std_logic_vector(7 downto 0);      -- new character value
   -- connections to external pins
   lcd: out lcdSigs);
end component;

-- counter for controlling when to update lcdDisplay
constant CNTR_LENGTH: integer := 20;
signal counter: std_logic_vector(CNTR_LENGTH-1 downto 0);
signal lowBits: std_logic_vector(CNTR_LENGTH-6 downto 0);

-- signals for controlling lcdDisplay
signal update: std_logic;
signal selekt: std_logic_vector(4 downto 0);
signal nuChar: std_logic_vector(7 downto 0);

type hex2asciiMap is array(0 to 15) of character; 
constant hex2ascii: hex2asciiMap :=
   ( 0 => '0',  1 => '1',  2 => '2',  3 => '3',  4 => '4', 
     5 => '5',  6 => '6',  7 => '7',  8 => '8',  9 => '9',
    10 => 'a', 11 => 'b', 12 => 'c', 13 => 'd', 14 => 'e', 15 => 'f');
                                                                              
begin
   disp:   lcdDisplay port map(clk, reset, update, selekt, nuchar, lcd);
   
   lowBits <= counter(CNTR_LENGTH-6 downto 0);
   update <= '1' when lowBits = (lowBits'range => '0') else '0';
   selekt <= counter(CNTR_LENGTH-1 downto CNTR_LENGTH-5);
             
   process(clk) begin
      if rising_edge(clk) then
         counter <= counter + 1;
         if reset = '1' then
            counter <= (others => '0');
         end if;
      end if;
   end process; 
   
   -- Combinational process that controls value of nuChar,
   -- based on selekt, puzlTime, bestTime
   process(selekt, puzlTime, bestTime) begin
      -- TODO
		-- assign the appropriate value to nuChar for the top and bottom row
		if selekt(4) = '0' then	-- top row
			case selekt(3 downto 0) is
				when x"0" =>
					nuchar <= c2b('p');
				when x"1" =>
					nuchar <= c2b('u');
				when x"2" =>
					nuchar <= c2b('z');
				when x"3" =>
					nuchar <= c2b('l');
				when x"4" =>
					nuchar <= c2b('T');
				when x"5" =>
					nuchar <= c2b('i');
				when x"6" =>
					nuchar <= c2b('m');
				when x"7" =>
					nuchar <= c2b('e');
			--added spaces between string and timer
				when x"8"=>
					nuchar <= c2b(' ');
				when x"9"=>
					nuchar <= c2b(' ');
				when x"a" =>
					nuchar <= c2b(hex2ascii(int(puzlTime(5))));
				when x"b" =>
					nuchar <= c2b(hex2ascii(int(puzlTime(4))));
				when x"c" =>
					nuchar <= c2b(hex2ascii(int(puzlTime(3))));
				when x"d" =>
					nuchar <= c2b(hex2ascii(int(puzlTime(2))));
				when x"e" =>
					nuchar <= c2b(hex2ascii(int(puzlTime(1))));
				when x"f" =>
					nuchar <= c2b(hex2ascii(int(puzlTime(0))));
				when others =>
				
			end case;
		else							-- bottom row
			case selekt(3 downto 0) is
				when x"0" =>
					nuchar <= c2b('b');
				when x"1" =>
					nuchar <= c2b('e');
				when x"2" =>
					nuchar <= c2b('s');
				when x"3" =>
					nuchar <= c2b('t');
				when x"4" =>
					nuchar <= c2b('T');
				when x"5" =>
					nuchar <= c2b('i');
				when x"6" =>
					nuchar <= c2b('m');
				when x"7" =>
					nuchar <= c2b('e');
				when x"8"=>
					nuchar <= c2b(' ');
				when x"9"=>
					nuchar <= c2b(' ');
				when x"a" =>
					nuchar <= c2b(hex2ascii(int(bestTime(5))));
				when x"b" =>
					nuchar <= c2b(hex2ascii(int(bestTime(4))));
				when x"c" =>
					nuchar <= c2b(hex2ascii(int(bestTime(3))));
				when x"d" =>
					nuchar <= c2b(hex2ascii(int(bestTime(2))));
				when x"e" =>
					nuchar <= c2b(hex2ascii(int(bestTime(1))));
				when x"f" =>
					nuchar <= c2b(hex2ascii(int(bestTime(0))));
				when others =>
				
			end case;
		end if;
   end process;
end a1;
