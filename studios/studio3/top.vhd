---------------------------------------------------------------------
-- Top module for simple queue on prototype board
-- Jon Turner 2/2014
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
	led: out leds;
	-- signals for controlling LCD display 
	lcd: out lcdSigs);
end top;

architecture a1 of top is

component binaryInMod port(
	clk: in std_logic;
	btn: in buttons;
	knob: in knobSigs;
	resetOut: out std_logic;
	dBtn: out std_logic_vector(3 downto 1);
	pulse: out std_logic_vector(3 downto 1);
	inBits: out word);
end component;

component binaryOutMod port(
	clk, reset: in std_logic;
	topRow, botRow: in word;
	-- signals for controlling LCD display 
	lcd: out lcdSigs);
end component;

component queue
	generic(
		qSiz: integer := 16;
		lgSiz: integer := 4;
		wordSiz: integer := 16);
	port( 
		clk, reset: in std_logic;
		enq, deq : in std_logic; -- control signals
		dataIn : in std_logic_vector(wordSiz-1 downto 0); -- value to be enqueued
		dataOut : out std_logic_vector(wordSiz-1 downto 0); -- first word in the queue
		empty, full : out std_logic); -- status signals
end component;

signal reset: std_logic;
signal dBtn, pulse: std_logic_vector(3 downto 1);
signal inBits, outBits: word;

-- TODO - define signals needed to connect queue

begin
	-- TODO
	-- instantiate inMod, outMod and queue components and
	-- connect them up
	-- use pulse(3), pulse(2) and pulse(1) for enq, deq and the
	-- simultaneous enq/deq
	-- also connect dBtn(3..1) to led(7..5) and the queue's
	-- empty full signals to led(1..0)
end a1;
