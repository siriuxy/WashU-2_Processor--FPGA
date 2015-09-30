--------------------------------------------------------------------------------
-- Testbench for top level circuit
-- Jon Turner - 5/2010
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;
use work.commonDefs.all;
 
ENTITY testTop2 IS
END testTop2;
 
ARCHITECTURE a1 OF testTop2 IS 
 
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
 
BEGIN
   knob(2 downto 1) <= rot;
	knob(0) <= press;
 
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
 
   process 
		-- rotate the knob to the left cnt times
		procedure lrot(cnt: in integer) is
			begin
			for i in 1 to cnt loop
				rot <= "01"; wait for pause; rot <= "11"; wait for pause;
				rot <= "10"; wait for pause; rot <= "00"; wait for pause;
				wait for 50 us; -- allow time for write to happen
			end loop;
		end;

		-- rotate the knob to the right cnt times
		procedure rrot(cnt: in integer) is
		begin
			for i in 1 to cnt loop
				rot <= "10"; wait for pause; rot <= "11"; wait for pause;
				rot <= "01"; wait for pause; rot <= "00"; wait for pause;
				wait for 50 us; -- allow time for write to happen
			end loop;
		end;

		-- push the knob button cnt times
		procedure bump(cnt: in integer) is begin
			for i in 1 to cnt loop
				press <= '1'; wait for pause; press <= '0'; wait for pause;
			end loop;
		end;

		-- push the reset button
		procedure reset is begin
			btn(0) <= '1'; wait for pause; btn(0) <= '0'; wait for pause;
		end;
		
	begin		
		wait for 100 ns;
      
		reset;
		
		wait for 10 us;

      -- set snoopAdr = x3f0		
		bump(1); rrot(15); bump(1); rrot(3); bump(2);
		
		-- set snoopData to (x,y)=(64,32) and save in M[x340]
		swt(3) <= '1';
		bump(1); rrot(4); bump(2); rrot(2); bump(1);
		btn(1) <= '1'; wait for pause; btn(1) <= '0'; wait for 20 us;
		
		swt(2) <= '1';  -- switch to continuous updating

      -- draw a square
		bump(2); rrot(50); bump(2); rrot(50); 
		bump(2); lrot(50);  bump(2); lrot(50);
		
		wait for 20 ms; -- allow time for vga display to update

      assert (false) report "Simulation ended normally." severity failure;
   end process;

END;
