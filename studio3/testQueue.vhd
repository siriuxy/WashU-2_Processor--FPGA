--------------------------------------------------------------------------------
-- Testbench for queue
-- Jon Turner, 2/2014
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.txt_util.all;
use work.commonDefs.all;

entity testQueue is end testQueue; 
architecture a1 of testQueue is 
 
component queue
	generic(
		qSiz: integer := 16;
		lgSiz: integer := 4;
		wordSiz: integer := 16);
	port( 
		clk, reset: in std_logic;
		enq, deq : in std_logic;		-- control signals
		dataIn : in std_logic_vector(wordSiz-1 downto 0);					-- value to be enqueued
		dataOut : out std_logic_vector(wordSiz-1 downto 0);				-- first word in the queue
		empty, full : out std_logic);	-- status signals
end component;

constant queueLen: integer := 8;
constant lgLen: integer := 3;
constant theWordSiz: integer := 16;

signal clk, resetSig : std_logic := '0';
signal enqSig, deqSig : std_logic := '0';
signal inbits: std_logic_vector(theWordSiz-1 downto 0) := (others => '0');

signal empty, full: std_logic;
signal outbits: std_logic_vector(theWordSiz-1 downto 0);

-- Clock period definitions
constant clk_period : time := 20 ns;
constant pause: time := 5*clk_period;
 
begin
	uut: queue generic map(queueLen,lgLen,theWordSiz) 
				  port map(clk,resetSig,enqSig,deqSig,inBits,outBits,empty,full);

  process begin
		clk <= '0'; wait for clk_period/2;
		clk <= '1'; wait for clk_period/2;
   end process;
	
	process
	-- reset the queue
	procedure reset is begin
		resetSig <= '1'; wait for pause; resetSig <= '0'; wait for pause;
	end;

	-- enqueue a new value at the end of the queue
	procedure enq(inval: integer) is begin 
		inBits <= slv(inval,theWordSiz);
		enqSig <= '1'; wait for clk_period; enqSig <= '0'; wait for pause; 
	end;
	
	-- dequeue the item at the front of the queue
	procedure deq is begin 
		-- TODO
	end;
	
	-- do simultaneous enqueue and dequeue operations
	procedure edq(inval: integer) is begin 
		-- TODO
	end;
	begin		
      wait for 100 ns;	
		
		reset;
		
		assert empty = '1' report "empty signal low when queue is empty";

		-- enq until queue is full     
		for i in 1 to 8 loop 
			assert full = '0' report "full signal high when queue is not full";
			enq(i); 
			assert int(outbits) = 1 report "incorrect front value when adding to queue, i=" & str(outbits);
			assert empty = '0' report "empty signal high when queue is not empty";
		end loop;
		
		-- TODO - check that full is high
		
		-- attempt to enq again
		enq(9);
		-- TODO - check front value
		
		-- and simultaneous enq/deq
		edq(10);
		assert int(outbits) = 2 report "incorrect front value " & str(outbits);
		
		-- deq until queue is empty
		for i in 2 to 8 loop
			-- TODO - check that queue is not empty
			-- TODO - check that front value is correct
			deq; 
			-- TODO - check that queue is not full
		end loop;
		
		assert int(outbits) = 10 report "incorrect front value when emptying" & str(outbits);
		deq; 
		
		assert empty = '1' report "empty signal low when queue is empty";
		
		-- attempt to deq again
		deq;
		assert empty = '1' report "empty signal low when queue is empty";
		assert full = '0' report "full signal high when queue is not full";
		
		-- attempt to do simultaneous enq/deq again
		edq(13);
		assert empty = '0' report "empty signal high when queue is not empty";
		assert full = '0' report "full signal high when queue is not full";

      assert false report "normal termination" severity failure;
   end process;  
end;
