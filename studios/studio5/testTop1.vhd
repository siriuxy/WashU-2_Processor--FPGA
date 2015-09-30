--------------------------------------------------------------------------------
-- Testbench for WashU-2 processor.
-- This version just resets it and waits while a program executes.
--
-- Jon Turner - 5/2010
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;
use work.commonDefs.all;
 
entity testTop1 is
end testTop1;
 
architecture a1 of testTop1 is 
 
-- Component Declaration for the Unit Under Test (UUT)

component top
port(
	clk : in  std_logic;
	btn : in  buttons;
	knob: in  knobsigs;
	swt : in  switches;
	led : out  leds;
	lcd : out  lcdsigs
  );
end component;
 
--Inputs
signal clk : std_logic := '0';
signal btn : buttons := (others => '0');
signal knob: knobSigs := (others => '0');
signal swt : switches := (others => '0');

signal rot: std_logic_vector(1 downto 0) := "00";
signal press: std_logic := '0';

--Outputs
signal led : std_logic_vector(7 downto 0);
signal lcd: lcdSigs;

-- Clock period definitions
constant clk_period : time := 20 ns;
constant pause: time := 5*clk_period;
 
begin
   knob(2 downto 1) <= rot;
	knob(0) <= press;
 
	-- Instantiate the Unit Under Test (UUT)
   uut: top port map (clk, btn, knob, swt, led, lcd);

   -- Clock process definitions
   process begin
		clk <= '0'; wait for clk_period/2;
		clk <= '1'; wait for clk_period/2;
   end process;
 
   process 
		-- push the reset button
		procedure reset is begin
			btn(0) <= '1'; wait for pause; btn(0) <= '0'; wait for pause;
		end;
	begin		
		wait for 100 ns;
      
		reset;
		
		wait for 10 ms;

      assert (false) report "Simulation ended normally." severity failure;
   end process;
end;
