----------------------------------------------------------------------------------
-- Simple binary output module
-- Jon Turner - 10/2011
--
-- The two data inputs topRow and botRow are displayed on the S3 board's LCD
-- display in binary, with the high order bit at the left.
----------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.commonDefs.all;

entity binaryOutMod is port(
	clk, reset: in std_logic;
	topRow, botRow: in word;
	-- signals for controlling LCD display 
	lcd: out lcdSigs);
end entity binaryOutMod;

architecture a1 of binaryOutMod is

component lcdDisplay port(
	clk, reset : in std_logic;
	-- internal interface for controlling display
	update: in std_logic;								-- update a stored value
	selekt: in std_logic_vector(4 downto 0);		-- character to replace
	nuChar: in std_logic_vector(7 downto 0);		-- new character value
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
																										
begin
	disp:	lcdDisplay port map(clk, reset, update, selekt, nuchar, lcd);
	
	lowBits <= counter(CNTR_LENGTH-6 downto 0);
	update <= '1' when lowBits = (lowBits'range => '0') else '0';
	selekt <= counter(CNTR_LENGTH-1 downto CNTR_LENGTH-5);
	
	nuchar <= x"30" when (selekt(4) = '0' and 
							    topRow((wordSize-1)-int(selekt(3 downto 0))) = '0') or
							   (selekt(4) = '1' and 
							    botRow((wordSize-1)-int(selekt(3 downto 0))) = '0') else
				 x"31";

	process(clk) begin
		if rising_edge(clk) then
			counter <= counter + 1;
			if reset = '1' then
				counter <= (others => '0');
			end if;
		end if;
	end process;
end a1;

