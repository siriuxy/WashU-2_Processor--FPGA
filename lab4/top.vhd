---------------------------------------------------------------------
-- Top module for fifteenPuzzle circuit on prototype board
-- your name
--
-- Your documentation here
-- TODOs: 1. blue square 2. debouncing knob 3. moving to center, but not in a mod way
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.commonDefs.all;

entity top is port(
   clk: in std_logic;
   -- S3 board buttons, knob, switches and LEDs
   btn: in buttons;
   knob: in knobSigs;
   swt: in switches;
   lcd: out lcdSigs;
   led: out leds;
   -- signals for controlling VGA display 
   hSync, vSync: out std_logic;
   dispVal: out pixel);
end top;

architecture a1 of top is

-- TODO
-- component declarations
component binaryInMod
	port(
		clk: in std_logic;
		btn: in buttons;
		knob: in knobSigs;
		resetOut: out std_logic;
		dBtn: out std_logic_vector(3 downto 1);
		pulse: out std_logic_vector(3 downto 1);
		inBits: out word);
end component;

component fifteenPuzzle
	port(
		clk, reset: in std_logic;
		-- client-side interface
		nuPuzzle: in std_logic;
		moveDir: in std_logic_vector(1 downto 0);
		moveNow: in std_logic;
		puzlTime, bestTime: out bcdVec(5 downto 0);
		-- auxiliary signals for testing (comment these out?)
		peekPos: in nibble; -- specifies a board position
		peekVal: out nibble; -- tile at position peekPos
		emptyPos: out nibble; -- position of empty square
		-- interface to external display
		hSync, vSync: out std_logic;
		dispVal: out pixel);
end component;

component outMod
	port(
		clk, reset: in std_logic;
		puzlTime, bestTime: in bcdVec(5 downto 0);
		-- signals for controlling LCD display 
		lcd: out lcdSigs);
end component;

-- intermediate signal declarations
signal reset, nuPuzzle, moveNow : std_logic;
signal moveDir : std_logic_vector(1 downto 0);
signal puzlTime, bestTime : bcdVec(5 downto 0);
signal peekPos, peekVal, emptyPos : nibble;
signal dBtn: std_logic_vector(3 downto 1);
signal pulse: std_logic_vector(3 downto 1);
signal inBits: word;
--signal lcd : lcdSigs;

begin      
   -- TODO
   -- Instantiate and connect the sub-components, fifteenPuzzle,
   -- binaryInMod and outMod
   -- Connect the low-order two bits from binaryInMod to the moveDir
   -- input of fifteenPuzzle
   -- Use pulse(1) for the nuPuzzle input, pulse(2) for the moveIt input
   -- Connect puzlTime and bestTime from fifteenPuzzle to outMod
   -- Connect the switches to peekPos, connect peekVal to led(3..0)
   -- and connect emptyPos to led(7..4)
	
	-- Component Instantiations
	imod : binaryInMod port map(clk,btn,knob,reset,dBtn,pulse,inBits);
	puzl : fifteenPuzzle port map(clk,reset,nuPuzzle,moveDir,moveNow,
											puzlTime,bestTime,peekPos,peekVal,
											emptyPos,hSync,vSync,dispVal);
	omod : outMod port map(clk,reset,puzlTime,bestTime,lcd);
	
	-- Component connections
	moveDir <= inBits(1 downto 0);
	nuPuzzle <= pulse(1);
	moveNow <= pulse(2);
	peekPos <= swt;
	led(3 downto 0) <= peekVal;
	led(7 downto 4) <= emptyPos;
end a1;
