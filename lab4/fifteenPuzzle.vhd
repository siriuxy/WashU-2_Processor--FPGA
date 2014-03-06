------------------------------------------------------------------------------
-- Fifteen Puzzle game
-- your name
--
-- This circuit implements the well-known 15 puzzle on the prototype board.
-- 
-- your documentation here
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

-- TODO - add other signals you may need

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
   -- TODO
end;
-- Return true if emptySquare is in leftmost column row, else false.
impure function leftCol return boolean is begin
   -- TODO
end;
-- Return true if emptySquare is in rightmost column, else false.
impure function rightCol return boolean is begin
   -- TODO
end;

-- Return true if the current board state matches the "goal" state.
-- That is, tile number i is at position i for all values of i.
impure function solved return boolean is begin
   -- TODO
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
      -- TODO
   end;
   begin
      if rising_edge(clk) then
         if reset = '1' then
            randBits <= x"357d"; -- initial random value
            state <= init; cnt <= (others => '0');
            emptySquare <= x"0";
            -- TODO - other initialization
         elsif nuPuzzle = '1' then
            state <= init;
            -- TODO - other initialization
         else
            case state is
            when init =>
               -- TODO - put the board in goal state
               -- when done, go to scramble state
            when scramble =>
               randBits <= random(randBits);
               -- TODO
               -- scramble the tiles on the board
               -- by making random moves
               -- do 32 moves when operationMode=0
               -- do 1024 when operationMode=1
               -- when done, go to solveIt state
               -- and start puzlTime counting
            when solveIt =>
               -- TODO
               -- if in the goal state
               --   stop counting puzlTime and
               --     update bestTime;
               --   go to solved state;
               -- otherwise, if a move is requested
               --   them make the move;
               -- increment puzlTime every 10 ms
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
            -- TODO
         else
            -- TODO
         end if;
      end if;
   end process;

   -- copy pattern for tile at position pos to its place on the display
   cp: copyPattern port map(clk,reset,startCopy,highlight,pat,
                            pos,busy,hSync,vSync,dispVal);
   startCopy <= '1' when timer = (timer'range => '0') else '0';
   pat <= -- TODO pattern to be displayed in the current position
   -- highlight the neighbor of the empty square, selected by moveDir
   highlight <= '1' when nbor = pos and (nbor /= emptySquare)
                else '0';
   nbor <= -- TODO - nbor=position of the neighbor of emptySquare
           -- selected by moveDir;
           -- if the neighbor is off the board, make nbor=emptySquare
                
   -- auxiliary signals
   emptyPos <= emptySquare;
   peekVal <= board(int(peekPos));
end a1;
