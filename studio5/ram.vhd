-------------------------------------------------------------------
-- RAM module
--
-- Uses the S3 chip's block RAM to define 8K words of memory (16K bytes).
-- The outer module combines the block RAM's separate data inputs
-- and outputs into a single data bus.
--
-- The outer module also ignores memory reads for locations
-- x0ff0 through x0fff, since this range of addresses is handled
-- used by the IO unit.
---------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all; 
use work.commonDefs.all;

entity ram is port (
  clk, en, rw: in STD_LOGIC;
  aBus: in address;
  dBus: inout word);
end ram;

architecture ramArch of ram is

signal addr: std_logic_vector(13 downto 0);

constant ramSize: integer := 16384; -- number of words in memory
type ramType is array(0 to ramSize-1) of word;
signal ramm: ramType := (

	-- paste Assembler output here

	others => x"0000"
);

-- monitoring registers to aid in simulation
signal i, j, p : word;

begin	
	addr <= aBus(13 downto 0);
	process (clk) begin
		if rising_edge(clk) then
			dBus <= (others => 'Z');
			if en = '1' and aBus(15 downto 14) = "00" then
				if rw = '0' then
					ramm(int(addr)) <= dBus;
					-- update monitoring registers for simulation
					if addr = "00" & x"0f0" then i <= dBus; end if;
					if addr = "00" & x"0f1" then j <= dBus; end if;
					if addr = "00" & x"0f2" then p <= dBus; end if;
				else
					dBus <= ramm(int(addr));
				end if;
			end if;
		end if;
	end process;		
end ramArch;

