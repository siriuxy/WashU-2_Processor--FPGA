----------------------------------------------------------------------------
-- Pattern Matcher
-- 
-- by Likai Yan 02/2014
--
-- This circuit implemented the method to recognize regex pattern a({b}|c)d from input, and 
-- count the number of times this pattern appears. It also have the ability to 
-- restart the circuit such that the num of repeated pattern is cleared.
--
-- In the regex. the num of 
-- repeated 'b' is input via repCount, and the number of repeated pattern is 
-- output by patCoutn.
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
type stateType is (start,blank,Astate,Bstate,Cstate,Dstate);
signal state: stateType;
--signal bp: std_logic;
signal bcnt:std_logic_vector(3 downto 0);
signal pcnt: byte;
signal inc: nibble;
begin
	process(clk)begin
		if rising_edge(clk) then
			if restart='1' then
				state<=start; inc<=repCount; bcnt<=x"0"; pcnt<=x"00";
			else
				case state is
				when start=>
					pcnt<=x"00";
--					bp<=0;
					state<=blank;
				when blank=>
						bcnt<=x"0";
	--					bp<=0;
					if valid='1' then
						if inSym=x"0" then state<=Astate;--double quote for hex. don't consider bcnt, bp as they are 0.
						else state<=blank;
						end if;
					end if;
				when Astate=>
					if valid='1' then
						if inSym=x"0" then state<=Astate;
						elsif inSym=x"1" then state<=Bstate; bcnt<=bcnt+1;
						--end if; -- I think use elsif is better
						elsif inSym=x"2" then state<=Cstate;
						else state<=blank;
						end if;
					end if;
				when Bstate=>
					if valid='1' then
						if inSym=x"1" then bcnt<=bcnt+1; --implies retaining its stage
						elsif (inSym=x"3" and bcnt=inc) then state<=Dstate;
						else state<=blank;
						end if;
					end if;
				when Cstate=>
					if valid='1' then
						if inSym=x"3" then state<=Dstate;
						else state<=blank;
						end if;
					end if;
				when Dstate=>
					pcnt<=pcnt+1;
					state<=blank;
				when others=>
				end case;
			end if;	
		end if;
	end process;
		patCount<=pcnt;					


end a1;
