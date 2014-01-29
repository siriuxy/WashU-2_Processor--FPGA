-- Standalone testbench for garage door opener
-- Jon Turner, 10/2011
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.commonDefs.all;
 
ENTITY testOpener IS
END testOpener;
 
ARCHITECTURE behavior OF testOpener IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT opener
    PORT(
         clk : IN  std_logic;
         reset : IN  std_logic;
         openClose : IN  std_logic;
         obstruction : IN  std_logic;
         atTop : IN  std_logic;
         atBot : IN  std_logic;
         goUp : OUT  std_logic;
         goDown : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal reset : std_logic := '0';
   signal openClose, obstruction, atTop, atBot: std_logic;

 	--Outputs
   signal goUp : std_logic;
   signal goDown : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
	constant pause : time := 3*clk_period;
	
	signal inputs: std_logic_vector(3 downto 0) := "0000";
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: opener PORT MAP (
          clk => clk,
          reset => reset,
          openClose => openClose,
          obstruction => obstruction,
          atTop => atTop,
          atBot => atBot,
          goUp => goUp,
          goDown => goDown
        );

   -- Clock process definitions
   process begin
		clk <= '0'; wait for clk_period/2;
		clk <= '1'; wait for clk_period/2;
   end process;
 
	openClose <= inputs(3); obstruction <= inputs(2);
	atTop <= inputs(1); atBot <= inputs(0);
	
	process begin	
		wait for 200 ns;
		reset <= '1'; inputs <= "0010"; wait for pause; reset <= '0'; wait for pause;
		
		-- first do a "normal" close/open cycle
		inputs <= "1000"; wait for clk_period; inputs <= "0000"; wait for clk_period;
		inputs <= "0001"; wait for clk_period; inputs <= "0000"; wait for clk_period;
		inputs <= "1000"; wait for clk_period; inputs <= "0000"; wait for clk_period;
		inputs <= "0010"; wait for clk_period; inputs <= "0000"; wait for pause;
		
		-- now check out the typical pause cases, and obstruction-detected
		inputs <= "1000"; wait for clk_period; inputs <= "0000"; wait for clk_period;
		inputs <= "1000"; wait for clk_period; inputs <= "0000"; wait for clk_period;
		inputs <= "1000"; wait for clk_period; inputs <= "0000"; wait for clk_period;
		inputs <= "1000"; wait for clk_period; inputs <= "0000"; wait for clk_period;
		inputs <= "1000"; wait for clk_period; inputs <= "0000"; wait for clk_period;
		inputs <= "0100"; wait for clk_period; inputs <= "0000"; wait for clk_period;
		-- and return to the opened state
		inputs <= "0010"; wait for clk_period; inputs <= "0000"; wait for pause;
		
		-- now verify all the atypical cases in the close/open cycle
		inputs <= "1001"; wait for clk_period; inputs <= "0000"; wait for clk_period;
		inputs <= "0011"; wait for clk_period; inputs <= "0000"; wait for clk_period;
		inputs <= "1001"; wait for clk_period; inputs <= "0000"; wait for clk_period;
		inputs <= "0011"; wait for clk_period; inputs <= "0000"; wait for pause;
		
		inputs <= "1010"; wait for clk_period; inputs <= "0000"; wait for clk_period;
		inputs <= "0001"; wait for clk_period; inputs <= "0000"; wait for clk_period;
		inputs <= "1010"; wait for clk_period; inputs <= "0000"; wait for clk_period;
		inputs <= "0110"; wait for clk_period; inputs <= "0000"; wait for pause;
		
		inputs <= "1011"; wait for clk_period; inputs <= "0000"; wait for clk_period;
		inputs <= "0001"; wait for clk_period; inputs <= "0000"; wait for clk_period;
		inputs <= "1011"; wait for clk_period; inputs <= "0000"; wait for clk_period;
		inputs <= "0111"; wait for clk_period; inputs <= "0000"; wait for pause;
			
		inputs <= "1000"; wait for clk_period; inputs <= "0000"; wait for clk_period;
		inputs <= "0001"; wait for clk_period; inputs <= "0000"; wait for clk_period;
		inputs <= "1100"; wait for clk_period; inputs <= "0000"; wait for clk_period;
		inputs <= "0010"; wait for clk_period; inputs <= "0000"; wait for pause;
		
		inputs <= "1000"; wait for clk_period; inputs <= "0000"; wait for clk_period;
		inputs <= "0001"; wait for clk_period; inputs <= "0000"; wait for clk_period;
		inputs <= "1101"; wait for clk_period; inputs <= "0000"; wait for clk_period;
		inputs <= "0010"; wait for clk_period; inputs <= "0000"; wait for pause;
		
		inputs <= "1000"; wait for clk_period; inputs <= "0000"; wait for clk_period;
		inputs <= "0001"; wait for clk_period; inputs <= "0000"; wait for clk_period;
		inputs <= "1110"; wait for clk_period; inputs <= "0000"; wait for clk_period;
		inputs <= "0010"; wait for clk_period; inputs <= "0000"; wait for pause;
		
		inputs <= "1000"; wait for clk_period; inputs <= "0000"; wait for clk_period;
		inputs <= "0001"; wait for clk_period; inputs <= "0000"; wait for clk_period;
		inputs <= "1111"; wait for clk_period; inputs <= "0000"; wait for clk_period;
		inputs <= "0010"; wait for clk_period; inputs <= "0000"; wait for pause;
																											
		-- now verify all the atypical cases for pause and obstruction detected
		
		-- now verify all the self-loops
		
		-- now verify all the transitions from reset
		
		assert false report "simulation ended normally" severity failure;
   end process;

END;
