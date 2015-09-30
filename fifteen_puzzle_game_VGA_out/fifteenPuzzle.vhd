------------------------------------------------------------------------------
-- Fifteen Puzzle game
-- Jordan Helderman, Likai Yan
--
-- This circuit implements the well-known 15 puzzle on the prototype board.
-- 
-- We added a few constant that specifies update frequency and
-- the size of the board. We added a signal for counting time, 
-- and two more for current time as buffers. Also, a few 
--functions are implemented to detect the current location of 
--the empty square to ensure we won't violate the boundary 
-- condition
-- We have two sychronous processes: one handles the states of 
-- the current game that is specified in the move procedure and  
-- counts time the player has spent. The other deals with the
-- copying pattern by counting the time needed to refresh the 
-- next tile. 
--
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.commonDefs.all;

entity fifteenPuzzle is port (
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
end fifteenPuzzle;

architecture a1 of fifteenPuzzle is

component copyPattern port( 
   clk, reset : in  std_logic;
   -- client-side interface
   start, highlight: in std_logic;
   pattern: in nibble;
   position: in nibble;
   busy: out std_logic;
   -- interface to external display
   hSync, vSync: out std_logic;
   dispVal: out pixel);
end component;

-- Constants
constant lgMaxRandMoves : integer := 10;
constant lgUpdateTime : integer := 19;
constant numSimRandMoves : integer := 32;
constant numRTRandMoves : integer := 1024;
constant boardArraySize : integer := 16;
-- Time between updates to puzlTime. Measured in clock ticks.
constant updateTime : integer := 500000; 

-- state of puzzle controller
type stateType is (init, scramble, solveIt, puzzleSolved);
signal state: stateType;

-- array of nibbles defines the state of the puzzle
type boardArray is array(0 to 15) of nibble;
signal board: boardArray;

signal emptySquare: nibble; -- position of the empty space
signal randBits: word; -- random bits for scrambling puzzle

-- signals to control copyPattern
signal timer: std_logic_vector(10+operationMode*5 downto 0);
signal startCopy, busy, highlight: std_logic;
signal pos, nbor, pat: nibble;

signal cnt : std_logic_vector(lgMaxRandMoves - 1 downto 0); 
signal puzlTimeCnt : std_logic_vector(lgUpdateTime - 1 downto 0);
signal puzlTimeBuf : bcdVec(5 downto 0);
signal bestTimebuf : bcdVec(5 downto 0);

-- Return next pseudo-random value following r
function random(r: word) return word is begin
   return (r(5) xor r(3) xor r(2) xor r(0)) & r(15 downto 1);
end;

-- Return true if emptySquare is in top row, else false.
impure function topRow return boolean is begin
   return emptySquare(3 downto 2) = "00";
end;
-- Return true if emptySquare is in bottom row, else false.
impure function botRow return boolean is begin
	return emptySquare(3 downto 2) = "11";
end;
-- Return true if emptySquare is in leftmost column row, else false.
impure function leftCol return boolean is begin
   return emptySquare(1 downto 0) = "00";
end;
-- Return true if emptySquare is in rightmost column, else false.
impure function rightCol return boolean is begin
   return emptySquare(1 downto 0) = "11";
end;

-- Return true if the current board state matches the "goal" state.
-- That is, tile number i is at position i for all values of i.
impure function solved return boolean is begin
	for i in 0 to 15 loop
		if (board(i) /= i) then
			return false;
		end if;
	end loop;
	return true;
end;

begin
   -- process to setup puzzle and respond to player's moves
   process(clk) 
   -- Move the empty square in the direction specified by dir. 
   -- Update both the game board and the emptySquare signal.
   -- Dir=0 means move up, 1 means move right, 2 means move down
   -- and 3 means move left.
   -- Ignore requests that would move the empty square off the
   -- board (so if you're in the top row, ignore up-moves).
   procedure move(dir: std_logic_vector(1 downto 0)) is begin
			case dir is
				when "00" =>	-- Move Up
					if (topRow = false) then		-- If not on top row
						emptySquare <= emptySquare - "0100";
						board(int(emptySquare)) <= board(int(emptySquare - "0100"));
						board(int(emptySquare - "0100")) <= board(int(emptySquare));
					end if;
				when "01" =>	-- Move Right
					if (rightCol = false) then	-- If not on right column
						emptySquare <= emptySquare + "0001";
						board(int(emptySquare)) <= board(int(emptySquare + "0001"));
						board(int(emptySquare + "0001")) <= board(int(emptySquare));
					end if;
				when "10" =>	-- Move Down
					if (botRow = false) then		-- If not on bottom row
						emptySquare <= emptySquare + "0100";
						board(int(emptySquare)) <= board(int(emptySquare + "0100"));
						board(int(emptySquare + "0100")) <= board(int(emptySquare));
					end if;
				when "11" =>	-- Move Left
					if (leftCol = false) then		-- If not on left column
						emptySquare <= emptySquare - "0001";
						board(int(emptySquare)) <= board(int(emptySquare - "0001"));
						board(int(emptySquare - "0001")) <= board(int(emptySquare));
				end if;
				when others =>
			end case;
   end;
	
   begin
      if rising_edge(clk) then
         if reset = '1' then
            randBits <= x"357d"; -- initial random value
            state <= init; 
				cnt <= (others => '0');
--            emptySquare <= x"0";
				for i in 5 downto 0 loop
					puzlTimeBuf(i) <= x"0";
					bestTimeBuf(i) <= x"f";
				end loop;
				puzlTimeCnt <= (others => '0');
         elsif nuPuzzle = '1' then
            state <= init; 
				cnt <= (others => '0');
				for i in 5 downto 0 loop
					puzlTimeBuf(i) <= x"0";
				end loop;
				puzlTimeCnt <= (others => '0');
         else
            case state is
            when init =>
               -- put the board in goal state
               -- when done, go to scramble state
	            emptySquare <= x"0";
					board(int(cnt)) <= cnt (3 downto 0);
					cnt <= cnt + 1;
					if (int(cnt) = 15) then
						state <= scramble;
						cnt <= (others => '0');
					end if;
					puzlTimeCnt <= (others => '0');
            when scramble =>
               randBits <= random(randBits);
               -- scramble the tiles on the board
               -- by making random moves
               -- do 32 moves when operationMode=0
               -- do 1024 when operationMode=1
               -- when done, go to solveIt state
               -- and start puzlTime counting
					
					move(randBits(1 downto 0));
					
					if operationMode = 0 then
						if (int(cnt) = numSimRandMoves - 1) then
							state <= solveIt;
						end if;
					else
						if (int(cnt) = numRTRandMoves - 1) then
							state <= solveIt;
						end if;
					end if;
					
					cnt <= cnt + 1;
            when solveIt =>
               -- if in the goal state
               --   stop counting puzlTime and
               --     update bestTime;
               --   go to solved state;
               -- otherwise, if a move is requested
               --   them make the move;
               -- increment puzlTime every 10 ms
					if solved = true then
						if (lessThan(puzlTimebuf, bestTimebuf)) then
							bestTimebuf <= puzlTimebuf;
						end if;
					else
						puzlTimeCnt <= puzlTimeCnt + 1;
						if (moveNow = '1') then		-- Move if requested
							move(moveDir);
						end if;
						if int(puzlTimeCnt) = updateTime then --increment puzlTime every 10 ms
							puzlTimeCnt <= (others => '0'); 	-- reset the counter
							puzlTimebuf <= plus1(puzlTimebuf);		-- increment the timer
						end if;
					end if;
            when others =>
            end case;
         end if;
      end if;
   end process;
               
   -- Process to control copying of patterns to display.
   -- Increment timer to control start of copying operation.
   -- Increment pos for each new copy operation, in order to
   -- iterate through all positions on the board.
   process(clk) begin
      if rising_edge(clk) then
         if reset = '1' then
				timer <= (others => '0');
				pos <= (others => '0');
         else
				if (timer = (timer'range => '0')) then
					pos <= pos + 1;
				end if;
				timer <= timer + 1;
         end if;
      end if;
   end process;

   -- copy pattern for tile at position pos to its place on the display
   cp: copyPattern port map(clk,reset,startCopy,highlight,pat,
                            pos,busy,hSync,vSync,dispVal);
   startCopy <= '1' when timer = (timer'range => '0') else '0';
	
	--  pattern to be displayed in the current position
   pat <= board(int(pos));
	
   -- highlight the neighbor of the empty square, selected by moveDir
   highlight <= '1' when nbor = pos and (nbor /= emptySquare) else 
					 '0';
					 
	-- bor=position of the neighbor of emptySquare
   -- selected by moveDir;
	-- if the neighbor is off the board, make nbor=emptySquare		 
   nbor <= emptySquare - "0100" when moveDir = "00" and topRow = false else
			  emptySquare + "0001" when moveDir = "01" and rightCol = false else
			  emptySquare + "0100" when moveDir = "10" and botRow = false else
			  emptySquare - "0001" when moveDir = "11" and leftCol = false else
			  emptySquare;
	
   -- auxiliary signals
   emptyPos <= emptySquare;
   peekVal <= board(int(peekPos));
	bestTime<=bestTimebuf;
	puzltime<=puzltimebuf;
end a1;
