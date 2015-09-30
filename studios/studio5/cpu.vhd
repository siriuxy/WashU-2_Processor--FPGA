------------------------------------------------------------------------
-- CPU module
-- Jon Turner - 5/2010
--
-- Repeatedly fetches and executes instructions from memory.
--
-- The regSelect input selects one of the four registers and
-- puts its value on the dispReg output.
--
--     if regSelect=0, dispReg = ireg
--     if regSelect=1, dispReg = pc
--     if regSelect=2, dispReg = acc
--     if regSelect=3, dispReg = iar
--
-- The pause signal is used to pause the processor for single step
-- operation. If pause is high at the end of an instruction execution,
-- the processor waits for it to go low before proceeding to the
-- next instruction fetch.
--
--------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.commonDefs.all;

entity cpu is port (
        clk, reset: in  std_logic;
        -- memory signals
        en, rw: out std_logic;        
        aBus: out address; dBus: inout word;
        -- console interface signals
        pause : in std_logic;
        regSelect: in std_logic_vector(1 downto 0);
        dispReg: out word);
end cpu;

architecture cpuArch of cpu is
type state_type is (
            resetState, pauseState, fetch,
            halt, negate,
            branch, brZero, brPos, brNeg, brInd,
            cLoad, dLoad, iLoad,
            dStore, iStore,         
            add, andd
);

signal state: state_type;
signal tick: std_logic_vector(3 downto 0);

signal pc:         address; -- program counter

signal iReg:     word;     -- instruction register
signal iar:     address; -- indirect address register
signal acc:     word;     -- accumulator
signal alu:     word;     -- alu output

-- address of the instruction being executed
signal this:     address; 
-- address for direct load, store, add, andd, ...
signal opAdr: address;
-- target for branch instruction
signal target: word;

begin
    opAdr <= this(15 downto 12) & ireg(11 downto 0); 
    target <= this + ((15 downto  8 => ireg(7)) & ireg( 7 downto 0));
    
    -- connect selected register to console
    with regSelect select
        dispReg <= iReg  when "00",
                 this  when "01",
          acc   when "10",
          iar   when others;

    -- select alu operation based on state
    alu <=     (not acc) + x"0001"        when state = negate else
                acc + dbus                when state = add    else
                acc and dbus            when state = andd   else
                (alu'range => '0'); 

    -- synchronous process controlling state, tick and registers
    process (clk)

    function decode(instr: word) return state_type is begin
        -- Instruction decoding.
        case instr(15 downto 12) is
        when x"0" =>
            case instr(11 downto 8) is
            when x"0" =>
                if instr(11 downto 0) = x"00" then 
                    return halt;
                elsif instr(11 downto 0) = x"01" then 
                    return negate;
                else
                    return halt;
                end if;
            when x"1" =>     return branch;
            when x"2" =>     return brZero;    
            when x"3" =>     return brPos;
            when x"4" =>     return brNeg;
            when x"5" =>     return brInd;
            end case;
        when x"1" =>     return cLoad;
        when x"2" =>     return dLoad;
        when x"3" =>     return iLoad;
        when x"5" =>     return dStore;
        when x"6" =>     return iStore;
        when x"8" =>     return add;
        when x"c" =>     return andd;
        when others => return halt; 
        end case;
    end function decode;
  
    procedure wrapup is begin
        -- Do this at end of every instruction
        if pause = '1' then
            state <= pauseState;
        else
            state <= fetch; tick <= x"0";
        end if;
    end procedure wrapup;
 
    begin
          if rising_edge(clk) then
              if reset = '1' then 
                state <= resetState; tick <= x"0";
                pc <= (others => '0');   this <= (others => '0');
                iReg <= (others => '0'); acc <= (others => '0'); 
            else
                tick <= tick + 1; -- advance time by default
                if state = resetState then
                    state <= fetch; tick <= x"0";
                elsif state = pauseState then
                    if pause = '0' then
                        state <= fetch; tick <= x"0";
                    end if;
                elsif state = fetch then
                    if tick = x"1" then                                
                        iReg <= dBus; this <= pc;
                    elsif tick = x"2" then
                        state <= decode(iReg);
                        pc <= pc + 1; tick <= x"0"; 
                    end if;
                else
                    case state is            
                    -- branch instructions
                    when branch => 
                        pc <= target; wrapup;
                    when brZero => 
                        if acc = x"0000" then 
                            pc <= target;    
                        end if;
                        wrapup;
                    when brPos => 
                        if acc(15) = '0' and acc /= x"0000" then 
                            pc <= target;
                        end if;
                        wrapup;
                    when brNeg => 
                        if acc(15) = '1' then 
                            pc <= target;    
                        end if;
                        wrapup;
                    when brInd => 
                        if tick = x"1" then pc <= dBus; wrapup; end if;

                    -- load instructions
                    when cload => 
                        acc <= (15 downto 12 => ireg(11)) & ireg(11 downto 0);
                        wrapup;
                    when dload =>
                        if tick = x"1" then acc <= dBus; wrapup; end if;
                    when iload =>
                        if tick = x"1" then iar <= dBus;
                        elsif tick = x"3" then acc <= dBus; wrapup;
                        end if;

                    -- store instructions                  
                    when dstore => wrapup;
                    when istore =>
                        if tick = x"1" then iar <= dBus;
                        elsif tick = x"2" then wrapup;
                        end if;

                    -- arithmetic and logic instructions
                    when negate =>    acc <= alu; wrapup;
                    when add | andd =>
                        if tick = x"1" then acc <= alu; wrapup; end if;
                        
                    when others => state <= halt;
                    end case;
                end if;
            end if;
          end if;
    end process;
    
    process (ireg,pc,iar,acc,this,opAdr,state,tick) begin
        -- Memory control section (combinational)
        -- default values for memory control signals
        en <= '0'; rw <= '1';
        aBus <= (others => 'Z'); dBus <= (others => 'Z');
        case state is
        when fetch =>  if tick = x"0" then
                                en <= '1'; aBus <= pc;
                            end if;                                                    
        when brInd => 
            if tick = x"0" then
                en <= '1'; aBus <= target;
            end if;
        when dLoad | add | andd => 
            if tick = x"0" then
                en <= '1'; aBus <= opAdr;
            end if;
        when iLoad => 
            if tick = x"0" then
                en <= '1'; aBus <= opAdr;
            elsif tick = x"2" then
                en <= '1'; aBus <= iar;
            end if;                        
        when dStore =>
            if tick = x"0" then 
                en <= '1'; rw <= '0';
                aBus <= opAdr; dBus <= acc;
            end if;            
        when iStore => 
            if tick = x"0" then
                en <= '1'; aBus <= opAdr;
            elsif tick = x"2" then
                en <= '1'; rw <= '0';
                aBus <= iar; dBus <= acc;
            end if;
        when others => 
        end case;
    end process;
end cpuArch;
