--------------------------------------------------------------------------------
-- Testbench for the top circuit.
-- Jon Turner, 2/2014
--------------------------------------------------------------------------------
LIBRARY ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.commonDefs.all;
 
 
ENTITY testTop IS
END testTop;
 
ARCHITECTURE behavior OF testTop IS 
 
	 -- Component Declaration for the Unit Under Test (UUT)
 
	 COMPONENT top
	 PORT(
			clk : IN  std_logic;
			btn : IN  std_logic_vector(3 downto 0);
			knob : IN  std_logic_vector(2 downto 0);
			swt : IN  std_logic_vector(3 downto 0);
			led : OUT  std_logic_vector(7 downto 0);
			lcd : OUT  lcdSigs
		  );
	 END COMPONENT;
	 

	--Inputs
	signal clk : std_logic := '0';
	signal btn : std_logic_vector(3 downto 0) := (others => '0');
	signal knob : std_logic_vector(2 downto 0) := (others => '0');
	signal swt : std_logic_vector(3 downto 0) := (others => '0');

 	--Outputs
	signal led : std_logic_vector(7 downto 0);
	signal lcd : lcdSigs;

	-- Clock period definitions
	constant clk_period : time := 20 ns;
	constant pause : time := 5*clk_period;
	
	signal rot: std_logic_vector(1 downto 0) := "00";
	signal press: std_logic := '0';
	
	signal inVal : integer := 0;
 
begin
	knob(0) <= press; knob(2 downto 1) <= rot;
	
	-- Instantiate the Unit Under Test (UUT)
	uut: top PORT MAP (clk, btn, knob, swt, led, lcd);

	-- Clock process definitions
	clk_process :process
	begin
		clk <= '0'; wait for clk_period/2;
		clk <= '1'; wait for clk_period/2;
	end process;

	-- Stimulus process
	stim_proc: process		
		-- rotate the knob to the left cnt times
		procedure lrot(cnt: in integer) is
		begin
			for i in 1 to cnt loop
				rot <= "01"; wait for pause; rot <= "11"; wait for pause;
				rot <= "10"; wait for pause; rot <= "00"; wait for pause;
			end loop;
		end;

		-- rotate the knob to the right cnt times
		procedure rrot(cnt: in integer) is
		begin
			for i in 1 to cnt loop
				rot <= "10"; wait for pause; rot <= "11"; wait for pause;
				rot <= "01"; wait for pause; rot <= "00"; wait for pause;
			end loop;
		end;

		-- push the knob button cnt times
		procedure bump(cnt: in integer) is
		begin
			for i in 1 to cnt loop
				press <= '1'; wait for pause;
				press <= '0'; wait for pause;
			end loop;
		end;

		-- push the reset button
		procedure reset is
		begin
			btn(0) <= '1'; wait for pause;
			btn(0) <= '0'; wait for pause;
		end;
		
		-- do single stackCalk operation using a numeric operation code
		procedure do(operation: integer; x: integer) is begin
			swt <= slv(operation,4); 
			if	 x > inVal then rrot(x - inVal);
			elsif x < inVal then lrot(inVal - x);
			end if;
			inVal <= x;
			btn(1) <= '1'; wait for pause;
			btn(1) <= '0'; wait for pause;
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
		-- hold reset state for 100 ns.
		wait for 100 ns; reset;

		-- push until stack is full
		for i in 1 to 7 loop 
			push(i);		
		end loop;
		
		-- attempt to push again
		push(8);
		
		-- pop until the stack is empty, and attempt to pop again
		for i in 7 downto 1 loop 
			pop; 
		end loop;
		
		-- attempt to pop again
		pop;

		-- fill it up again
		for i in 1 to 7 loop push(i); end loop;
		
		-- and do some arithmetic operations
		add2; sub2;
		add(13); sub(13);
		add2; sub2; add2; sub2;	 
		
		-- these should be ignored
		add2; sub2;
		
		clearTop;

		clearStak;
		
		push(1); add(2);
		
		wait for 20 ms;

		assert (false) report "normal termination" severity failure;
	end process;
end;
