------------------------------------------------------------------------------
-- Mine Sweeper game
-- Jon Turner - 3/2012
--
-- This circuit implements the well-known Mine Sweeper game on the prototype board.
-- It uses a 10x14 game board.
-- 
-- inputs
--		x			specifies the x position of the "current square" on the
--					game board
--		y			specifies the y position of the "current square"
--		newGame	when high, starts a new game
--		markIt	when high, if the current square is covered, this either 
--					marks it or unmarks it (to indicate presence of a mine)
--		stepOnIt	when high, causes the player to "step" on the current square;
--					if the square contains a mine, this terminates the game and
--					causes all covered squares to be uncovered; if the current
--					square does not contain a mine, it is just uncovered
--		level		controls the level of difficulty of the game; higher numbers
--					lead to larger numbers of mines
--
--	outputs
--		hSync		the horizontal sync signal for the external vga display
--		vSync		the vertical sync signal for the external vga display
--		dispVal	the 3 bit display value for the current pixel on the vga display
--
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.commonDefs.all;

entity mineSweeper is port (
	clk, reset: in std_logic;
	-- client-side interface
	xIn, yIn: in nibble;
	newGame, markIt, stepOnIt: in std_logic;
	level: in std_logic_vector(2 downto 0);
	-- interface to external display
	hSync, vSync: out std_logic;
	dispVal: out pixel);
end mineSweeper;

architecture a1 of mineSweeper is

component copyPattern port( 
	clk, reset : in  std_logic;
	-- client-side interface
	start, highlight: in std_logic;
	pattern: in nibble;
	x, y: in nibble;
	busy: out std_logic;
	-- interface to external display
	hSync, vSync: out std_logic;
	dispVal: out pixel);
end component;

-- state of game controller
type stateType is (clearCounts, setMines, countMines, playTime, gameOver);
signal state: stateType;

-- x-y coordinates pairs
signal x, y, x1, y1, x2, y2: nibble;

-- arrays of bits that define state of squares on game board
-- range extends beyond gameboard to eliminate boundary cases
type boardBits is array(0 to 15) of std_logic_vector(0 to 11);
signal   isMined: boardBits := (others => (0 to 11 => '0'));
signal isCovered: boardBits := (others => (0 to 11 => '1'));
signal isFlagged: boardBits := (others => (0 to 11 => '0'));

-- mineCount(x)(y)=# of mines in squares y-2 to y in column x
type countColumn is array(0 to 11) of unsigned(2 downto 0);
type countArray is array(0 to 15) of countColumn;
signal mineCount: countArray := (others => (0 to 11 => o"0"));

-- convenience functions/procedures for accessing arrays
impure function mined(x,y: nibble) return boolean is begin
	assert x"0" < x and x < x"f" and x"0" < y and y < x"b" 
			report "x,y range violation";
	if isMined(int(x))(int(y)) = '1' then return true;
	else return false;
	end if;
end;
impure function covered(x,y: nibble) return boolean is begin
	assert x"0" < x and x < x"f" and x"0" < y and y < x"b" 
			report "x,y range violation";
	if isCovered(int(x))(int(y)) = '1' then return true;
	else return false;
	end if;
end;
impure function flagged(x,y: nibble) return boolean is begin
	assert x"0" < x and x < x"f" and x"0" < y and y < x"b" 
			report "x,y range violation";
	if isFlagged(int(x))(int(y)) = '1' then return true;
	else return false;
	end if;
end;

-- Return the number of mines contained in neighboring squares
impure function numMines(x,y: nibble) return unsigned is begin
	assert x"0" < x and x < x"f" and x"0" < y and y < x"b" 
			report "x,y range violation";
	return mineCount(int(x))(int(y));
end;

