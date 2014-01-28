------------------------------------------------------------------------------
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
--
-- Modified the_date, your name
--
-- Document your changes here
--
------------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.commonDefs.all;

entity calculator is port (
	clk: in std_logic;
	clear, load, add, mode: in std_logic;	-- signals to enable operations
	dIn: in word;		   	-- input data
	result: out word;
	error: out std_logic);		-- output result
end calculator;

architecture a1 of calculator is
signal dReg: word;
signal dRegResult: word:=(wordsize-1 downto 0 => '0'); --gives an initial value to avoid error at the beginning;
signal errormsg: std_logic;
begin
dRegResult<=dReg+dIn;
	process (clk) begin
		if rising_edge(clk) then
		--sequential process block
			if clear = '1' then
				dReg <= (wordsize-1 downto 0 => '0');
				errormsg<='0'; --added to clear error value
			elsif load = '1' then
				dReg <= dIn;
			elsif add = '1' then
				dReg <= dReg + dIn;
				if mode = '0' then
					if (dRegResult< dReg) or (dRegResult< dIn) then 
						errormsg<='1';
					end if;
				elsif mode = '1' then
					if (dRegResult(wordsize-1) /= dReg(wordsize-1)) or (dRegResult(wordsize-1) /= dIn(wordsize-1)) then 
						errormsg<='1';
					end if;
				end if;
			end if;
		end if;
	end process;
					result <= dReg;
					error <= errormsg;
end a1;

