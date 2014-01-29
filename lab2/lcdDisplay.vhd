----------------------------------------------------------------------------------
-- LCD Display Controller for S3 board
-- Jon Turner, 5/2010
-- 
-- Implements a simple interface that a circuit can use to control the 
-- display and uses the control signals to the external device to update it.
-- The internal interface includes an update signal which causes one
-- of the display locations to be updated, whenever it is asserted. The
-- display location to be updated is specified by the selekt input,
-- and the new character to be written at that location is specified
-- by the nuChar input. The character locations are numbered 0-15 in
-- the top row and 16-31 in the bottom row (left-to-right).
--
--	The circuit maintains an internal character buffer where characters
-- are stored, and it periodically sends a character to the display
-- from this buffer, cycling through all the characters in the buffer
-- approximately once every 42 ms.
--
-- On power-up, the internal buffer is initialized with space characters.
-- However, it is not cleared again following a reset. It's up to the
-- "client circuit" to initialize the display. This choice was made to
-- avoid forcing the client to wiat for an auto-initialization process
-- to complete.
--
--	The input data and the result are both 16 bit values.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use work.commonDefs.all;

entity lcdDisplay is port(
	clk, reset : in std_logic;
	-- internal interface for controlling display
	update: in std_logic;								-- update a stored value
	selekt: in std_logic_vector(4 downto 0);		-- character to replace
	nuChar: in std_logic_vector(7 downto 0);		-- new character value
	-- connections to external pins
	lcd: out lcdSigs);
end lcdDisplay;

architecture a1 of lcdDisplay is
type char_buf is array(0 to 31) of std_logic_vector(7 downto 0);
signal cb: char_buf := (others => x"20"); -- initialize with spaces
type stateType is (init, normal);
signal state: stateType;
signal tick: std_logic_vector(23 downto 0); -- counter for controlling timing
signal nextChar: std_logic_vector(4 downto 0); -- selects char from cb
signal en, rs: std_logic;
signal data: std_logic_vector(3 downto 0);
begin
	lcd <= (en, rs, '0', '1', data); -- write only, disable intel strataflash
	
	process(clk) begin  -- update character buffer when update is asserted
		if rising_edge(clk) then
			if reset = '0' and update = '1' then
				cb(int(selekt)) <= nuChar;
			end if;
		end if;
	end process;
	
	process(clk) begin	-- periodically send a character from cb to display
		if rising_edge(clk) then
			tick <= tick + 1; -- increment tick whenever reset is low
			if reset = '1' then
				en <= '0'; rs <= '0'; 
				nextChar <= (others => '0'); data <= (others => '0');
				tick <= (others => '0');
				state <= init;
				en <= '0';
			elsif state = init then
				case tick is -- update external display
				-- initialization sequence for display
				when x"100000" => rs <= '0'; data <= x"3";
				when x"100003" => en <= '1';
				when x"100010" => en <= '0';
				when x"200000" => data <= x"3";
				when x"200003" => en <= '1';
				when x"200010" => en <= '0';
				when x"202000" => data <= x"3";
				when x"202003" => en <= '1';
				when x"202010" => en <= '0';
				when x"203000" => data <= x"3";
				when x"203003" => en <= '1';
				when x"203010" => en <= '0';
				when x"204000" => data <= x"2";
				when x"204003" => en <= '1';
				when x"204010" => en <= '0';
				-- function set command	
				when x"205000" => data <= x"2";
				when x"205003" => en <= '1';
				when x"205010" => en <= '0';	
				when x"205100" => data <= x"8";
				when x"205103" => en <= '1';
				when x"205110" => en <= '0';
				-- entry mode set command	
				when x"206000" => data <= x"0";
				when x"206003" => en <= '1';
				when x"206010" => en <= '0';	
				when x"206100" => data <= x"6";
				when x"206103" => en <= '1';
				when x"206110" => en <= '0';
				-- display on, no cursor, no blink 	
				when x"207000" => data <= x"0";
				when x"207003" => en <= '1';
				when x"207010" => en <= '0';	
				when x"207100" => data <= x"c";
				when x"207103" => en <= '1';
				when x"207110" => en <= '0';
				-- clear display 	
				when x"208000" => data <= x"0";
				when x"208003" => en <= '1';
				when x"208010" => en <= '0';	
				when x"208100" => data <= x"c";
				when x"208103" => en <= '1';
				when x"208110" => en <= '0';
				-- and wait to start normal operation
				when x"21ffff" => state <= normal;
				when others => -- nothing
				end case;
			else 
				-- send a character every 2^16 ticks (about every 1.3 us)
				-- first send upper nibble of address, then lower nibble
				-- then send upper nibble of character, then lower nibble
				case tick(15 downto 0) is
				when x"0000" => rs <= '0';
									 data <= '1' & nextChar(4) & "00";
				when x"0003" => en <= '1';
				when x"0010" => en <= '0';
				when x"0100" => data <= nextChar(3 downto 0);
				when x"0103" => en <= '1';
				when x"0110" => en <= '0';
				when x"1000" => rs <= '1'; data <= cb(int(nextChar))(7 downto 4);
				when x"1003" => en <= '1';
				when x"1010" => en <= '0';
				when x"1100" => data <= cb(int(nextChar))(3 downto 0);
				when x"1103" => en <= '1';
				when x"1110" => en <= '0'; nextChar <= nextChar + 1;
				when others => -- nothing					
				end case;
			end if;
		end if;
	end process;
end a1;
