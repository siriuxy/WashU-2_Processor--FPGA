--------------------------------------------------------------------------------
-- testbench for mineSweeper
-- Jon Turner - 3/2012
--------------------------------------------------------------------------------
LIBRARY ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.commonDefs.all;
 
ENTITY testMineSweeper IS
END testMineSweeper;
 
ARCHITECTURE behavior OF testMineSweeper IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT mineSweeper
    PORT(
         clk : IN  std_logic;
         reset : IN  std_logic;
         xIn : IN  nibble;
         yIn : IN  nibble;
         newGame : IN  std_logic;
         markIt : IN  std_logic;
         stepOnIt : IN  std_logic;
         level : IN  std_logic_vector(2 downto 0);
         hSync : OUT  std_logic;
         vSync : OUT  std_logic;
         dispVal : OUT  pixel
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal reset : std_logic := '0';
   signal x : nibble := (others => '0');
   signal y : nibble := (others => '0');
   signal newGame : std_logic := '0';
   signal markIt : std_logic := '0';
   signal stepOnIt : std_logic := '0';
   signal level : std_logic_vector(2 downto 0) := (others => '0');

 	--Outputs
   signal hSync : std_logic;
   signal vSync : std_logic;
   signal dispVal : pixel;

   -- Clock period definitions
   constant clk_period : time := 20 ns;
	constant pause : time := 100 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: mineSweeper PORT MAP (
          clk => clk, reset => reset, xIn => x, yIn => y,
          newGame => newGame, markIt => markIt,
          stepOnIt => stepOnIt, level => level,
          hSync => hSync, vSync => vSync, dispVal => dispVal
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0'; wait for clk_period/2;
		clk <= '1'; wait for clk_period/2;
   end process;

   process
	-- push the reset button
	procedure resetIt is begin
		reset <= '1'; wait for clk_period; reset <= '0'; wait for pause;
	end;
	
	-- start a new game
	procedure nuGame is begin
		newGame <= '1'; wait for clk_period; newGame <= '0'; wait for pause;
	end;
	
	-- mark a square
	procedure markSquare is begin
		markIt <= '1'; wait for clk_period; markIt <= '0'; wait for pause;
	end;
	
	-- step on a square
	procedure stepOnSquare is begin
		stepOnIt <= '1'; wait for clk_period; stepOnIt <= '0'; wait for pause;
	end;

   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      level <= "001";		
		resetIt; wait for 45 us;
		x <= x"4"; y <= x"1"; markSquare; wait for 50 us;
		x <= x"1"; y <= x"3"; stepOnSquare; wait for 50 us;
		x <= x"2"; y <= x"9"; stepOnSquare; wait for 100 us;
		
		level <= "011";		
		nuGame; wait for 30 us;
		x <= x"1"; y <= x"1"; stepOnSquare;
		wait for 10 us;
		x <= x"2"; y <= x"8"; stepOnSquare;
		wait for 10 us;
		x <= x"2"; y <= x"2"; stepOnSquare;
		
		wait for 20 ms;
		level <= o"1"; nuGame; wait for 50 us;
		level <= o"2"; nuGame; wait for 50 us;
		level <= o"3"; nuGame; wait for 50 us;
		level <= o"4"; nuGame; wait for 50 us;
		level <= o"5"; nuGame; wait for 50 us;
		level <= o"6"; nuGame; wait for 50 us;
		level <= o"7"; nuGame; wait for 50 us;
		assert (false) report "simulation ended normally" severity failure;
   end process;

END;
