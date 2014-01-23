-----------------------------------------------------------------------------
-- Generic binary input module for use with prototype board.
-- Provides inputs that can be used by other circuits for various purposes.
-- Jon Turner - 10/2011
--
-- inputs
--    btn       four bit signal from external buttons
--    knobSigs  three bit signal from external knob
--
-- outputs
--    resetOut  reset signal derived from btn(0)
--    dBtn	debounced versions of btn(3..1)
--    pulse     one clock tick pulses, derived from btn(3..1)
--    inBits    16 bit value controlled by knob
-----------------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.commonDefs.all;

entity binaryInMod is port(
	clk: in std_logic;
	-- external signals for buttons and knob
	btn: in buttons;
	knob: in knobSigs;
	-- outputs intended for internal use
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

-- debounced buttons
signal dbb, dbb_prev: buttons;

signal reset: std_logic;	-- debounced btn(0)

-- outputs from knob interface
signal tick, clockwise: std_logic;
signal delta: word;

-- data bits controlled by knob
signal bits : word;
begin
	-- debounce the buttons	and knob
	db1: debouncer generic map(width => 4) port map(clk, btn, dbb);
	
	-- define dBtn output signals and reset
	dBtn <= dbb(3 downto 1);
	reset <= dbb(0); resetOut <= reset;
	
	ki: knobIntf port map(clk, reset, knob, tick, clockwise, delta);

	-- define pulse and data bits
	process (clk) begin
		if rising_edge(clk) then
			dbb_prev <= dbb;
			if reset = '1' then
				bits <= (others => '0');
			elsif tick = '1' then
				if  clockwise = '1' then bits <= bits + delta;
				else			 bits <= bits - delta;
				end if;
			end if;
		end if;
	end process;
	pulse <= dbb(3 downto 1) and (not dbb_prev(3 downto 1));
	inBits <= bits;
end a1;

