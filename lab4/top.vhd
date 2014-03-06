---------------------------------------------------------------------
-- Top module for fifteenPuzzle circuit on prototype board
-- your name
--
-- Your documentation here
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.commonDefs.all;

entity top is port(
   clk: in std_logic;
   -- S3 board buttons, knob, switches and LEDs
   btn: in buttons;
   knob: in knobSigs;
   swt: in switches;
   lcd: out lcdSigs;
   led: out leds;
   -- signals for controlling VGA display 
   hSync, vSync: out std_logic;
   dispVal: out pixel);
end top;

architecture a1 of top is

-- TODO

begin      
   -- TODO
   -- Instantiate and connect the sub-components, fifteenPuzzle,
   -- binaryInMod and outMod
   -- Connect the low-order two bits from binaryInMod to the moveDir
   -- input of fifteenPuzzle
   -- Use pulse(1) for the nuPuzzle input, pulse(2) for the moveIt input
   -- Connect puzlTime and bestTime from fifteenPuzzle to outMod
   -- Connect the switches to peekPos, connect peekVal to led(3..0)
   -- and connect emptyPos to led(7..4)
end a1;
