library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.commonDefs.all;

entity outMod is 
	generic(wordSiz: integer :=  16);
	port(
		clk, reset: in std_logic;
		inBits, outBits: in std_logic_vector(wordSiz-1 downto 0);
		op: in nibble;
		-- signals for controlling LCD display 
		lcd: out lcdSigs);
end entity outMod;

architecture a1 of outMod is

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

type hex2asciiMap is array(0 to 15) of character; 
constant hex2ascii: hex2asciiMap :=
	( 0 => '0',  1 => '1',  2 => '2',  3 => '3',  4 => '4', 
	  5 => '5',  6 => '6',  7 => '7',  8 => '8',  9 => '9',
	 10 => 'a', 11 => 'b', 12 => 'c', 13 => 'd', 14 => 'e', 15 => 'f');
	 
type opName is array(0 to 15) of byte;
type opNameList is array(0 to 7) of string(1 to 16);
signal operations: opNameList := (
	0 => "clear top       ",
	1 => "clear stack     ",
	2 => "pop             ",
	3 => "push            ",
	4 => "add to top      ",
	5 => "add top two     ",
	6 => "sub from top    ",
	7 => "sub top two     ");

																										
begin
	disp:	lcdDisplay port map(clk, reset, update, selekt, nuchar, lcd);
	
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
	
	process(selekt, inbits, outbits, op) begin
		if selekt(4) = '0' then
			case selekt(3 downto 0) is
			when x"0" => nuChar <= c2b('i');
			when x"1" => nuChar <= c2b('n');
			when x"3" => nuChar <= c2b(hex2ascii(int(inBits(15 downto 12))));
			when x"4" => nuChar <= c2b(hex2ascii(int(inBits(11 downto  8))));
			when x"5" => nuChar <= c2b(hex2ascii(int(inBits( 7 downto  4))));
			when x"6" => nuChar <= c2b(hex2ascii(int(inBits( 3 downto  0))));
			when x"8" => nuChar <= c2b('o');
			when x"9" => nuChar <= c2b('u');
			when x"a" => nuChar <= c2b('t');
			when x"c" => nuChar <= c2b(hex2ascii(int(outBits(15 downto 12))));
			when x"d" => nuChar <= c2b(hex2ascii(int(outBits(11 downto  8))));
			when x"e" => nuChar <= c2b(hex2ascii(int(outBits( 7 downto  4))));
			when x"f" => nuChar <= c2b(hex2ascii(int(outBits( 3 downto  0))));
			when others => nuChar <= c2b(' ');
			end case;
		else
			nuChar <= c2b(operations(int(op))(int(selekt(3 downto 0))+1));
		end if;
	end process;
end a1;