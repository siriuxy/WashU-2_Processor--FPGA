---------------------------------------------------------------------
-- Top module for simple calculator on S3 board
-- Jon Turner 8/2010
--
-- This version uses just the buttons and switches plus the LEDs.
---------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
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

component calculator port (
	clk: in std_logic;
	clear, load, add, mode: in std_logic;
	din : in word;
	result: out word;
	error: out std_logic); --add error output
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
	clk, reset, error: in std_logic;
	topRow, botRow: in word;
	lcd: out lcdSigs);
end component binaryOutMod;

signal reset, clear, load, add, mode, error: std_logic;
signal dBtn, pulse: std_logic_vector(3 downto 1);
signal inBits, outBits: word;

begin
	
   -- connect the sub-components	
	imod: binaryInMod port map(clk,btn,knob,reset,dBtn,pulse,inBits);
	calc: calculator port map(clk,clear,load,add,mode,inBits,outBits,error);
	omod: binaryOutMod port map(clk,reset,error,inBits,outBits,lcd);
	
	-- define internal control signals
	clear <= dBtn(1) or reset;
	load <= pulse(2);
	add <= pulse(3);
	mode<=swt(0);
	
	-- connect a few input and output bits to leds
	led(7 downto 2) <= ("000000"); 
	led(0)<=mode;
	led(1)<=error;
end a1;
