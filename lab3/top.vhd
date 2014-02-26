---------------------------------------------------------------------
-- Top module for stack calculator on prototype board
-- Jon Turner 1/2014
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

component outMod
	generic(wordSiz: integer :=  16);
	port(
		clk, reset: in std_logic;
		inBits, outBits: in word;		-- calculator input/output
		op: in nibble;				      -- calculator operation
		-- signals for controlling LCD display 
		lcd: out lcdSigs);
end component;

component stackCalc 
	generic(
		stakSiz: integer :=  8;
		lgSiz:   integer :=  3;
		wordSiz: integer := 16);
	port(
		clk, reset: in std_logic;	
		op: in nibble;
		doOp: in std_logic;
		dIn: in std_logic_vector(wordSiz-1 downto 0);
		result: out word);
end component;

signal reset: std_logic;
signal dBtn, pulse: std_logic_vector(3 downto 1);
signal inBits, outBits: word;
signal op: nibble;
signal doOp: std_logic;

begin
	
   -- connect the sub-components	
	imod: binaryInMod port map(clk,btn,knob,reset,dBtn,pulse,inBits);
	  sc: stackCalc generic map(8,3,wordSize) 
						 port map(clk,reset,op,doOp,inBits,outBits);
	omod: outMod generic map(wordSize) 
					 port map(clk,reset,inBits,outBits,op,lcd);
	
	-- calculator control signals
	op <= swt; doOp <= pulse(1);
	
	-- connect some input bits to leds
	led(7 downto 4) <= inbits(3 downto 0); 
	led(3 downto 0) <= swt;
end a1;