-- Return the appropriate pattern number for square x,y
impure function pattern(x,y: nibble) return nibble is begin
	assert x"0" < x and x < x"f" and x"0" < y and y < x"b" 
			report "x,y range violation";
	if (not covered(x,y)) and (not mined(x,y)) then
		return "0" & std_logic_vector(numMines(x,y));
	elsif covered(x,y) and (not flagged(x,y)) then
		return x"9";
	elsif covered(x,y) and flagged(x,y) then
		return x"a";
	elsif (not covered(x,y)) and mined(x,y) then
		return x"b";
	else
		return x"0";
	end if;
end;

-- auxiliary signals
signal timer: std_logic_vector(10+operationMode*7 downto 0);
signal startCopy, busy, highlight: std_logic;
signal randBits: word;
signal nbor, pat: nibble;

-- Return an x-coordinate that is in the range of values defined by board
function safeX(x: nibble) return nibble is begin
	   if x < x"1" then return x"1";
	elsif x > x"e" then return x"e";
	else return x;
	end if;
end;
-- Return a y-coordinate that is in the range of values defined by board
function safeY(y: nibble) return nibble is begin
	   if y < x"1" then return x"1";
	elsif y > x"a" then return x"a";
	else return y;
	end if;
end;

-- Return true if x,y is the last square on the board.
function lastSquare(x,y: nibble) return boolean is begin
	if x = x"e" and y = x"a" then return true;
	else                          return false;
	end if;
end;
function lastSquare(x,y, nbor: nibble) return boolean is begin
	if nbor = x"7" and x = x"e" and y = x"a" then return true;
	else return false;
	end if;
end;

-- Adjust the values of signals x and y to the next square
-- on the board. Wraps around to 1,1 at end of board
procedure advance(signal x, y: inout nibble) is begin
	   if x /= x"e" then x <= x + 1;
	elsif y /= x"a" then x <= x"1"; y <= y + 1;
	else					   x <= x"1"; y <= x"1";
	end if;
end;
procedure advance(signal x, y, nbor: inout nibble) is begin
	if nbor /= x"7" then nbor <= nbor + 1;
   elsif x /= x"e" then nbor <= x"0"; x <= x + 1; 
	elsif y /= x"a" then nbor <= x"0"; x <= x"1"; y <= y + 1;
	else					   nbor <= x"0"; x <= x"1"; y <= x"1";
	end if;
end;

-- Return next pseudo-random value following r
function random(r: word) return word is begin
	return (r(5) xor r(3) xor r(2) xor r(0)) & r(15 downto 1);
end;

