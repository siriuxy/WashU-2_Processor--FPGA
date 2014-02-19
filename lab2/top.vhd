---------------------------------------------------------------------
-- Top module for pattern matcher
-- 
-- 
--  by Likai Yan 02/2014
--
-- This circuit uses buttons and siwtches with LEDs to take in the input,
-- passing the information to the patternMatcher and outMode, 
-- and use LED to display certain information.
--
-- It connects the patterMatcher circuit with the binaryInMod and outMod circuits.
---------------------------------------------------------------------
library IEEE;
use ieee.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
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
component patternMatcher port (
	clk, restart, valid: in std_logic;
	inSym: in nibble;
	repCount: in nibble;
	patCount: out byte);
end component;

component binaryInMod is port(
	clk: in std_logic;
	btn: in buttons;
	knob: in knobSigs;
	resetOut: out std_logic;
	dBtn: out std_logic_vector(3 downto 1);
	pulse: out std_logic_vector(3 downto 1);
	inBits: out word);
end component;

component outMod is port(
	clk, reset: in std_logic;
	inSym: in nibble;					-- input symbol to matcher
	valid: in std_logic;				-- valid symbol signal
	patCount: in byte;				-- number of matches since restart
	-- signals for controlling LCD display 
	lcd: out lcdSigs);
end component outMod;

signal inSym, repCount : nibble;
signal patCount: byte;
signal restart, valid, resetOut, reset: std_logic;
signal dBtn, pulse: std_logic_vector(3 downto 1);
signal inBits: word;
--do we need to deal with signal buttons?
	-- TODO - your code here. Do we need to care about clk?
begin
imod: binaryInMod port map(clk,btn,knob,resetOut,dBtn,pulse,inBits);
pm: patternMatcher port map(clk,restart,valid,insym,repcount,patcount);
omod: OutMod port map(clk,reset,insym,valid,patCount,lcd);


restart<=pulse(1);
valid<=pulse(2);
inSym<=inBits(3 downto 0);
repCount<=inBits(11 downto 8);


led(3 downto 0)<=inSym;
led(7 downto 4)<=repCount;
end a1;
