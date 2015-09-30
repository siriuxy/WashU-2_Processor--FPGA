library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.commonDefs.all;

entity outMod is port(
	clk, reset: in std_logic;
	inSym: in nibble;					-- input symbol to matcher
	valid: in std_logic;				-- valid symbol signal
	patCount: in byte;				-- number of matches since restart
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

type hex2asciiMap is array(0 to 15) of byte; 
signal hex2ascii: hex2asciiMap :=
	( 0 => x"30",  1 => x"31",  2 => x"32",  3 => x"33",  4 => x"34", 
	  5 => x"35",  6 => x"36",  7 => x"37",  8 => x"38",  9 => x"39",
	 10 => x"61", 11 => x"62", 12 => x"63", 13 => x"64", 14 => x"65", 15 => x"66");

type rowType is array(0 to 15) of byte;
signal top, bot: rowType;
																										
begin
	-- store input data in pair of chaacter arrays to be sent to display
	process(clk) begin
		if rising_edge(clk) then
			if reset = '1' then
				top <= (others => x"20"); bot <= (others => x"20");
			else
				top(15) <= x"61" + (x"0" & inSym);
				if valid = '1' then
					top(13) <= top(15);
					top(0 to 12) <= top(1 to 13);			
				end if;
				bot(14) <= hex2ascii(int(patCount(7 downto 4)));
				bot(15) <= hex2ascii(int(patCount(3 downto 0)));
			end if;
		end if;
	end process;
	
	disp:	lcdDisplay port map(clk, reset, update, selekt, nuchar, lcd);
	
	-- counter process
	process(clk) begin
		if rising_edge(clk) then
			counter <= counter + 1;
			if reset = '1' then
				counter <= (others => '0');
			end if;
		end if;
	end process;
	
	lowBits <= counter(CNTR_LENGTH-6 downto 0);
	update <= '1' when lowBits = (lowBits'range => '0') else '0';
	selekt <= counter(CNTR_LENGTH-1 downto CNTR_LENGTH-5);
	nuChar <= top(int(selekt(3 downto 0))) when selekt(4) = '0' else
				 bot(int(selekt(3 downto 0)));
end a1;
