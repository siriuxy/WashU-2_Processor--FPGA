-------------------------------------------------------------------
-- simpleVga
-- Jon Turner - 2/2014
---------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use work.commonDefs.all;

entity vgaDisplay is port (
	clk, reset: in std_logic;
	-- client-side interface
	en, rw: in std_logic;
	addr: in dbAdr;
	data: inout pixel;
	-- video outputs
	hSync, vSync: out std_logic;
	dispPix: out pixel);
end vgaDisplay;

architecture a1 of vgaDisplay is
type dbType is array(0 to 240*320) of pixel;
signal dBuf: dbType := (others => o"0");
signal dispAddr: dbAdr;
signal dispData: pixel;

-- signals and constants for generating video timing
type stateType is (syncState, frontPorch, displayRegion, backPorch);
signal hState, vState: stateType;

-- horizontal clock tick counter, vertical line counter
subtype hIndex is unsigned(10 downto 0);
subtype vIndex is unsigned( 9 downto 0);
signal tick: hIndex; signal line: vIndex;

-- Constants defining horizontal timing, in 50 MHz clock ticks
constant hSyncWidth: hIndex := to_unsigned( 192,tick'length);
constant hBpWidth:   hIndex := to_unsigned(  96,tick'length);
constant hDispWidth: hIndex := to_unsigned(1280,tick'length);
constant hFpWidth:   hIndex := to_unsigned( 32,tick'length);

-- Constants defining vertical timing, in horizontal lines
constant vsyncWidth: vIndex := to_unsigned(  2,line'length);
constant vBpWidth:   vIndex := to_unsigned( 33,line'length);
constant vDispWidth: vIndex := to_unsigned(480,line'length);
constant vFpWidth:   vIndex := to_unsigned( 10,line'length);

begin			  
	-- display buffer process - dual port memory
	process (clk) begin
		if rising_edge(clk) then
			data <= (others => 'Z');
			if en = '1' then
				if rw = '0' then
					dBuf(int(addr)) <= data;
				else
					data <= dBuf(int(addr));
				end if;
			end if;
			dispData <= dBuf(int(dispAddr));
		end if;	
	end process;
	dispPix <= dispData when vState = displayRegion and hState = displayRegion
				  else (others => '0');

   -- generate display timing signals and display address
	process (clk) begin
		if rising_edge(clk) then
			if reset = '1' then
				vState <= syncState; hState <= syncState;
				tick <= (others => '0'); line <= (others => '0');
				dispAddr <= (others => '0');
			else
				-- generate horizontal timing signals
				tick <= tick + 1;
				case hState is
				when syncState =>
					if tick = hSyncWidth-1 then 
						hState <= backPorch; tick <= (others => '0');						
					end if;
				when backPorch =>
					if tick = hBpWidth-1 then 
						hState <= displayRegion; tick <= (others => '0');
					end if;
				when displayRegion =>					
					if tick = hDispWidth-1 then 
						hState <= frontPorch; tick <= (others => '0');
					end if;
					if vState = displayRegion then
						if tick(1 downto 0) = "11" then
							-- advance dispAddr every four clock ticks in display region
							dispAddr <= dispAddr + 1;
						end if;
						if tick = hDispWidth-1 and line(0) = '0' then 
							-- backup dispAdr at the end of even-numbered lines
							dispAddr <= dispAddr - to_unsigned(319,dispAddr'length);
						end if;
					end if;
				when frontPorch =>
					if tick = hFpWidth-1 then 
						hState <= syncState; tick <= (others => '0');
						-- generate vertical timing signals at end of line
						line <= line + 1;
						case vState is
						when syncState =>						
							dispAddr <= (others => '0');
							if line = vSyncWidth-1 then 
								vState <= backPorch; line <= (others => '0');
							end if;					
						when backPorch =>
							if line = vBpWidth-1 then 
								vState <= displayRegion; line <= (others => '0');
							end if;
						when displayRegion =>
							if line = vDispWidth-1 then 
								vState <= frontPorch; line <= (others => '0');
							end if;
						when frontPorch =>
							if line = vFpWidth-1 then 
								vState <= syncState; line <= (others => '0');
							end if;
						end case;
						end if;
					end case;			
			end if;
		end if;
	end process;
	hSync <= '0' when hState = syncState else '1';
	vSync <= '0' when vState = syncState else '1';
end a1;