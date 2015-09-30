--------------------------------------------------------------------------------
-- testbench for calculator on s3 board
--------------------------------------------------------------------------------
LIBRARY ieee;
use ieee.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
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
	
	signal reset, clear, load, add, press: std_logic;
	signal rot: std_logic_vector(1 downto 0);
 
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
 
	btn(0) <= reset; btn(1) <= clear;
	btn(2) <= load; btn(3) <= add;
	
	knob(2 downto 1) <= rot;
	knob(0) <= press;
	
	swt <= "0000";

	-- Stimulus process
	process begin		

		reset <= '0'; clear <= '0'; load <= '0'; 
		add <= '0'; press <= '0'; rot <= "00";
		wait for pause;
		
		reset <= '1'; wait for pause; reset <= '0'; wait for pause;
		
		-- turn knob clockwise one full rotation
		rot <= "10"; wait for pause; rot <= "11"; wait for pause;
		rot <= "01"; wait for pause; rot <= "00"; wait for pause;
		
		-- load calculator, then add a few times
		load <= '1'; wait for pause; load <= '0'; wait for pause;		
		add <= '1'; wait for pause; add <= '0'; wait for pause;
		add <= '1'; wait for pause; add <= '0'; wait for pause;

		-- press down on knob, then rotate it again
		press <= '1'; wait for pause; press <= '0'; wait for pause;
		rot <= "10"; wait for pause; rot <= "11"; wait for pause;
		rot <= "01"; wait for pause; rot <= "00"; wait for pause;
		
		-- another add, then, clear
		add <= '1'; wait for pause; add <= '0'; wait for pause;
		clear <= '1'; wait for pause; clear <= '0'; wait for pause;

		assert false report "simulation ended normally"
		severity failure;
	end process;
END;
