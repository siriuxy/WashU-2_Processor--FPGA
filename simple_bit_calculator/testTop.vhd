--------------------------------------------------------------------------------
-- testbench for calculator on s3 board
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
	signal press: std_logic := '0';

 	--Outputs
   signal led : std_logic_vector(7 downto 0);
   signal lcd : lcdSigs;

   -- Clock period definitions
   constant clk_period : time := 20 ns;
	
	constant pause : time := 5*clk_period;
	
	signal rot: std_logic_vector(1 downto 0) := (others => '0');
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: top PORT MAP (
          clk => clk, btn => btn, knob => knob,
          swt => swt, led => led, lcd => lcd
        );

   -- Clock process definitions
   process begin
		clk <= '0'; wait for clk_period/2;
		clk <= '1'; wait for clk_period/2;
   end process;
	
	knob(2 downto 1) <= rot;
	knob(0) <= press;
	
	swt(3 downto 1) <= "000";

   -- Stimulus process
	process
		procedure lrot(cnt: in integer) is
		begin
			for i in 1 to cnt loop
				rot <= "10"; wait for pause; rot <= "11"; wait for pause;
				rot <= "01"; wait for pause; rot <= "00"; wait for pause;
			end loop;
		end;

		-- rotate the knob to the left cnt times
		procedure rrot(cnt: in integer) is
		begin
			for i in 1 to cnt loop
				rot <= "01"; wait for pause; rot <= "11"; wait for pause;
				rot <= "10"; wait for pause; rot <= "00"; wait for pause;
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
		
		-- push the clear button for the calculator
		procedure clear is
		begin
				 btn(1) <= '1'; wait for pause; btn(1) <= '0'; wait for pause;
		end;
		
		-- push the load button for the calculator
		procedure load is
		begin
				 btn(2) <= '1'; wait for pause; btn(2) <= '0'; wait for pause;
		end;
		
		-- push the add button for the calculator
		procedure add is
		begin
				 btn(3) <= '1'; wait for pause; btn(3) <= '0'; wait for pause;
		end;
		
	begin
 
		rot <= "00";
		wait for pause;
		
		reset;	
		wait for 11 ms;
		swt(0) <= '0';
		
		lrot(1); load; rrot(2); add; load; add; 
		clear; add; add; add;
		
		swt(0) <= '1';
		
		clear; lrot(1); bump(3); rrot(8); bump(1); lrot(1); load;
		rrot(1); bump(3); lrot(8); bump(1); rrot(1); add; load; add;
		clear; add; add; lrot(2); add; add; add; add; add;

      assert false report "simulation ended normally" severity failure;
   end process;

END;
