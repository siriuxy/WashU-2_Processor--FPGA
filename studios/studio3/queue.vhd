--------------------------------------------------------------------------------
-- Queue module
-- Jon Turner, 2008
--
-- Simple memory-based queue with enq and deq operations. 
-- Supports simultaneous enq and deq.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use work.commonDefs.all;

entity queue is
	generic(
		qSiz: integer := 16; --original val 16
		lgSiz: integer := 4;
		wordSiz: integer := 16);
	port( 
		clk, reset: in std_logic;
		enq, deq : in std_logic;	-- control signals
		dataIn : in std_logic_vector(wordSiz-1 downto 0); -- value to be enqueued
		dataOut : out std_logic_vector(wordSiz-1 downto 0); -- first word in the queue
		empty, full : out std_logic);	-- status signals
end queue;

architecture a1 of queue is
-- array to store values
type qStoreTyp is array(0 to qSiz-1) of std_logic_vector(wordSiz-1 downto 0);
signal qStore: qStoreTyp;

-- read/write pointers and counter
signal readPntr, writePntr: std_logic_vector(lgSiz-1 downto 0);
signal count: std_logic_vector(lgSiz downto 0);

begin
	process (clk) begin
		if rising_edge(clk) then
			if reset = '1' then
				readPntr <= (others => '0');
				writePntr <= (others => '0'); 
				count <= (others => '0');
			else
				-- simultaneous enq/deq, if empty, just enq
				if enq = '1' and deq = '1' then
					if count = 0 then
						qStore(int(writePntr)) <= dataIn;
						writePntr <= writePntr + 1; count <= count + 1;
					else 
						qStore(int(writePntr)) <= dataIn;
						readPntr <= readPntr + 1; writePntr <= writePntr + 1;
					end if;
				-- enqueue  if not full
				elsif enq = '1' and count < qSiz then
					qStore(int(writePntr)) <= dataIn;
					writePntr <= writePntr + 1; count <= count + 1;
				-- dequeue if not empty
				elsif deq = '1' and count > 0 then			
					readPntr <= readPntr + 1; count <= count - 1;
				end if;
			end if;
		end if;
	end process;
	dataOut <= qStore(int(readPntr)); -- value at front, when not empty
	empty <= '1' when count = 0 else '0';
	full <= '1' when count = qSiz else '0';
end a1;
