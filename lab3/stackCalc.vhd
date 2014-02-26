------------------------------------------------------------------------------
-- Stack Calculator
-- Your name, date
--
-- Document the module here
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.commonDefs.all;

entity stackCalc is 
	generic(
		stakSiz: integer :=  8;
		lgSiz:   integer :=  3;
		wordSiz: integer := 16);
	port(
		clk, reset: in std_logic;	
		op: in nibble;
		doOp: in std_logic;
		dIn: in std_logic_vector(wordSiz-1 downto 0);
		result: out std_logic_vector(wordSiz-1 downto 0));
end stackCalc;

architecture a1 of stackCalc is
	-- TODO
end a1;
