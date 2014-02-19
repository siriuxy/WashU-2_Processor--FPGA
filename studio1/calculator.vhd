----------------------------------------------------------------------------------
-- Simple Binary Calculator
-- Jon Turner, 12/2007
-- modified 5/2010 for newer prototype boards
--
-- This circuit implements a simple binary calculator with three
-- operations
--
--		clear stored value
--		enter new value
--		add to stored value
--
--	The input data and the result are both 16 bit values.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.commonDefs.all;

entity calculator is port (
	clk: in std_logic;
	clear, load, add: in std_logic;	-- signals to enable operations
	dIn: in word;		   				-- input data
	result: out word);					-- output result
end calculator;

architecture a1 of calculator is
signal dReg: word;
begin
	process (clk) begin
		if rising_edge(clk) then
			if clear = '1' then
				dReg <= (wordsize-1 downto 0 => '0');
			elsif load = '1' then
				dReg <= dIn;
			elsif add = '1' then
				dReg <= dReg + dIn ;
			end if;
		end if;
	end process;
	result <= dReg;
end a1;

