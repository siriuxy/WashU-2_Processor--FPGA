library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

package commonDefs is
   constant wordSize: integer := 16;
	 	     
	constant nBtn: integer := 4; -- number of buttons
	constant nKsigs: integer := 3; -- number of knob signals
	constant nSwt: integer := 4; -- number of switches
	constant nLED: integer := 8; -- number of LEDs
	 
	constant operationMode: integer := 0; -- 0 for sim, 1 for proto board
	constant debounceBits: integer := 2 + operationMode*14; 
	 
	subtype word is std_logic_vector(wordSize-1 downto 0);
	subtype buttons is std_logic_vector(nBtn-1 downto 0);
	subtype knobSigs is std_logic_vector(nKsigs-1 downto 0);
	subtype switches is std_logic_vector(nSwt-1 downto 0);
	subtype leds is std_logic_vector(nLED-1 downto 0);
	 
	type lcdSigs is record
		en, rs, rw, sf_CE: std_logic;
		data: std_logic_vector(3 downto 0);
	end record;
    
   function int(d: std_logic_vector) return integer;
   -- Convert logic vector to integer. Handy for array indexing.
    
end package commonDefs;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

package body commonDefs is
   function int(d: std_logic_vector) return integer is
   -- Convert logic vector to integer. Handy for array indexing. 
   begin return conv_integer(unsigned(d)); end function int;
end package body commonDefs;
