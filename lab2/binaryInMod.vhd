----------------------------------------------------------------------------------
-- Generic binary input module for providing inputs to other circuits
-- Jon Turner - 10/2011
--
-- Modified for lab1 to provide BCD input value.
-- Jon Turner - 12/2013
----------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use work.commonDefs.all;

entity binaryInMod is port(
	clk: in std_logic;
	btn: in buttons;
	knob: in knobSigs;
	resetOut: out std_logic;
	dBtn: out std_logic_vector(3 downto 1);
	pulse: out std_logic_vector(3 downto 1);
	inBits: out word);
end binaryInMod;

architecture a1 of binaryInMod is
component debouncer 
	generic (width: integer := 8);
	port(
	clk: in std_logic;
	dIn: in std_logic_vector(width-1 downto 0);
	dOut: out std_logic_vector(width-1 downto 0)
	);
end component;

component knobIntf port(
	clk, reset: in std_logic;
	knob: in knobSigs; 				
	tick: out std_logic;				
	clockwise: out std_logic;		
	delta: out word); 
end component;

signal dbb, dbb_prev: buttons;
signal dbKnob: knobSigs;
signal reset: std_logic;
signal tick, clockwise: std_logic;
signal bits, delta: word;
begin
	-- debounce the buttons	and define reset/resetOut
	db: debouncer generic map(width => 4) port map(clk, btn, dbb);
	
	dBtn <= dbb(3 downto 1);
	reset <= dbb(0);
	resetOut <= reset;
	
	-- define pulse output using debounced buttons
	process (clk) begin
		if rising_edge(clk) then dbb_prev <= dbb; end if;
	end process;	
	pulse <= dbb(3 downto 1) and (not dbb_prev(3 downto 1));

	-- define inBits, based on signals from knob interface
	ki: knobIntf port map(clk, reset, knob, tick, clockwise, delta);
	process (clk) begin
		if rising_edge(clk) then
			if reset = '1' then
				bits <= (others => '0');
			elsif tick = '1' then
				if  clockwise = '1' then
					bits <= bits + delta;
				else
					bits <= bits - delta;
				end if;
			end if;
		end if;
	end process;
	inBits <= bits;
end a1;

