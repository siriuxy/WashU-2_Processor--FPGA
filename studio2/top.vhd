---------------------------------------------------------------------
-- Top module for garage door opener on S3 board
-- Jon Turner 8/2010
--
-- This version uses just the buttons and switches plus the LEDs.
---------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
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

component opener port (
	clk, reset: in std_logic;
	openClose: in std_logic;	-- signal to open or close door
	obstruction: in std_logic;	-- obstruction detected
	atTop: in std_logic;		-- door at the top (fully open)
	atBot: in std_logic;		-- door at the bottom (fully closed)
	goUp: out std_logic;		-- raise door
	goDown: out std_logic);		-- lower door
end component;

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
	lcd: out lcdSigs);
end component binaryOutMod;

signal reset, strobe: std_logic;
signal dBtn, pulse: std_logic_vector(3 downto 1);
signal inBits, outBits: word;

signal openClose, obstruction, atTop, atBot: std_logic;
signal goUp, goDown: std_logic;

begin
	-- define internal signals
	openClose 	<= inBits(3) and pulse(2);
	obstruction <= inBits(2) and pulse(2);
	atTop 		<= inBits(1) and pulse(2);     
	atBot 		<= inBits(0) and pulse(2);	
	outBits <= (1 => goUp, 0 => goDown, others => '0');
	
   -- connect the sub-components	
	imod: binaryInMod port map(clk,btn,knob,reset,dBtn,pulse,inBits);
	gdo: opener port map(clk,dBtn(1),
		 openClose,obstruction,atTop,atBot,
		 goUp,goDown);
	omod: binaryOutMod port map(clk,reset,inBits,outBits,lcd);
	
	-- connect a few input and output bits to leds
	led(7 downto 4) <= inbits(3 downto 0); 
	led(3 downto 0) <= outBits(3 downto 0);
end a1;
