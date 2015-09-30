--------------------------------------------------------------------------------
-- Testbench for stackCalk
-- Jon Turner, 2/2014
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.txt_util.all;
use work.commonDefs.all;
entity testStakCalc is end testStakCalc;
 
architecture a1 of testStakCalc is 
 
component stackCalc 
	generic(
		stakSiz: integer :=  8;
		lgSiz:	integer :=  3;
		wordSiz: integer := 16);
	port(
		clk, reset: in std_logic;	
		op: in nibble;
		doOp: in std_logic;
		dIn: in std_logic_vector(wordSiz-1 downto 0);
		result: out std_logic_vector(wordSiz-1 downto 0));
end component;

signal clk, reset : std_logic := '0';
signal op : nibble := (others => '0');
signal doOp : std_logic := '0';
signal inbits: word := (others => '0');

signal outbits: word;

-- Clock period definitions
constant clk_period : time := 20 ns;
constant pause: time := 5*clk_period;
 
BEGIN
	uut: stackCalc generic map(8,3,wordSize) 
			port map(clk,reset,op,doOp,inBits,outBits);

  	process begin
		clk <= '0'; wait for clk_period/2;
		clk <= '1'; wait for clk_period/2;
	end process;
	
	process

	-- reset the circuit
	procedure restart is begin
		reset <= '1'; wait for pause; reset <= '0';
	end;
	
	-- do a single stackCalk operation using a numeric operation code
	procedure do(operation: integer; inval: integer) is begin
		op <= slv(operation,4); inbits <= slv(inval,wordSize); 
		doOp <= '1'; wait for clk_period; doOp <= '0'; wait for pause;
	end;

	-- clear the item on the top of the stack
	procedure clearTop is begin do(0,0); end;
	-- clear the entire stack
	procedure clearStak is begin do(1,0); end;
	-- pop the top value off the stack
	procedure pop  is begin do(2,0); end;
	-- push a value onto the stack
	procedure push(inval: integer) is begin do(3,inval); end;
	-- add to the top stack value
	procedure add(inval: integer) is begin do(4,inval); end;
	-- add the top two stack values together
	procedure add2 is begin do(5,0); end;
	-- subtract from the top stack value
	procedure sub(inval: integer) is begin do(6,inval); end;
	-- subtract the top two stack values
	procedure sub2 is begin do(7,0); end;

	begin		
		wait for 100 ns;	

		restart;
		-- push until stack is full
		for i in 1 to 7 loop 
			push(i);
			assert int(outbits) = i report "incorrect stack top when pushing, i=" & str(i);			
		end loop;
		
		-- attempt to push again
		push(8);
		assert int(outbits) = 7 report "incorrect stack top " & str(outbits);
		
		-- pop until the stack is empty, and attempt to pop again
		for i in 7 downto 1 loop 
			assert int(outbits) = i report "incorrect stack top when popping, i=" & str(i);
			pop; 
		end loop;
		
		-- attempt to pop again
		pop;

		-- fill it up again
		for i in 1 to 7 loop push(i); end loop;
		
		-- and do some arithmetic operations
		add2;	 assert int(outbits) = 13 report "incorrect result, i=" & str(outbits);
		sub2;	 assert int(outbits) =  8 report "incorrect result, i=" & str(outbits);
		add(13); assert int(outbits) = 21 report "incorrect result, i=" & str(outbits);
		sub(13); assert int(outbits) =  8 report "incorrect result, i=" & str(outbits);
		add2;	 assert int(outbits) = 12 report "incorrect result, i=" & str(outbits);
		sub2;	 assert int(outbits) =  9 report "incorrect result, i=" & str(outbits);
		add2;	 assert int(outbits) = 11 report "incorrect result, i=" & str(outbits);
		sub2;	 assert int(outbits) = 10 report "incorrect result, i=" & str(outbits);
		
		-- these should be ignored
		add2;	 assert int(outbits) = 10 report "incorrect result, i=" & str(outbits);
		sub2;	  assert int(outbits) = 10 report "incorrect result, i=" & str(outbits);
		
		clearTop; assert int(outbits) = 0 report "incorrect result, i=" & str(outbits);

		clearStak;

		assert false report "normal termination" severity failure;
	end process;
end;
