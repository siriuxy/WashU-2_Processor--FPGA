library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

package commonDefs is
   constant wordSize: integer := 16;
	constant lgWordSize: integer := 4;
	 	     
	constant nBtn: integer := 4; -- number of buttons
	constant nKsigs: integer := 3; -- number of knob signals
	constant nSwt: integer := 4; -- number of switches
	constant nLED: integer := 8; -- number of LEDs
	 
	constant operationMode: integer := 0; -- use 0 for simulation, 1 for S3 board
	constant debounceBits: integer := 2 + operationMode*14;

	-- subtypes used by vgaDisplay module
	subtype pixel is unsigned(2 downto 0);
	subtype dbAdr is unsigned(16 downto 0);
	 
	subtype nibble is std_logic_vector(3 downto 0);
	subtype byte is std_logic_vector(7 downto 0);
	subtype word is std_logic_vector(wordSize-1 downto 0);
	subtype address is std_logic_vector(wordSize-1 downto 0);
	subtype buttons is std_logic_vector(nBtn-1 downto 0);
	subtype knobSigs is std_logic_vector(nKsigs-1 downto 0);
	subtype switches is std_logic_vector(nSwt-1 downto 0);
	subtype leds is std_logic_vector(nLED-1 downto 0);
	
	subtype bcdDigit is unsigned(3 downto 0);
	type bcdVec is array(natural range <>) of bcdDigit;
	 
	type lcdSigs is record
		en, rs, rw, sf_CE: std_logic;
		data: std_logic_vector(3 downto 0);
	end record;
    
	-- Convert logic vector to integer. Handy for array indexing.
	function int(d: std_logic_vector) return integer;
	function int(d: unsigned) return integer;
	function int(d: signed) return integer;
	
 	-- Convert integer to logic vector of specified length.
   function slv(d: integer; len: integer) return std_logic_vector;
	
	-- Convert character to byte
	function c2b(c: character) return byte;
	
	-- Pad signal to specified length
	function pad(x: std_logic_vector; len: integer) return std_logic_vector;
	function pad(x: unsigned; len: integer) return unsigned;
		
	-- BCD incrementer
	function plus1(x: bcdVec) return bcdVec; 

	-- Return true if BCD vectors x,y satisfy x<y.
	function lessThan(x, y: bcdVec) return boolean;   
end package commonDefs;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

package body commonDefs is  
   -- Convert logic vector to integer. Handy for array indexing.
	function int(d: std_logic_vector) return integer is
   begin return to_integer(unsigned(d)); end function int;
	
	function int(d: unsigned) return integer is
   begin return to_integer(d); end function int;
	
	function int(d: signed) return integer is
   begin return to_integer(d); end function int;
	
	-- Convert integer to logic vector of specified length.
	function slv(d: integer; len: integer) return std_logic_vector is
   begin return std_logic_vector(to_unsigned(d,len)); end function slv;
	
	-- Convert character to byte
	function c2b(c: character) return byte is
	begin return slv(character'pos(c),8); end function c2b;
	
	-- Pad signal to specified length
	function pad(x: std_logic_vector; len: integer) return std_logic_vector is
	begin return slv(int(x),len); end;
	function pad(x: unsigned; len: integer) return unsigned is
	begin return to_unsigned(int(x),len); end;
	
	-- BCD incrementer
	function plus1(x: bcdVec) return bcdVec is 
	variable z: bcdVec(x'high downto 0);
	begin
		z := x;
		for i in 0 to x'high loop
			if x(i) = x"9" then z(i) := x"0";
			else z(i) := x(i) + 1; exit;
			end if;
		end loop;
		return z;
	end;
	
	-- Return true if BCD vectors x,y satisfy x<y.
	function lessThan(x, y: bcdVec) return boolean is begin
		for i in x'high downto 0 loop
			if x(i) < y(i) then return true; end if;
		end loop;
		return false;
	end;
	
end package body commonDefs;
