library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.txt_util.all;
use work.commonDefs.all;

entity testStack is end testStack; 
architecture a1 of testStack is 
 
component stack 
	generic(
		stakSiz: integer :=  8;
		lgSiz:   integer :=  3;
		wordSiz: integer := 16);
	port(
		clk, reset: in std_logic;	
		push, pop: in std_logic;
		dIn: in std_logic_vector(wordSiz-1 downto 0);
		top: out std_logic_vector(wordSiz-1 downto 0);
		full, empty: out std_logic);
end component;

signal clk, reset : std_logic := '0';
signal push, pop : std_logic := '0';
signal inbits: word := (others => '0');

signal empty, full: std_logic;
signal outbits: word;

-- Clock period definitions
constant clk_period : time := 20 ns;
constant pause: time := 5*clk_period;
 
begin
	uut: stack generic map(8,3,wordSize) 
		   port map(clk,reset,push,pop,inBits,outBits,full,empty);

	process begin
		clk <= '0'; wait for clk_period/2;
		clk <= '1'; wait for clk_period/2;
	end process;
	
	process
	-- TODO - define helper functions/procedures here
	begin		
		wait for 100 ns;	

		-- TODO - add tests here

      		assert false report "normal termination" severity failure;
	end process;  
end;
