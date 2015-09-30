--------------------------------------------------------------------------------
-- testbench for mineSweeper
-- Jon Turner - 3/2012
--------------------------------------------------------------------------------
LIBRARY ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.commonDefs.all;
 
entity testFifteen is end;
 
architecture arch of testFifteen is 
 
component fifteenPuzzle port(
	clk, reset: in std_logic;
	-- client-side interface
	nuPuzzle: in std_logic;
	moveDir: in std_logic_vector(1 downto 0);
	moveNow: in std_logic;
	puzlTime, bestTime: out bcdVec(5 downto 0);
	-- auxiliary signals for testing
	peekPos: in nibble; -- specifies a board position
	peekVal: out nibble; -- tile at position peekPos
	emptyPos: out nibble; -- position of empty square
	-- interface to external display
	hSync, vSync: out std_logic;
	dispVal: out pixel);
end component;
    
--Inputs
signal clk : std_logic := '0';
signal reset : std_logic := '0';
signal nuPuz : std_logic := '0';
signal moveIt : std_logic := '0';
signal moveDir : std_logic_vector(1 downto 0) := (others => '0');
signal peekPos: nibble := x"0";

--Outputs
signal puzlTime, bestTime: bcdVec(5 downto 0);
signal hSync : std_logic;
signal vSync : std_logic;
signal dispVal : pixel;
signal peekVal, emptyPos : nibble;

-- Clock period definitions
constant clk_period : time := 20 ns;
constant pause : time := 100 ns;

begin
 
	-- Instantiate the Unit Under Test (UUT)
   uut: fifteenPuzzle port map(clk,reset,nuPuz,moveDir,moveIt,
										puzlTime,bestTime,peekPos,peekVal,emptyPos,
										hSync,vSync,dispVal);

	process begin
		clk <= '0'; wait for clk_period/2;
		clk <= '1'; wait for clk_period/2;
   end process;

   process
	-- push the reset button
	procedure resetIt is begin
		reset <= '1'; wait for clk_period; reset <= '0'; wait for pause;
	end;
	
	-- start a new puzzle
	procedure nuPuzzle is begin
		nuPuz <= '1'; wait for clk_period; nuPuz <= '0'; wait for pause;
	end;

	procedure checkIt is begin
		peekPos <= emptyPos; wait for 1 ps; 
		assert peekVal = x"0" report "empty square not consistent";
	end;
	
	-- move now
	procedure move(dir: integer) is begin
		moveDir <= slv(dir,2);
		moveIt <= '1'; wait for clk_period; moveIt <= '0'; 
		checkIt; wait for 1 ms;
	end;

   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	
		
		resetIt; wait for 10 us;
		
		move(2); move(1); move(2); move(3); move(0);
		move(3); move(0); move(0); move(3);

		nuPuzzle; wait for 10 us;
		-- move empty square to top left, then top right
		move(0); move(0); move(0); move(0);
		move(3); move(3); move(3); move(3);
		move(1); move(1); move(1); move(1);
		move(2); move(2); move(2); move(2);
	
		assert (false) report "simulation ended normally" severity failure;
   end process;

end;
