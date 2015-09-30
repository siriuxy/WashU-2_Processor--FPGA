--------------------------------------------------------------------------
-- Stack circuit
-- Your name, date
--
-- Your documentation here
--------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.commonDefs.all;

entity stack is 
	generic(
		stakSiz: integer :=  8;
		lgSiz:   integer :=  3;
		wordSiz: integer := 16);
	port(
		clk, reset: in std_logic;	
		push, pop: in std_logic;
		dIn: in  std_logic_vector(wordSiz-1 downto 0);
		top: out std_logic_vector(wordSiz-1 downto 0);
		empty, full: out std_logic);
end stack;

architecture a1 of stack is
	-- TODO
end a1;
