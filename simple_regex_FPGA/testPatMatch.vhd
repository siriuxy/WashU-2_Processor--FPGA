--------------------------------------------------------------------------------
-- Test Pattern Matchner
-- Jon Turner, 12/2013

--------------------------------------------------------------------------------
LIBRARY ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.commonDefs.all;
 
ENTITY testPatMatch IS
END testPatMatch;
 
ARCHITECTURE a1 OF testPatMatch IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT patternMatcher
    PORT(
         clk : IN  std_logic;
         restart : IN  std_logic;
         valid : IN  std_logic;
         inSym : IN  std_logic_vector(3 downto 0);
         repCount : IN  std_logic_vector(3 downto 0);
         patCount : OUT  std_logic_vector(7 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal restart : std_logic := '0';
   signal valid : std_logic := '0';
   signal inSym : std_logic_vector(3 downto 0) := (others => '0');
   signal repCount : std_logic_vector(3 downto 0) := (others => '0');

 	--Outputs
   signal patCount : std_logic_vector(7 downto 0);

   -- Clock period definitions
   constant clk_period : time := 20 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: patternMatcher PORT MAP (clk, restart, valid, inSym, repCount, patCount);

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0'; wait for clk_period/2;
		clk <= '1'; wait for clk_period/2;
   end process;

   -- Stimulus process
   stim_proc: process
		procedure restart(count: in std_logic_vector(3 downto 0)) is begin
		-- Start a round of tests using a specified repeat count
			repCount <= count; restart <= '1'; wait for 20 ns; restart <= '0'; wait for 20 ns;
		end;
		
		procedure nextSym(sym: in std_logic_vector(3 downto 0)) is begin
		-- Input one symbol to the circuit, where x"0" corresponds to 'a', x"1 to b and so forth
			inSym <= sym; valid <= '1'; wait for 20 ns; valid <= '0'; wait for 20 ns;
		end;
		
		procedure nextSymVec(ss: in std_logic_vector(0 to 39)) is begin
		-- Input a string of up to 9 hex digits. The input vector holds exactly 10 
		-- and  f is interpreted as a termination character. So for example, use
		-- nextSymVec(x"0132ffffff") to input the symbols x0, 1, 3 and 2.
			for i in 0 to 10 loop
				if ss(4*i to 4*i+3) = x"f" then exit; end if;
				nextSym(ss(4*i to 4*i+3));
			end loop;
		end;
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

		-- start with a set of tests using a repeat count of 3      
		-- first test all the cases where the input matches the pattern
		-- be sure to to use all the state-machine transitions that lead to successful matches
		restart(x"3");
		nextSymVec(x"12ffffffff");
		nextSymVec(x"01113fffff");
		nextSymVec(x"011135ffff");
		nextSymVec(x"0023ffffff");
		nextSymVec(x"0023213fff");
		
		-- next add cases that fail after matching one or more initial 'a' characters
		nextSymVec(x"03ffffffff");
		nextSymVec(x"07ffffffff");
		
		-- now cases that fail after matching ab
		nextSymVec(x"01110fffff"); 
		nextSymVec(x"01111fffff");
		nextSymVec(x"01115fffff");
		nextSymVec(x"0113ffffff");
		nextSymVec(x"0110ffffff");
		
		-- and finally, cases that fail after matching ac
		nextSymVec(x"020fffffff");
		nextSymVec(x"021fffffff");
		nextSymVec(x"02bfffffff");

		-- now, a few more tests using a repeat count of 1
		restart(x"1");
		nextSymVec(x"013fffffff");
		nextSymVec(x"003fffffff");
		nextSymVec(x"0113ffffff");
		nextSymVec(x"023fffffff");
		nextSymVec(x"231fffffff");

      assert (false) report "normal termination" severity failure;
   end process;

end a1;
