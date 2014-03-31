------------------------------------------------------------------------------
-- copyPattern - copies a pattern to the VGA display buffer
-- Jon Turner - 2/2012
-- Modified by Jordan Helderman, Likai Yan: 
-- initAdr and advAdr are modified from the one given in studio 4 to fit 
-- this lab.
--
--   This module is used to support the fifteenPuzzle circuit.
-- It defines 16 patterns for the tiles in a 15 puzzle and
-- copies a pattern to a position in a VGA display buffer when
-- requested to do so.
--
-- client-side interface
-- inputs
--      start    when high, starts a copy operation; during the clock tick
--               when it's high, other inputs must be valid
--      highlight highlight the pattern by modifying the colors
--      pattern  is a four bit pattern index, specifying one of the pre-defined
--               patterns
--      position specifies the position of a tile in the puzzle; posiitons
--               are numbered 0..15, starting at top left, and proceeding
--               row-by-row
--   outputs
--      busy     is high whenever the circuit is busy carrying out an operation.
--
-- interface to external vga display
--
-- hSync, vSync   horizontal and vertical sync signals
-- dispVal         value of current pixel
------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.commonDefs.all;

entity copyPattern is port( 
   clk, reset : in  std_logic;
   -- client side interface
   start, highlight: in std_logic;
   pattern: in nibble;
   position: in nibble;
   busy: out std_logic;
   -- interface to external display
   hSync, vSync: out std_logic;
   dispVal: out pixel);
end copyPattern;

architecture a1 of copyPattern is
component vgaDisplay port (
   clk, reset: in std_logic;
   en, rw: in std_logic;
   addr: in dbAdr;
   data: inout pixel;
   hSync, vSync: out std_logic;
   dispPix: out pixel);
end component;

