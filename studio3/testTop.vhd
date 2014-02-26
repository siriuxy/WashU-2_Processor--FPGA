--------------------------------------------------------------------------------
-- Testbench for the top circuit.
-- Jon Turner, 2/2014
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.commonDefs.all;
 
entity testTop is
end testTop;
 
architecture a1 of testTop is 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    component top port(
         clk : IN  std_logic;
         btn : IN  std_logic_vector(3 downto 0);
         knob : IN  std_logic_vector(2 downto 0);
         swt : IN  std_logic_vector(3 downto 0);
         led : OUT  std_logic_vector(7 downto 0);
         lcd : OUT  lcdSigs
        );
    end component;
    

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
   uut: top port map (clk, btn, knob, swt, led, lcd);

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
				press <= '1'; wait for pause; press <= '0'; wait for pause;
			end loop;
		end;

		-- push the reset button
		procedure reset is
		begin
			btn(0) <= '1'; wait for pause; btn(0) <= '0'; wait for pause;
		end;
		
		-- enqueue a value
		procedure enq(x: integer) is begin 
			if x > inVal then rrot(x - inVal);
			elsif x < inVal then lrot(inVal - x);
			end if;
			inVal <= x;
			btn(3) <= '1'; wait for pause; btn(3) <= '0'; wait for pause;
		end;
		
		-- dequeue from front of queue
		procedure deq is begin 
			-- TODO
		end;
		
		-- simultaneous enqueue/dequeue
		procedure edq(x: integer) is begin 
			-- TODO
		end;		

	begin		
		wait for 100 ns; reset;

		-- TODO - verify that queue is empty

		-- enq until queue is full     
		for i in 1 to 8 loop 
			-- TODO - verify that queue is not full
			enq(i); 
			-- TODO - verify that queue is not empty
		end loop;

		-- TODO - verify that queue is full
		
		-- attempt to enq again
		enq(9);
		
		-- and simultaneous enq/deq
		edq(10);
		
		-- deq until queue is empty
		for i in 2 to 8 loop
			-- TODO - verify that queue is not empty
			deq; 
			-- TODO - verify that queue is not full
		end loop;
		
		deq; 
		
		-- attempt to deq again
		deq;
		
		-- attempt to do simultaneous enq/deq again
		edq(13);

      assert (false) report "normal termination" severity failure;
   end process;
end;
