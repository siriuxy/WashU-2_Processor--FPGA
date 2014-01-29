----------------------------------------------------------------------------------
-- Controller for a Garage Door Opener
-- Jon Turner, 11/2011
--
-- This circuit implements a controller for a garage door opener.
-- It has four input signals.
--
--		open/close - which comes from remote control
--		obstruction detected - comes from a sensor
--		at top - from contact at the top of the door
--		at bottom - from contact at the bottom or the door
--
-- It generated three mutually exclusive output signals.
--
--		move door up
--		move door down
--		stop door
--
-- If an open/close signal is detected when the door is moving,
-- it stops where it is. The next open/close causes it to move
-- in the reverse direction.
--
--	The circuit also has a strobe input. The other inputs are
-- ignored whenever the strobe input is low. This facilitates
-- experimental verification on the S3 board, allowing inputs
-- to be controlled with the knob, while state changes only
-- occur when the strobe button is pressed.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.commonDefs.all;

entity opener is port (
	clk, reset: in std_logic;
	openClose: in std_logic;		-- signal to open or close door
	obstruction: in std_logic;		-- obstruction detected
	atTop: in std_logic;				-- door at the top (fully open)
	atBot: in std_logic;				-- door at the bottom (fully closed)
	goUp: out std_logic;					-- raise door
	goDown: out std_logic);				-- lower door
end opener;

architecture a1 of opener is
type stateType is (opened, closed, opening, closing,
					    pauseUp, pauseDown, resetState);
signal state:stateType;
begin
	process (clk) begin
		if rising_edge(clk) then
			if reset = '1' then
				state <= resetState;
			elsif state = resetState then
				   if atTop = '1' then state <= opened;
				elsif atBot = '1' then state <= closed;
				else state <= pauseDown;
				end if;
			else
				case state is
				when opened =>
					if openClose = '1' and obstruction = '0' then
						state <= closing;
					end if;
				when closing =>
					if openClose = '0' and obstruction = '0' and atBot = '1' then
						state <= closed;
					elsif obstruction = '1' then
						state <= opening;					
					elsif openClose = '1' then
						state <= pauseDown;
					end if;
				when closed =>
					if openClose = '1' then
						state <= opening;
					end if;
				when opening =>
					if openClose = '0' and  atTop = '1' then
						state <= opened;
					elsif openClose = '1' then
						state <= pauseUp;
					end if;
				when pauseUp =>
					if openClose = '1' and obstruction = '0' then
						state <= closing;
					end if;
				when pauseDown =>
					if openClose = '1' then
						state <= opening;
					end if;
				when others =>
				end case;
			end if;
		end if;
	end process;
	goUp   <= '1' when state = opening else '0';
	goDown <= '1' when state = closing else '0';
end a1;
