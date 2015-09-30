--------------------------------------------------------
-- De-bounce the push buttons.
-- Jon Turner - 1/2008
--
-- This circuit produces a debounced version of the 
-- S3 board's push buttons. It does this by ignoring
-- all changes to btn that are not stable for at least
-- 2^20 clock ticks (about 20 ms with a 50 MHz clock).
--------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use work.commonDefs.all;

entity debouncer is 
	generic (width: integer := 8);
	port(	clk: in std_logic;
			din: in std_logic_vector(width-1 downto 0);
			dout: out std_logic_vector(width-1 downto 0));
end debouncer;

architecture a1 of debouncer is
signal prevDin: std_logic_vector(width-1 downto 0);
-- in commonDefs,
-- for simulation, set operationMode = 0 to make count 2 bits long
-- for synthesis,  set operationMode = 0 to make count 16 bits long
constant debounceBits: integer := 2 + operationMode*14;
signal count: std_logic_vector(debounceBits-1 downto 0);
begin
	process(clk) begin
		if rising_edge(clk) then
			prevDin <= din;
			if prevDin /= din then count <= (others => '1');
			elsif count /= (count'range => '0') then count <= count - 1;
			else dout <= din;
			end if;
		end if;
	end process; 
end a1;
