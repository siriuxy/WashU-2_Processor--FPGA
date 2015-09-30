------------------------------------------------------------------
-- Top module for Washu2
-- Jon Turner - 5/2010
--
-- Defines the connections among the various components and the
-- connections between the external pins provided by the S3 board
-- and the corresponding internal signals.
--------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use work.commonDefs.all;

entity top is port(
	clk: in std_logic;
	
	btn: in buttons;
	knob: in knobSigs;
	swt: in switches;
	led: out leds;

	-- signals for controlling LCD display 
	lcd: out lcdSigs;
	
	-- signals for controlling VGA 
	hSync, vSync: out std_logic;
	dispVal: out std_logic_vector(2 downto 0));
end top;

architecture a1 of top is

component cpu port (
   clk, reset: in  std_logic;
   en, rw: out std_logic;    	
	aBus:	out address; dBus: inout word;
	pause: in  std_logic;
	regSelect: in std_logic_vector(1 downto 0);
	dispReg: out word);
end component;

component ram port (
   clk, en, rw: in std_logic;
   aBus: in address; 
	dBus: inout word);
end component;

component console port(
	clk: in std_logic;
	
	-- inputs and outputs
	btn: in buttons;
	knob: in knobSigs;
	swt: in switches;
	
	resetOut: out std_logic;
	pause: out std_logic;	-- pause CPU

	-- memory signals
	memEnIn, memRwIn: in std_logic;
	memEnOut, memRwOut: out std_logic;
	aBus: out word;
	dBus: inout word;
	
	-- signals for observing on CPU registers
	regSelect: out std_logic_vector(1 downto 0);
	cpuReg: in word;
	
	-- signals for controlling LCD display
	lcd: out lcdSigs);
end component;

component vgaDisplay port (
	clk, reset: in std_logic;
	en, rw: in std_logic;
	addr: in address;
	data: inout word;
	hSync, vSync: out std_logic;
	dispVal: out std_logic_vector(2 downto 0));
end component;

signal reset, pause : std_logic;
signal mem_en, mem_rw, cpu_en, cpu_rw : std_logic;
signal aBus: address; signal dBus: word;

signal regSelect: std_logic_vector(1 downto 0);
signal cpuReg: word;

begin	
  cpuu:        cpu port map(clk, reset, cpu_en, cpu_rw, aBus, dBus, 
								    pause, regSelect, cpuReg);
  ramm:        ram port map(clk, mem_en, mem_rw, aBus, dBus);
  cons:	  console port map(clk, btn, knob, swt, reset, pause, 
								    cpu_en, cpu_rw, mem_en, mem_rw, aBus, dBus,
								    regSelect, cpuReg,lcd);
	vga: vgaDisplay port map(clk, reset, mem_en, mem_rw, aBus, dBus,
									 hSync, vSync, dispVal);
									 
	led <= swt & swt;
end a1;