--constant coordMap : pos2CoordMap :=(
--	x"00", x"01", x"02", x"03", x"10"
subtype patRow is std_logic_vector(3*20-1 downto 0);
type patArray is array(natural range <>) of patRow;
constant patMem: patArray := (
   o"11111111111111111110",
   o"11111111111111111110",
   o"11111111111111111110",
   o"11111111111111111110",
   o"11111111111111111110",
   o"11111111111111111110",
   o"11111111111111111110",
   o"11111111111111111110",
   o"11111111111111111110",
   o"11111111111111111110",
   o"11111111111111111110",
   o"11111111111111111110",
   o"11111111111111111110",
   o"11111111111111111110",
   o"11111111111111111110",
   o"11111111111111111110",
   o"11111111111111111110",
   o"11111111111111111110",
   o"11111111111111111110",
   o"00000000000000000000",

   o"22222222222222222220",
   o"22222222222222222220",
   o"22222222227222222220",
   o"22222222277222222220",
   o"22222222777222222220",
   o"22222227777222222220",
   o"22222222277222222220",
   o"22222222277222222220",
   o"22222222277222222220",
   o"22222222277222222220",
   o"22222222277222222220",
   o"22222222277222222220",
   o"22222222277222222220",
   o"22222222277222222220",
   o"22222222277222222220",
   o"22222227777772222220",
   o"22222227777772222220",
   o"22222222222222222220",
   o"22222222222222222220",
   o"00000000000000000000",

   o"22222222222222222220",
   o"22222222222222222220",
   o"22222222777722222220",
   o"22222777777777222220",
   o"22277772222227772220",
   o"22277222222222277220",
   o"22222222222222277220",
   o"22222222222222227720",
   o"22222222222222227720",
   o"22222222222222277220",
   o"22222222222227772220",
   o"22222222222777222220",
   o"22222222277722222220",
   o"22222227772222222220",
   o"22222777222222222220",
   o"22277722222222222220",
   o"22777777777777777220",
   o"22777777777777777220",
   o"22222222222222222220",
   o"00000000000000000000",

   o"22222222222222222220",
   o"22222222222222222220",
   o"22222277777722222220",
   o"22227777777777222220",
   o"22277222222227722220",
   o"22222222222222772220",
   o"22222222222222277220",
   o"22222222222222277220",
   o"22222222222227772220",
   o"22222222227777222220",
   o"22222227777722222220",
   o"22222222227777222220",
   o"22222222222227772220",
   o"22222222222222277220",
   o"22222222222222277220",
   o"22277222222222772220",
   o"22227777777777722220",
   o"22222777777772222220",
   o"22222222222222222220",
   o"00000000000000000000",

   o"22222222222222222220",
   o"22222222222222222220",
   o"22222222222777222220",
   o"22222222227777222220",
   o"22222222277277222220",
   o"22222222772277222220",
   o"22222227722277222220",
   o"22222277222277222220",
   o"22222772222277222220",
   o"22227722222277222220",
   o"22277222222277222220",
   o"22772222222277222220",
   o"22777777777777777220",
   o"22777777777777777220",
   o"22222222222277222220",
   o"22222222222277222220",
   o"22222222222277222220",
   o"22222222222222222220",
   o"22222222222222222220",
   o"00000000000000000000",

   o"22222222222222222220",
   o"22222222222222222220",
   o"22777777777777777220",
   o"22777777777777777220",
   o"22772222222222222220",
   o"22772222222222222220",
   o"22772222222222222220",
   o"22772222222222222220",
   o"22777777777772222220",
   o"22777777777777722220",
   o"22222222222222772220",
   o"22222222222222277220",
   o"22222222222222277220",
   o"22222222222222277220",
   o"22772222222222772220",
   o"22277777777777722220",
   o"22227777777777222220",
   o"22222222222222222220",
   o"22222222222222222220",
   o"00000000000000000000",

   o"22222222222222222220",
   o"22222222222222222220",
   o"22222777777777722220",
   o"22227777777777772220",
   o"22277222222222277220",
   o"22772222222222222220",
   o"22772222222222222220",
   o"22772222222222222220",
   o"22772222222222222220",
   o"22772777777772222220",
   o"22777777777777722220",
   o"22777222222222772220",
   o"22772222222222277220",
   o"22772222222222277220",
   o"22277222222222277220",
   o"22227777777777772220",
   o"22222777777777722220",
   o"22222222222222222220",
   o"22222222222222222220",
   o"00000000000000000000",

   o"22222222222222222220",
   o"22222222222222222220",
   o"22777777777777777220",
   o"22777777777777777220",
   o"22222222222222277220",
   o"22222222222222772220",
   o"22222222222227722220",
   o"22222222222277222220",
   o"22222222222772222220",
   o"22222222227722222220",
   o"22222222277222222220",
   o"22222222772222222220",
   o"22222227722222222220",
   o"22222277222222222220",
   o"22222772222222222220",
   o"22227722222222222220",
   o"22277222222222222220",
   o"22222222222222222220",
   o"22222222222222222220",
   o"00000000000000000000",

   o"22222222222222222220",
   o"22222222222222222220",
   o"22222777777777222220",
   o"22227777777777722220",
   o"22277222222222772220",
   o"22772222222222277220",
   o"22772222222222277220",
   o"22772222222222277220",
   o"22277222222222772220",
   o"22227777777777722220",
   o"22227777777777722220",
   o"22277222222222772220",
   o"22772222222222277220",
   o"22772222222222277220",
   o"22772222222222277220",
   o"22277222222222772220",
   o"22227777777777722220",
   o"22222777777777222220",
   o"22222222222222222220",
   o"00000000000000000000",

   o"22222222222222222220",
   o"22222222222222222220",
   o"22222777777777222220",
   o"22227777777777722220",
   o"22277222222222772220",
   o"22772222222222277220",
   o"22772222222222277220",
   o"22772222222222277220",
   o"22277722222222277220",
   o"22227777777777777220",
   o"22222227777777777220",
   o"22222222222222277220",
   o"22222222222222277220",
   o"22222222222222772220",
   o"22222222222227722220",
   o"22222222222277222220",
   o"22222222222772222220",
   o"22222222227722222220",
   o"22222222222222222220",
   o"00000000000000000000",

   o"22222222222222222220",
   o"22222222222222222220",
   o"27722227777777722220",
   o"27722277777777772220",
   o"27722772222222277220",
   o"27727722222222227720",
   o"27727722222222227720",
   o"27727722222222227720",
   o"27727722222222227720",
   o"27727722222222227720",
   o"27727722222222227720",
   o"27727722222222227720",
   o"27727722222222227720",
   o"27727722222222227720",
   o"27722772222222277220",
   o"27722277777777772220",
   o"27722227777777722220",
   o"22222222222222222220",
   o"22222222222222222220",
   o"00000000000000000000",

   o"22222222222222222220",
   o"22222222222222222220",
   o"22277222222222772220",
   o"22277222222222772220",
   o"22277222222222772220",
   o"22277222222222772220",
   o"22277222222222772220",
   o"22277222222222772220",
   o"22277222222222772220",
   o"22277222222222772220",
   o"22277222222222772220",
   o"22277222222222772220",
   o"22277222222222772220",
   o"22277222222222772220",
   o"22277222222222772220",
   o"22277222222222772220",
   o"22277222222222772220",
   o"22222222222222222220",
   o"22222222222222222220",
   o"00000000000000000000",

   o"22222222222222222220",
   o"22222222222222222220",
   o"22772222277772222220",
   o"22772222777777722220",
   o"22772227722222772220",
   o"22772277222222277220",
   o"22772222222222227720",
   o"22772222222222227720",
   o"22772222222222227720",
   o"22772222222222277220",
   o"22772222222222772220",
   o"22772222222227722220",
   o"22772222222277222220",
   o"22772222222772222220",
   o"22772222277722222220",
   o"22772227772222222220",
   o"22772777777777777220",
   o"22772777777777777220",
   o"22222222222222222220",
   o"00000000000000000000",

   o"22222222222222222220",
   o"22222222222222222220",
   o"22772222277772222220",
   o"22772227777777722220",
   o"22772277222222772220",
   o"22772222222222277220",
   o"22772222222222227720",
   o"22772222222222227720",
   o"22772222222222777220",
   o"22772222222777722220",
   o"22772222227772222220",
   o"22772222222777722220",
   o"22772222222222777220",
   o"22772222222222227720",
   o"22772222222222227720",
   o"22772277222222277220",
   o"22772227777777772220",
   o"22772222777777222220",
   o"22222222222222222220",
   o"00000000000000000000",

   o"22222222222222222220",
   o"22222222222222222220",
   o"22772222222227722220",
   o"22772222222277722220",
   o"22772222222777722220",
   o"22772222227727722220",
   o"22772222277227722220",
   o"22772222772227722220",
   o"22772227722227722220",
   o"22772277222227722220",
   o"22772772222227722220",
   o"22772772222227722220",
   o"22772777777777777720",
   o"22772777777777777720",
   o"22772222222227722220",
   o"22772222222227722220",
   o"22772222222227722220",
   o"22222222222222222220",
   o"22222222222222222220",
   o"00000000000000000000",

   o"22222222222222222220",
   o"22222222222222222220",
   o"22772777777777777720",
   o"22772777777777777720",
   o"22772772222222222220",
   o"22772772222222222220",
   o"22772772222222222220",
   o"22772772222222222220",
   o"22772777777777222220",
   o"22772777777777772220",
   o"22772222222222277220",
   o"22772222222222227720",
   o"22772222222222227720",
   o"22772222222222227720",
   o"22772772222222277220",
   o"22772277777777772220",
   o"22772227777777722220",
   o"22222222222222222220",
   o"22222222222222222220",
   o"00000000000000000000");

-- register used to keep track of time step within update;
-- between operations, held at "all ones"
signal tick: unsigned(10 downto 0);

-- signals used to write to the display memory in vgaDisplay
signal en, rw: std_logic;
signal dispAdr: dbAdr;

-- address of row in pattern memory and offset of pixel within row
signal patAdr: std_logic_vector(8 downto 0);
signal patOffset: byte;

-- pixel value read from pattern memory and possibly
-- highlighted version passed to display buffer
signal patPix, curPix: pixel;

-- local copy of highlight input
signal hiLite: std_logic;   

begin
   curPix <= patPix when en = '1' and hiLite = '0' 
               else not patPix when en = '1' and hiLite = '1'
               else (others => 'Z');
   vga: vgaDisplay port map(clk,reset,en,rw,dispAdr,curPix,
                            hSync,vSync,dispVal);
   
   process(clk)
      -- Initialize address signals used to access the pattern memory
      -- and the display buffer
      procedure initAdr(pos,pat: in nibble; 
                        signal dAdr: out dbAdr; 
                        signal pAdr: inout std_logic_vector(8 downto 0); 
                        signal pOffset: out byte) is
		variable row, col: unsigned(2*dAdr'length-1 downto 0);
      begin
			-- placeholders for the position in the display buffer
			-- constant offset accounts for the centering of the board on 
			--		the VGA display
			row := to_unsigned(20*320,dAdr'length)*pad(unsigned(pos(3 downto 2)) + 4,dAdr'length);
			col := to_unsigned(20,dAdr'length)*pad(unsigned(pos(1 downto 0)) + 4,dAdr'length);
			
			dAdr <= row(dAdr'high downto 0) + col(dAdr'high downto 0);
			pAdr <= pad(slv(20,9)*pad(pat,8),9);
			pOffset <= slv(59,8);
      end;
      -- Advance address signals used to access the pattern memory 
      -- and display buffer
      procedure advanceAdr(signal dAdr: inout dbAdr; 
                           signal pAdr: inout std_logic_vector(8 downto 0); 
                           signal pOffset: inout byte) is 
      begin
			if pOffset = 2 then
				pAdr <= pAdr + 1;
				pOffset <= slv(59,8);
				dAdr <= dAdr + to_unsigned(320-19,dAdr'length);
			else
				pOffset <= pOffset - 3;
				dAdr <= dAdr + 1;
			end if;
      end;   
   begin
      if rising_edge(clk) then
         en <= '0'; rw <= '0'; -- default values
         if reset = '1' then
            tick <= (others => '1');
            hiLite <= '0';
         else
            tick <= tick + 1; -- increment by default
            if start = '1' and tick = (tick'range => '1') then
               initAdr(position,pattern,dispAdr,patAdr,patOffset); 
               hiLite <= highLight;
            elsif tick < to_unsigned(4*400,11) then
               -- an update is in progress
               -- each step involves copying a pixel from the pattern to
               -- the display buffer; we allow four clock ticks per step            
               if tick(1 downto 0) = "00" then
                  -- first read from pattern memory
                  patPix <= unsigned(patMem(int(patAdr))(
                                     int(patOffset) downto int(patOffset-2)));
                  en <= '1'; -- write to display buffer during next tick
               elsif tick(1 downto 0) = "11" then                  
                  advanceAdr(dispAdr, patAdr, patOffset);
               end if;
            else -- returns circuit to "ready" state
               tick <= (others => '1');
            end if;
         end if;
      end if;
   end process;
   busy <= '1' when reset = '0' and tick /= (tick'range => '1') else '0';
end a1;
