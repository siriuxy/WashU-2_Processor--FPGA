----------------------------------------------------------------------------
-- Pattern Matcher
-- 
-- Document the module here. Points will be deducted for missing
-- or inadequate documentation
----------------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.commonDefs.all;

entity patternMatcher is port(
	clk, restart, valid: in std_logic;
	inSym: in nibble;
	repCount: in nibble;
	patCount: out byte);
end patternMatcher;

architecture a1 of patternMatcher is

-- TODO - your code here

end a1;
