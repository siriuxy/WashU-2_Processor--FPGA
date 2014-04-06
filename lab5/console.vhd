----------------------------------------------------------------------------------
-- Console for WashU2
-- Jon Turner - 5/2010 
--
-- This module allows the user to interact with the processor using the
-- buttons, switches and knob on the S3 board. It also displays the
-- CPU register and the console's snoop registers on the lcd display.
--
-- The north button (btn(0)) acts as a reset button for the processor,
-- restarting execution from location 0. Note, this does not re-initialize
-- memory. To do that, one can use the S3 board's program button.
--
-- The west button (btn(3) puts the processor in single step mode and once in
-- single step mode, causes it to advance by one instruction fore each press.
-- The south button (btn(2)) takes the processor out of single step mode.
--
-- The console includes a snoopAdr and snoopData register. Their values can
-- be controlled using the knob on the S3 board. If swt(3)=0, the knob controls
-- snoopAdr, otherwise it controls snoopData. Turning the knob to the right
-- increments the register, turning the knob to the left decrements it.
-- Or, one can hold the knob down to produce more rapid changes in the value.
--
-- The east button (btn(1)) is used to write the value in snoopData to
-- memory at the location specified by snoopAdr (assuming swt(3)=1).
-- When swt(3)=0, snoopData contains the value in the memory at the
-- location specified by snoopAdr.
--
---------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;
use work.commonDefs.all;

entity console is port(
    clk: in std_logic;
    
    -- inputs and outputs
    btn: in buttons;
    knob: in knobSigs;
    swt: in switches;
    
    resetOut: out std_logic;
    pause : out std_logic;    -- pause CPU

    -- memory signals
    memEnIn, memRwIn: in std_logic;
    memEnOut, memRwOut: out std_logic;
    aBus: out word;
    dBus: inout word;
    
    -- signals for observing on CPU registers
    regSelect: out std_logic_vector(1 downto 0);
    cpuReg: in word;
    
    -- signals for controlling LCD display
    lcd: out lcdSigs);
end console;

architecture a1 of console is

component debouncer
    generic(width: integer := 8);
    port(    clk: in std_logic;
            din: in std_logic_vector(width-1 downto 0);
            dout: out std_logic_vector(width-1 downto 0));
end component;

component knobIntf port(
    clk, reset: in std_logic;
    knob: in knobSigs;                 -- knob signals
    tick: out std_logic;                -- high for each knob transition
    clockwise: out std_logic;        -- high for clockwise rotation
    delta: out word);                  -- add/subtract amount
end component;

component lcdDisplay port(
    clk, reset : in std_logic;
    -- internal interface for controlling display
    update: in std_logic;                           -- update a stored value
    selekt: in std_logic_vector(4 downto 0);        -- character to replace
    nuChar: in std_logic_vector(7 downto 0);        -- new character value
    -- connections to external pins
    lcd: out lcdSigs);
end component;

signal dBtn, prevDBtn: buttons;
signal reset: std_logic;
signal tick, clockwise : std_logic;
signal delta: word;

-- single step control signal
signal singleStep: std_logic;

-- local signals for controlling memory
signal memEn, memRw: std_logic;

-- signals for controlling snooping
signal snoopAdr, snoopData: word;
signal snoopCnt: std_logic_vector(6*operationMode + 9 downto 0);
signal snoopTime, writeReq: std_logic;

-- 0 means out, 1 means in
signal snoopMode: std_logic; 

-- signals for controlling lcdDisplay
constant CNTR_LENGTH: integer := 8 + operationMode*12;
signal lcdCounter: std_logic_vector(CNTR_LENGTH-1 downto 0);
signal lowBits: std_logic_vector(CNTR_LENGTH-6 downto 0);

signal update: std_logic;
signal selekt: std_logic_vector(4 downto 0);
signal nuChar: std_logic_vector(7 downto 0);

type hex2asciiMap is array(0 to 15) of character; 
constant hex2ascii: hex2asciiMap :=
    ( 0 => '0',  1 => '1',  2 => '2',  3 => '3',  4 => '4', 
      5 => '5',  6 => '6',  7 => '7',  8 => '8',  9 => '9',
     10 => 'a', 11 => 'b', 12 => 'c', 13 => 'd', 14 => 'e', 15 => 'f');
begin
    snoopMode <= swt(3);
    reset <= dBtn(0);    resetOut <= reset;
    
    -- connect all the sub-components
    db: debouncer generic map(width => 4) port map(clk, btn, dBtn);    
    kint: knobIntf port map(clk, reset, knob, tick, clockwise, delta);
    disp: lcdDisplay port map(clk, reset, update, selekt, nuchar, lcd);    

    pause <= singleStep or snoopTime;
    
    -- process for controlling single step operation
    process(clk) begin
        if rising_edge(clk) then
            prevDBtn <= dBtn;
            if reset = '1' then
                singleStep <= '0';
            else
                if dBtn(3) > prevDBtn(3) then
                    singleStep <= not singleStep;
                elsif dBtn(3) = '1' then
                    singleStep <= '1';
                elsif dBtn(2) > prevDBtn(2) then
                    singleStep <= '0';
                end if;
            end if;
        end if;
    end process;
    
    memEnOut <= memEnIn or memEn;
    memRwOut <= memRwIn and memRw;
    
    snoopTime <= '1' when snoopCnt(snoopCnt'high downto 4) =
                                    (snoopCnt'high downto 4 => '1')
                    else '0';
    
    -- process controlling memory signals for snooping
    process (snoopTime, snoopCnt, snoopData, snoopAdr) begin
        memEn <= '0'; memRw <= '1';
        aBus <= (others => 'Z'); dBus <= (others => 'Z');
        if snoopTime = '1' then 
            -- allow time for in-progress instruction to complete
            if snoopCnt(3 downto 0) = x"c" then
                memEn <= '1'; aBus <= snoopAdr;
            elsif writeReq = '1' and snoopCnt(3 downto 0) = x"f" then
                memEn <= '1'; memRw <= '0';
                aBus <= snoopAdr; dBus <= snoopData;
            end if;
        end if;
    end process;

    -- process that controls snoop registers and writeReq
    process(clk) begin
        if rising_edge(clk) then
            if reset = '1' then
                snoopAdr <= (others => '0'); snoopData <= (others => '0');
                writeReq <= '0';
                snoopCnt <= (others => '0');            
            else
                snoopCnt <= snoopCnt + 1;
                -- generate writeReq signal in response to button push
                if dBtn(1) > prevDBtn(1) and snoopMode = '1' then
                    writeReq <= '1';
                end if;
                if writeReq = '1' and snoopTime = '1'
                   and snoopCnt(3 downto 0) = x"f" then
                    writeReq <= '0';
                end if;
                -- load snoopData at end of snoopTime period
                if snoopTime = '1' and snoopMode = '0' then
                    if snoopCnt(3 downto 0) = x"d" then
                        snoopData <= dBus;
                    end if;
                end if;
                -- update snoopAdr or snoopData in response to knob signals
                if tick = '1' then
                    if snoopMode = '0' then
                        if clockwise = '1' then snoopAdr <= snoopAdr + delta;
                        else snoopAdr <= snoopAdr - delta;
                        end if;
                    else
                        if clockwise = '1' then snoopData <= snoopData + delta;
                        else snoopData <= snoopData - delta;
                        end if;
                    end if;
                end if;                    
            end if;
        end if;
    end process;

    -- update LCD display to show cpu registers and snoop registers
    -- first row:  ireg acc snoopAdr
    -- second row:  pc  iar snoopData    
    lowBits <= lcdCounter(CNTR_LENGTH-6 downto 0);
    update <= '1' when lowBits = (lowBits'range => '0') else '0';
    selekt <= lcdCounter(CNTR_LENGTH-1 downto CNTR_LENGTH-5);
    
    regSelect <=     "00" when selekt <= slv(4,5) else
                        "10" when selekt <= slv(10,5) else
                        "01" when selekt <= slv(20,5) else
                        "11";
    
    process (cpuReg, snoopAdr, snoopData, selekt) begin
        case selekt is
        -- high nibble of processor registers
        when "00000" | "00110" | "10000" | "10110" => 
            nuChar <= c2b(hex2Ascii(int(cpuReg(15 downto 12))));
        -- second nibble of processor registers
        when "00001" | "00111" | "10001" | "10111" =>
            nuChar <= c2b(hex2Ascii(int(cpuReg(11 downto 8))));
        -- third nibble of processor registers
        when "00010" | "01000" | "10010" | "11000" => 
            nuChar <= c2b(hex2Ascii(int(cpuReg(7 downto 4))));
        -- low nibble of processor registers
        when "00011" | "01001" | "10011" | "11001" =>
            nuChar <= c2b(hex2Ascii(int(cpuReg(3 downto 0))));
            
        -- nibbles of snoopAdr register
        when "01100" => nuChar <= c2b(hex2Ascii(int(snoopAdr(15 downto 12))));
        when "01101" => nuChar <= c2b(hex2Ascii(int(snoopAdr(11 downto 8))));
        when "01110" => nuChar <= c2b(hex2Ascii(int(snoopAdr(7 downto 4))));
        when "01111" => nuChar <= c2b(hex2Ascii(int(snoopAdr(3 downto 0))));
        
        -- nibbles of snoopAdr registe
        when "11100" => nuChar <= c2b(hex2Ascii(int(snoopData(15 downto 12))));
        when "11101" => nuChar <= c2b(hex2Ascii(int(snoopData(11 downto 8))));
        when "11110" => nuChar <= c2b(hex2Ascii(int(snoopData(7 downto 4))));
        when "11111" => nuChar <= c2b(hex2Ascii(int(snoopData(3 downto 0))));
            
        when others => nuChar <= c2b(' ');  -- spaces everywhere else
        end case;
    end process;
        
    -- process to increment lcdCounter
    process(clk) begin
        if rising_edge(clk) then
            if reset = '1' then lcdCounter <= (others => '0');
            else lcdCounter <= lcdCounter + 1;                    
            end if;
        end if;
    end process;
end a1;
