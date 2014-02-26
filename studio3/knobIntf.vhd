--------------------------------------------------------
-- Knob Interface
-- Jon Turner - 5/1010
--
-- This circuit converts signals from the knob to a more
-- convenient form. The output signal tick goes high for
-- one clock tick every time the knob makes a complete
-- rotation. The clockwise output signal is high when the 
-- knob is being turned in the clockwise direction,
-- otherwise it is 0.
--
-- The delta output is controlled by the knob button.
-- It starts at 1 and each button press causes it to
-- increase by a factor of 16. If a button press would
-- make it zero, it becomes 1 again. This is useful when
-- using the knob to control a numeric value.
--
-- This circuit includes an internal debouncer for the
-- knob signals.
---------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use work.commonDefs.all;

entity knobIntf is port(
	clk, reset: in std_logic;
	knob: in knobSigs; 				-- knob signals
	tick: out std_logic;				-- high for each knob transition
	clockwise: out std_logic;		-- high for clockwise rotation
	delta: out word);  				-- amount to add/subtract per tick
end knobIntf;

architecture a1 of knobIntf is
component debouncer 
	generic (width: integer := 8);
	port(
	clk: in std_logic;
	dIn: in std_logic_vector(width-1 downto 0);
	dOut: out std_logic_vector(width-1 downto 0)
	);
end component;

signal dbKnob: knobSigs;
signal rot, prevRot: std_logic_vector(1 downto 0);	
signal btn, prevBtn: std_logic;
signal diff : std_logic_vector(15 downto 0);
begin
	-- debounce the knob signals and separate the rotational signals
	-- from the button press
	db: debouncer generic map(width => 3) port map(clk, knob, dbKnob);
	rot <= dbKnob(2 downto 1); btn <= dbKnob(0);
	
	delta <= diff; -- use internal signal diff to generate output, delta
	process(clk) begin
		if rising_edge(clk) then
			prevRot <= rot; prevBtn <= btn; tick <= '0';
			if reset = '1' then
				diff <= (0 => '1', others => '0');
				clockwise <= '1';
			else
				if prevRot = "00" and rot = "01" then
					tick <= '1'; clockwise <= '0'; 
				end if;
				if prevRot = "10" and rot = "11" then
					tick <= '1'; clockwise <= '1';
				end if;
				
				if btn > prevBtn then
					diff <= diff(11 downto 0) & diff(15 downto 12);
				end if;
			end if;	
		end if;
	end process;
end a1;