begin										
	-- range-limited versions of x,y inputs
	x <= safeX(xIn); y <= safeY(yIn);		
	
	-- process to setup game and respond to player's moves
	process(clk) 
	procedure setMine(x,y: nibble; val: std_logic) is begin
		isMined(int(x))(int(y)) <= val;
	end;
	procedure setCover(x,y: nibble; val: std_logic) is begin
		isCovered(int(x))(int(y)) <= val;
	end;
	procedure setFlag(x,y: nibble; val: std_logic) is begin
		isFlagged(int(x))(int(y)) <= val;
	end;
	-- If square x,y is uncovered and has no neighboring mines, uncover its neighbors.
	-- The square directly above x,y is neighbor 0, then neighbor numbers increase
	-- as you go around square x,y in a clockwise direction.
	procedure clearNeighbors(x, y, nbor: nibble) is begin
		if (not covered(x,y)) and numMines(x,y) = o"0" then
			case nbor is
			when x"0" => setCover(x  ,y-1,'0');
			when x"1" => setCover(x+1,y-1,'0');
			when x"2" => setCover(x+1,y  ,'0');
			when x"3" => setCover(x+1,y+1,'0');
			when x"4" => setCover(x  ,y+1,'0');
			when x"5" => setCover(x-1,y+1,'0');
			when x"6" => setCover(x-1,y  ,'0');
			when x"7" => setCover(x-1,y-1,'0');
			when others =>
			end case;
		end if;
	end;
	-- If square x,y has a mine, add 1 to the mine count of the specified neighbor.
	procedure addToMineCount(x,y: nibble; signal nbor: inout nibble) is begin
		if mined(x,y) then
			case nbor is
			when x"0" => mineCount(int(x  ))(int(y-1)) 
									<= mineCount(int(x  ))(int(y-1)) + 1;
			when x"1" => mineCount(int(x+1))(int(y-1)) 
									<= mineCount(int(x+1))(int(y-1)) + 1;
			when x"2" => mineCount(int(x+1))(int(y  )) 
									<= mineCount(int(x+1))(int(y  )) + 1;
			when x"3" => mineCount(int(x+1))(int(y+1)) 
									<= mineCount(int(x+1))(int(y+1)) + 1;
			when x"4" => mineCount(int(x  ))(int(y+1)) 
									<= mineCount(int(x  ))(int(y+1)) + 1;
			when x"5" => mineCount(int(x-1))(int(y+1)) 
									<= mineCount(int(x-1))(int(y+1)) + 1;
			when x"6" => mineCount(int(x-1))(int(y  )) 
									<= mineCount(int(x-1))(int(y  )) + 1;
			when x"7" => mineCount(int(x-1))(int(y-1)) 
									<= mineCount(int(x-1))(int(y-1)) + 1;
			when others =>
			end case;
		end if;
	end;

	begin
		if rising_edge(clk) then
			if reset = '1' then
				randBits <= x"357d"; -- initial pseudo-random value
				state <= clearCounts; 
				x1 <= x"0"; y1 <= x"0"; nbor <= x"0";
			elsif newGame = '1' then
				state <= clearCounts; x1 <= x"0"; y1 <= x"0";			
			else
				case state is
				when clearCounts =>
					mineCount(int(x1))(int(y1)) <= o"0";
					   if x1 /= x"f" then x1 <= x1 + 1;
					elsif y1 /= x"b" then x1 <= x"0"; y1 <= y1 + 1;
					else					    x1 <= x"1"; y1 <= x"1"; state <= setMines;
					end if;
				when setMines =>
					-- place mines at random and "cover" them
					randBits <= random(randBits);
					if randBits < ("0" & level & "000000000000") then
						setMine(x1,y1,'1');
					else
						setMine(x1,y1,'0');
					end if;
					setCover(x1,y1,'1'); setFlag(x1,y1,'0');
					-- move onto next square
					advance(x1,y1);
					if lastSquare(x1,y1) then state <= countMines; end if;
				when countMines =>
					addToMineCount(x1,y1,nbor);
					advance(x1,y1,nbor);
					if lastSquare(x1,y1,nbor) then state <= playtime; end if;
				when playTime =>
					if markIt = '1' then
						-- mark/unmark current cell if it's covered
						if covered(x,y) then 
							if flagged(x,y) then setFlag(x,y,'0');
							else setFlag(x,y,'1');
							end if;
						end if;
					elsif stepOnIt = '1' then
						if covered(x,y) then
							if mined(x,y) then state <= gameOver;
							else setCover(x,y,'0');
							end if;
						end if;
					end if;
					-- uncover those cells that are adjacent to an 
					-- uncovered cell that has no neighboring mines
					clearNeighbors(x1,y1,nbor); advance(x1,y1,nbor);
				when gameOver =>
					-- uncover all cells
					setCover(x1,y1,'0'); advance(x1,y1);
				when others =>
				end case;
			end if;
		end if;
	end process;
					
	-- process to iterate through cells for copying to display
	-- advance (x2,y2) through range of values periodically
	process(clk) begin
		if rising_edge(clk) then
			if reset = '1' then
				timer <= (others => '0');
				x2 <= x"1"; y2 <= x"1";
			else
				if timer = (timer'range => '0') then
					advance(x2,y2);
				end if;
				timer <= timer + 1;
			end if;
		end if;
	end process;
	-- copy pattern for x2,y2 to the position on the display
	cp: copyPattern port map(clk,reset,startCopy,highlight,
									 pat,x2,y2,busy,hSync,vSync,dispVal);
	startCopy <= '1' when timer = (timer'range => '0') else '0';
	highlight <= '1' when x2 = x and y2 = y else '0';
	pat <= pattern(x2,y2);
end a1;