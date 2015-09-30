--------------------------------------------------------------------------------
-- testbench for garage dooor opener circuit on prototype board
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use ieee.std_logic_unsigned.ALL;
use work.commonDefs.all;
 
ENTITY testTop IS
END testTop;
 
ARCHITECTURE behavior OF testTop IS 
 
-- Component Declaration for the Unit Under Test (UUT)

component top port(
	clk: in std_logic;
	-- S3 board buttons, knob, switches and LEDs
	btn: in buttons;
	knob: in knobSigs;
	swt: in switches;
   	led: out leds;
	-- signals for controlling LCD display 
	lcd: out lcdSigs);
end component;

--Inputs
signal clk : std_logic := '0';
signal btn : buttons := (others => '0');
signal knob : knobSigs := (others => '0');
signal swt : switches := (others => '0');

 --Outputs
signal led : leds;
signal lcd : lcdSigs;

-- Clock period definitions
constant clk_period : time := 20 ns;
constant pause: time := 5*clk_period;

-- convenience signals
signal rot: std_logic_vector(1 downto 0);
signal press: std_logic;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
	uut: top PORT MAP (
		  clk => clk,
		  btn => btn,
		  knob => knob,
		  swt => swt,
		  led => led,
		  lcd => lcd
		);

   	-- Clock process definitions
   	process begin
		clk <= '0'; wait for clk_period/2;
		clk <= '1'; wait for clk_period/2;
   	end process;
	
	knob(2 downto 1) <= rot;
	knob(0) <= press;
 
   	-- Stimulus process
   	process

	-- rotate the knob to the right cnt times
	procedure rrot(cnt: in integer) is
	begin
		for i in 1 to cnt loop
			rot <="10"; wait for pause; rot <= "11"; wait for pause;
			rot <="01"; wait for pause; rot <= "00"; wait for pause;
		end loop;
	end;
	
	-- rotate the knob to the left cnt times
	procedure lrot(cnt: in integer) is
	begin
		for i in 1 to cnt loop
			rot <="01"; wait for pause; rot <= "11"; wait for pause;
			rot <="10"; wait for pause; rot <= "00"; wait for pause;
		end loop;
	end;
	
	-- push the reset button
	procedure reset is
	begin
		btn(0) <= '1'; wait for pause; btn(0) <= '0'; wait for pause;
	end;

	-- push btn(2) in order to activate the state machine
	procedure doit is
	begin
		btn(2) <= '1'; wait for pause; btn(2) <= '0'; wait for pause;
	end;
	
	begin		
  		wait for 100 ns;
		
		rot <= "00"; press <= '0'; wait for pause;
		
		reset; 
	
		rrot(8); doit;  -- 8
		lrot(6); doit;	-- 2
		rrot(6); doit;  -- 8
		lrot(7); doit;  -- 1
		rrot(7); doit;  -- 8

	 	assert (false) report "simulation ended normally"
		severity failure;
	end process;
end;
