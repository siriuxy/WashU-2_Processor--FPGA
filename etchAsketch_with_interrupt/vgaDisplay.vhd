-------------------------------------------------------------------
-- vgaDisplay
-- Jon Turner - 6/2010
--
-- Uses the S3 chip's block RAM to define 4K words of memory (8K bytes).
-- This memory appears as page F in the S3 processors address space.
-- The values in the display buffer are sent to the outputs that
-- control the VGA display.
--
-- Because we have too little memory for a full 640x480 VGA display,
-- each memory pixel corresponds to a 4x4 block of display pixels.
-- The array of memory pixels is 160x120, with each 16 bit word
-- holding five 3 bit values. So, we have 32 words per row and
-- 120 rows.
--
-- This version of vgaDisplay is intended for use with the WashU-2.
-- In this context, the interface address is 16 bits and the top
-- four bits are xF when the processor is accessing the dispaly buffer.
---------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use work.commonDefs.all;

entity vgaDisplay is port (
	clk, reset: in std_logic;
	en, rw: in std_logic;
	addr: in address;
	data: inout word;
	hSync, vSync: out std_logic;
	dispVal: out std_logic_vector(2 downto 0));
end vgaDisplay;

architecture a1 of vgaDisplay is

constant dbSize: integer := 4096; -- number of words in memory
type dbType is array(0 to dbSize-1) of word;
signal dBuf: dbType := (
	others       => x"0000"
);
subtype dbAdr is std_logic_vector(11 downto 0);

signal hCnt, vCnt: std_logic_vector(11 downto 0);
signal pixel, dPixel:std_logic_vector(5 downto 0);
type stateType is (syncState, frontPorch, displayRegion, backPorch);
signal hState, vState: stateType;

signal dbufOut,  dispWord: word;
signal dbufAddr, dispAddr: dbAdr;
signal active, doRead: std_logic;

-- registers for tracking writes
signal lastAdr: address;
signal lastData: word;

begin
   -- generate display timing signals
	process (clk) begin
		if rising_edge(clk) then
			if reset = '1' then
				vState <= syncState; hState <= syncState;
				hCnt <= (others => '0'); vCnt <= (others => '0');
				dispAddr <= (others => '0'); pixel <= (others => '0');
			else
				-- generate horizontal timing signals
				hCnt <= hCnt + 1;
				if hCnt = x"0bf" then hState <= backPorch; end if;
				if hCnt = x"12f" then hState <= displayRegion; end if;
				if hCnt = x"62f" then hState <= frontPorch; end if;				
				if hCnt = x"63f" then hState <= syncState;				
					hcnt <= x"000";
					-- generate vertical timing signals
					vCnt <= vCnt + 1;
					if vCnt = x"001" then vState <= backPorch; end if;
					if vCnt = x"022" then vState <= displayRegion; end if;
					if vCnt = x"202" then vState <= frontPorch; end if;
					if vCnt = x"209" then vState <= syncState;
						vCnt <= (others => '0');
					end if;
				end if;
				
				-- generate dispAdr and pixel
				if vState = syncState then 
					dispAddr <= (others => '0');
				end if;
				if hState = backPorch then
					pixel <= (others => '0');
				end if;
				if hState = displayRegion and vState = displayRegion then
					pixel <= pixel + 1;
					if pixel = o"47" then
						dispAddr <= dispAddr + 1; pixel <= (others => '0');
					end if;
				end if;
				-- backup dispAddr at end of 3 out of 4 horizontal lines
				if vState = displayRegion and hCnt = x"63f" then
					if vCnt(1 downto 0) /= "10" then
						dispAddr <= dispAddr - x"020";
					end if;
				end if;
			end if;
		end if;
	end process;
	
	hSync <= '0' when hState = syncState else '1';
	vSync <= '0' when vState = syncState else '1';
	
	-- active is high for accesses to display buffer
	active <= '1' when en = '1' and addr(15 downto 12) = x"F" 
					  else '0';
	dbufAddr <= addr(11 downto 0) when active = '1' else dispAddr;
	
	-- memory process
	process (clk) begin
		if rising_edge(clk) then		
			if active = '1' and rw = '0' then
				dBuf(int(dbufAddr)) <= data;
				dbufOut <= (others => '0');
				lastAdr <= addr; -- update debugging registers
				lastData <= data;
			else
				dbufOut <= dBuf(int(dbufAddr));
			end if;
			-- control signal for client-side read
			if active = '1' and rw = '1' then doRead <= '1';
												  else doRead <= '0';
			end if;
			dPixel <= pixel; -- delayed version of pixel for use in dispVal
		end if;
	end process;
	data <= dbufOut when doRead = '1' else (others => 'Z');
	
	dispWord <= dbufOut when vState = displayRegion and hState = displayRegion
	            else (others => '0');
					
	dispVal <= 	dispWord(14 downto 12) when dPixel(5 downto 3)="000" else
					dispWord(11 downto  9) when dPixel(5 downto 3)="001" else
					dispWord( 8 downto  6) when dPixel(5 downto 3)="010" else
					dispWord( 5 downto  3) when dPixel(5 downto 3)="011" else
					dispWord( 2 downto  0);		
end a1;