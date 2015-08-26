-- ZPU
--
-- Copyright 2004-2008 oharboe - Øyvind Harboe - oyvind.harboe@zylin.com
-- Copyright 2008 alvieboy - Álvaro Lopes - alvieboy@alvie.com
-- Copyright 2015 gatekeeper - Tiago Gasiba - tiago.gasiba@gmail.com
-- 
-- The FreeBSD license
-- 
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions
-- are met:
-- 
-- 1. Redistributions of source code must retain the above copyright
--    notice, this list of conditions and the following disclaimer.
-- 2. Redistributions in binary form must reproduce the above
--    copyright notice, this list of conditions and the following
--    disclaimer in the documentation and/or other materials
--    provided with the distribution.
-- 
-- THIS SOFTWARE IS PROVIDED BY THE ZPU PROJECT ``AS IS'' AND ANY
-- EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
-- PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
-- ZPU PROJECT OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
-- INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
-- OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
-- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
-- STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
-- ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-- 
-- The views and conclusions contained in the software and documentation
-- are those of the authors and should not be interpreted as representing
-- official policies, either expressed or implied, of the ZPU Project.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.zpu_config.all;
use work.zpupkg.all;


--###############################################################################################
--#    Signal          |  Dir  | Description
--#  ------------------+-------+--------------------------------------------------------
--#   clk              |  IN   | Clock Cycle. Max frequency determined by synthesis
--#  ------------------+-------+--------------------------------------------------------
--#   reset            |  IN   | CPU reset. Active high
--#  ------------------+-------+--------------------------------------------------------
--#   enable           |  IN   | CPU is enabled when signal is '1'
--#  ------------------+-------+--------------------------------------------------------
--#   mem_writeEnable  |  OUT  | set to '1' for a single cycle to send off a write request.
--#                    |       | mem_write is valid only while mem_writeEnable='1'.
--#  ------------------+-------+--------------------------------------------------------
--#   mem_readEnable   |  OUT  | set to '1' for a single cycle to send off a read request.
--#  ------------------+-------+--------------------------------------------------------
--#   mem_busy         |  IN   | It is illegal to send off a read/write request when mem_busy='1'.
--#                    |       | Set to '0' when mem_read  is valid after a read request. If it goes
--#                    |       | to '1'(busy), it is on the cycle after mem_read/writeEnable is '1'.
--#  ------------------+-------+--------------------------------------------------------
--#   mem_addr         |  OUT  | address for read/write request
--#  ------------------+-------+--------------------------------------------------------
--#   mem_read         |  IN   | read data. Valid only on the cycle after mem_busy='0' after 
--#                    |       | mem_readEnable='1' for a single cycle.
--#  ------------------+-------+--------------------------------------------------------
--#   mem_write        |  OUT  | data to write
--#  ------------------+-------+--------------------------------------------------------
--#   mem_writeMask    |  OUT  | set to '1' for those bits that are to be written to memory upon
--#                    |       | write request
--#  ------------------+-------+--------------------------------------------------------
--#   break            |  OUT  | set to '1' when CPU hits break instruction
--#  ------------------+-------+--------------------------------------------------------
--#   interrupt        |  IN   | set to '1' until interrupts are cleared by CPU. 
--###############################################################################################
entity zpu_core is
    port (
        clk                 : in  std_logic;
        reset               : in  std_logic;
        enable              : in  std_logic;
        in_mem_busy         : in  std_logic;
        mem_read            : in  std_logic_vector(wordSize-1 downto 0);
        mem_write           : out std_logic_vector(wordSize-1 downto 0);
        out_mem_addr        : out std_logic_vector(maxAddrBitIncIO downto 0);
        out_mem_writeEnable : out std_logic;
        out_mem_readEnable  : out std_logic;
        mem_writeMask       : out std_logic_vector(wordBytes-1 downto 0);
        interrupt           : in  std_logic;
        break               : out std_logic  );
end zpu_core;


architecture behave of zpu_core is

  type InsnType is (  Insn_AddTop,          Insn_Dup,             Insn_DupStackB,         Insn_Pop,
                      Insn_PopDown,         Insn_Add,             Insn_Or,                Insn_And,
                      Insn_Xor,             Insn_Store,           Insn_AddSP,             Insn_Shift,
                      Insn_Nop,             Insn_Im,              Insn_LoadSP,            Insn_StoreSP,
                      Insn_Emulate,         Insn_Load,            Insn_PushSP,            Insn_PopPC,
                      Insn_PopPCrel,        Insn_Not,             Insn_Flip,              Insn_PopSP,
                      Insn_Neqbranch,       Insn_Eq,              Insn_Loadb,             Insn_Mult,
                      Insn_Lessthan,        Insn_Lessthanorequal, Insn_Ulessthanorequal,  Insn_Ulessthan,
                      Insn_PushSPadd,       Insn_Call,            Insn_CallPCrel,         Insn_Sub,
                      Insn_Break,           Insn_Storeb,          Insn_InsnFetch,         Insn_AShiftLeft,
                      Insn_AShiftRight,     Insn_LShiftRight );

  type StateType is ( State_Load2,          State_Popped,         State_LoadSP2,          State_LoadSP3,
                      State_AddSP2,         State_Fetch,          State_Execute,          State_Decode,
                      State_Decode2,        State_Resync,         State_StoreSP2,         State_Resync2,
                      State_Resync3,        State_Loadb2,         State_Storeb2,          State_Mult2,
                      State_Mult3,          State_Mult5,          State_Mult4,            State_BinaryOpResult2,
                      State_BinaryOpResult, State_Idle,           State_Interrupt,        State_AShiftLeft2,
                      State_AShiftRight2,   State_LShiftRight2,   State_ShiftDone   ); 

  type InsnArray   is array(0 to wordBytes-1) of InsnType;
  type OpcodeArray is array(0 to wordBytes-1) of std_logic_vector(7 downto 0);

  signal pc                  : unsigned(maxAddrBitIncIO downto 0);           -- Program Counter
  signal sp                  : unsigned(maxAddrBitIncIO downto minAddrBit);  -- Stack Pointer
  signal incSp               : unsigned(maxAddrBitIncIO downto minAddrBit);  -- Stack Pointer + 1
  signal incIncSp            : unsigned(maxAddrBitIncIO downto minAddrBit);  -- Stack Pointer + 2
  signal decSp               : unsigned(maxAddrBitIncIO downto minAddrBit);  -- Stack Pointer - 1
  signal stackA              : unsigned(wordSize-1 downto 0);                -- cached version of mem[SP]
  signal stackB              : unsigned(wordSize-1 downto 0);                -- cached version of mem[SP+1]
  signal binaryOpResult      : unsigned(wordSize-1 downto 0);
  signal binaryOpResult2     : unsigned(wordSize-1 downto 0);
  signal multResult2         : unsigned(wordSize-1 downto 0);
  signal multResult3         : unsigned(wordSize-1 downto 0);
  signal multResult          : unsigned(wordSize-1 downto 0);
  signal multA               : unsigned(wordSize-1 downto 0);
  signal multB               : unsigned(wordSize-1 downto 0);
  signal shiftA              : unsigned(wordSize-1 downto 0);
  signal shiftB              : unsigned(wordSize-1 downto 0);
  signal shiftA_Next         : unsigned(wordSize-1 downto 0);
  signal shiftB_Next         : unsigned(wordSize-1 downto 0);
  signal idim_flag           : std_logic;
  signal busy                : std_logic;
  signal mem_writeEnable     : std_logic;
  signal mem_readEnable      : std_logic;
  signal mem_addr            : std_logic_vector(maxAddrBitIncIO downto minAddrBit);
  signal mem_delayAddr       : std_logic_vector(maxAddrBitIncIO downto minAddrBit);
  signal mem_delayReadEnable : std_logic;
  signal inInterrupt         : std_logic;
  signal decodeWord          : std_logic_vector(wordSize-1 downto 0);
  signal state               : StateType;
  signal insn                : InsnType;
  signal decodedOpcode       : InsnArray;
  signal opcode              : OpcodeArray;
  signal bytesBitsCnt        : integer;

-- Begin ZPU state machine.
begin

  -- the memory subsystem will tell us one cycle later whether or not it is busy
  out_mem_writeEnable                             <= mem_writeEnable;
  out_mem_readEnable                              <= mem_readEnable;
  out_mem_addr(maxAddrBitIncIO downto minAddrBit) <= mem_addr;
  out_mem_addr(minAddrBit-1 downto 0)             <= (others => '0');
  incSp                                           <= sp + 1;
  incIncSp                                        <= sp + 2;
  decSp                                           <= sp - 1;
  bytesBitsCnt                                    <= to_integer(pc(byteBits-1 downto 0)); -- the lower part of the PC which acts as a counter for the instruction decoder

  opcodeControl : process(clk, reset)
      variable tOpcode         : std_logic_vector(OpCode_Size-1 downto 0);
      variable spOffset        : unsigned(4 downto 0);
      variable tSpOffset       : unsigned(4 downto 0);
      variable nextPC          : unsigned(maxAddrBitIncIO downto 0);
      variable tNextInsn       : InsnType;
      variable tDecodedOpcode  : InsnArray;
      variable tMultResult     : unsigned(wordSize*2-1 downto 0);
  begin

      if reset = '1' then
           -- Asynchronous reset
          state           <= State_Idle;                                           -- initial state is Idle
          break           <= '0';                                                  -- reset break signal
          sp              <= unsigned(spStart(maxAddrBitIncIO downto minAddrBit)); -- set SP to spStart
          pc              <= (others => '0');                                      -- initialize PC to 0x00000000
          idim_flag       <= '0';                                                  -- IM instruction not being executed
          inInterrupt     <= '0';                                                  -- not processing any interrupt
          mem_writeEnable <= '0';                                                  -- not writing to memory
          mem_readEnable  <= '0';                                                  -- not reading from memory
          multA           <= (others => '0');                                      -- multipliaction result = 0
          multB           <= (others => '0');                                      -- multiplication result = 0
          mem_writeMask   <= (others => '1');                                      -- initialize writeMask to all 1's
          
      elsif rising_edge(clk) then
          -- NOTE: we must multiply unconditionally to get pipelined multiplication
          tMultResult     := multA * multB;
          multResult3     <= multResult2;
          multResult2     <= multResult;
          multResult      <= tMultResult(wordSize-1 downto 0);
          binaryOpResult2 <= binaryOpResult;  -- pipeline a bit.
          multA           <= (others => DontCareValue);
          multB           <= (others => DontCareValue);
          mem_addr        <= (others => DontCareValue);
          mem_readEnable  <= '0';
          mem_writeEnable <= '0';
          mem_write       <= (others => DontCareValue);

          if (mem_writeEnable = '1') and (mem_readEnable = '1') then
              -- if this condition happens, we halt execution until the condition clears...
              report "read/write collision" severity failure;
          else  

              spOffset(4)          := not opcode(bytesBitsCnt)(4);
              spOffset(3 downto 0) := unsigned(opcode(bytesBitsCnt)(3 downto 0));
              nextPC               := pc + 1;

              if (interrupt = '0') then
                  -- Interrupt ended, we can serve ISR again
                  inInterrupt <= '0';
              end if;

              case state is
                  --------------------------------------------------------------------------------------
                  -- STATE: IDLE
                  --------------------------------------------------------------------------------------
                  when State_Idle =>
                      if enable = '1' then
                          -- go to Resynch (main CPU state) only if CPU is enabled
                          state <= State_Resync;
                      end if;
                      
                  --------------------------------------------------------------------------------------
                  -- STATE: RESYNC
                  --------------------------------------------------------------------------------------
                  -- Initial state of ZPU, fetch top of stack + first instruction 
                  when State_Resync =>
                      if in_mem_busy = '0' then
                          mem_addr       <= std_logic_vector(sp);
                          mem_readEnable <= '1';
                          state          <= State_Resync2;
                      end if;

                  --------------------------------------------------------------------------------------
                  -- STATE: RESYNC2
                  --------------------------------------------------------------------------------------
                  -- Wait until mem_busy is LOW
                  -- load stackA with mem[SP]
                  -- fetch SP+1
                  when State_Resync2 =>
                      if in_mem_busy = '0' then
                          stackA         <= unsigned(mem_read);       -- stackA <= mem[SP]
                          mem_addr       <= std_logic_vector(incSp);
                          mem_readEnable <= '1';
                          state          <= State_Resync3;
                      end if;

                  -- Wait until mem_busy is LOW
                  -- load stackB with mem[SP+1]
                  -- fetch PC
                  -- next state: DECODE
                  when State_Resync3 =>
                      if in_mem_busy = '0' then
                          stackB         <= unsigned(mem_read);       -- stackB <= mem[SP+1]
                          mem_addr       <= std_logic_vector(pc(maxAddrBitIncIO downto minAddrBit));
                          mem_readEnable <= '1';
                          state          <= State_Decode;
                      end if;

                  --------------------------------------------------------------------------------------
                  -- STATE: DECODE
                  --------------------------------------------------------------------------------------
                  -- Wait until mem_busy is LOW
                  -- load decodeWord with mem[PC]
                  -- next state: if _interrupt_ : INTERRUPT
                  --             else           : DECODE2
                  when State_Decode =>
                      if in_mem_busy = '0' then
                          decodeWord <= mem_read;        -- decodeWord <= mem[PC]
                          state      <= State_Decode2;   -- goto DECODE2
                          -- Do not recurse into ISR while interrupt line is active
                          if interrupt = '1' and inInterrupt = '0' and idim_flag = '0' then
                              -- We got an interrupt, execute interrupt instead of next instruction
                              inInterrupt                      <= '1';                                 -- signal that we are executing interrupt
                              sp                               <= decSp;                               -- decrement SP
                              mem_writeEnable                  <= '1';                                 -- write out StackB
                              mem_addr                         <= std_logic_vector(incSp);             -- as in mem[SP+1] <= stackB
                              mem_write                        <= std_logic_vector(stackB);            --
                              stackA                           <= (others => DontCareValue);           -- 
                              stackA(maxAddrBitIncIO downto 0) <= pc;                                  -- stackA <= PC
                              stackB                           <= stackA;                              -- load stackB with stackA
                              pc                               <= to_unsigned(32, maxAddrBitIncIO+1);  -- load PC with 32h (ISR)
                              state                            <= State_Interrupt;
                          end if; -- interrupt
                      end if; -- in_mem_busy

                  --------------------------------------------------------------------------------------
                  -- STATE: INTERRUPT
                  --------------------------------------------------------------------------------------
                  -- Wait until mem_busy is LOW
                  -- NOTE: do not change inInterrupt flag
                  -- next state: DECODE
                  when State_Interrupt =>
                      if in_mem_busy = '0' then
                          mem_addr       <= std_logic_vector(pc(maxAddrBitIncIO downto minAddrBit));
                          mem_readEnable <= '1';
                          state          <= State_Decode;
                          report "ZPU jumped to interrupt!" severity note;
                      end if;

                  --------------------------------------------------------------------------------------
                  -- STATE: DECODE2
                  --------------------------------------------------------------------------------------
                  when State_Decode2 =>
                      -- NOTE:
                      --     decode 4 instructions in parallel (for 32bit processor)
                      --     decode 2 instructions in parallel (for 16bit processor)
                      --     decode 1 instructions in parallel (for  8bit processor)
                      -- 
                      -- Example (32 bit)
                      --
                      --      32222222    22211111   111111
                      --      10987654    32109876   54321098   76543210
                      --     +==========+==========+==========+==========+
                      --     | OpCode 0 | OpCode 1 | OpCode 2 | OpCode 3 |
                      --     +==========+==========+==========+==========+
                      --
                      for i in 0 to wordBytes-1 loop
                          tOpcode               := decodeWord((wordBytes-1-i+1)*8-1 downto (wordBytes-1-i)*8); -- fetch OpCode (8 bit)
                          tSpOffset(4)          := not tOpcode(4);  -- for STORESP/LOADSP/ADDSP, bit 4 is inverted
                          tSpOffset(3 downto 0) := unsigned(tOpcode(3 downto 0));
                          opcode(i)             <= tOpcode;
                          
                          if (tOpcode(7 downto 7) = OpCode_Im) then                          -- OPCODE: 1xxxxxxx (IM)
                              tNextInsn := Insn_Im;
                          elsif (tOpcode(7 downto 5) = OpCode_StoreSP) then                  -- OPCODE: 010xxxxx (STORESP)
                              if tSpOffset = 0 then
                                  tNextInsn := Insn_Pop;                                     -- OPCODE: 01010000 (POP)
                              elsif tSpOffset = 1 then
                                  tNextInsn := Insn_PopDown;                                 -- OPCODE: 01010001 (POPDOWN)
                              else
                                  tNextInsn := Insn_StoreSP;                                 -- OPCODE: other (STORESP)
                              end if;
                          elsif (tOpcode(7 downto 5) = OpCode_LoadSP) then                   -- OPCODE: 011xxxxx (LOADSP)
                              if tSpOffset = 0 then
                                  tNextInsn := Insn_Dup;                                     -- OPCODE: 01110000 (DUP)
                              elsif tSpOffset = 1 then
                                  tNextInsn := Insn_DupStackB;                               -- OPCODE: 01110001 (DUPSTACKB)
                              else
                                  tNextInsn := Insn_LoadSP;                                  -- OPCODE: other (LOADSP)
                              end if;
                          elsif (tOpcode(7 downto 5) = OpCode_Emulate) then
                              tNextInsn := Insn_Emulate;                                     -- per default emulate the instruction
                              if tOpcode(5 downto 0) = OpCode_Neqbranch then
                                  tNextInsn := Insn_Neqbranch;                               -- OPCODE: 00111000 (NEQBRANCH)
                              elsif tOpcode(5 downto 0) = OpCode_Eq then
                                  tNextInsn := Insn_Eq;                                      -- OPCODE: 00101110 (EQ)
                              elsif tOpcode(5 downto 0) = OpCode_Lessthan then
                                  tNextInsn := Insn_Lessthan;                                -- OPCODE: 00100100 (LESSTHAN)
                              elsif tOpcode(5 downto 0) = OpCode_Lessthanorequal then
                                  tNextInsn :=Insn_Lessthanorequal;                          -- OPCODE: 00100101 (LESSTHANORQEQUAL)
                              elsif tOpcode(5 downto 0) = OpCode_Ulessthan then
                                  tNextInsn := Insn_Ulessthan;                               -- OPCODE: 00100110 (ULESSTHAN)
                              elsif tOpcode(5 downto 0) = OpCode_Ulessthanorequal then
                                  tNextInsn :=Insn_Ulessthanorequal;                         -- OPCODE: 00100111 (ULESSTHANOREQUAL)
                              elsif tOpcode(5 downto 0) = OpCode_Loadb then
                                  tNextInsn := Insn_Loadb;                                   -- OPCODE: 00110011 (LOADB)
                              elsif tOpcode(5 downto 0) = OpCode_Mult then
                                  tNextInsn := Insn_Mult;                                    -- OPCODE: 00101001 (MULT)
                              elsif tOpcode(5 downto 0) = OpCode_Storeb then
                                  tNextInsn := Insn_Storeb;                                  -- OPCODE: 00110100 (STOREB)
                              elsif tOpcode(5 downto 0) = OpCode_Pushspadd then
                                  tNextInsn := Insn_PushSPadd;                               -- OPCODE: 00111101 (PUSHSPADD)
                              elsif tOpcode(5 downto 0) = OpCode_Callpcrel then
                                  tNextInsn := Insn_CallPCrel;                               -- OPCODE: 00111111 (CALLPCREL)
                              elsif tOpcode(5 downto 0) = OpCode_Call then
                                  tNextInsn :=Insn_Call;                                     -- OPCODE: 00101101 (CALL)
                              elsif tOpcode(5 downto 0) = OpCode_Sub then
                                  tNextInsn := Insn_Sub;                                     -- OPCODE: 00110001 (SUB)
                              elsif tOpcode(5 downto 0) = OpCode_PopPCRel then
                                  tNextInsn :=Insn_PopPCrel;                                 -- OPCODE: 00111001 (POPPCREL)
                              elsif tOpcode(5 downto 0) = OpCode_AShiftLeft then
                                  tNextInsn := Insn_AShiftLeft;                              -- OPCODE: 00101011 (ASHIFTLEFT)
                              elsif tOpcode(5 downto 0) = OpCode_AShiftRight then
                                  tNextInsn := Insn_AShiftRight;                             -- OPCODE: 00101100 (ASHIFTRIGHT)
                              elsif tOpcode(5 downto 0) = OpCode_LShiftRight then
                                  tNextInsn := Insn_LShiftRight;                             -- OPCODE: 00101010 (LSHIFTRIGHT)
                              elsif tOpcode(5 downto 0) = OpCode_Xor then
                                  tNextInsn := Insn_Xor;                                     -- OPCODE: 00110010 (XOR)
                              end if;
                          elsif (tOpcode(7 downto 4) = OpCode_AddSP) then
                              if tSpOffset = 0 then
                                  tNextInsn := Insn_Shift;                                   -- OPCODE: 00010000 (SHIFT)
                              elsif tSpOffset = 1 then
                                  tNextInsn := Insn_AddTop;                                  -- OPCODE: 00010001 (ADDTOP)
                              else
                                  tNextInsn := Insn_AddSP;                                   -- OPCODE: other (ADDSP)
                              end if;
                          else
                              case tOpcode(3 downto 0) is
                                  when OpCode_Nop =>
                                      tNextInsn := Insn_Nop;                                 -- OPCODE: 00001011 (NOP)
                                  when OpCode_PushSP =>
                                      tNextInsn := Insn_PushSP;                              -- OPCODE: 00000010 (PUSHSP)
                                  when OpCode_PopPC =>
                                      tNextInsn := Insn_PopPC;                               -- OPCODE: 00000100 (POPPC)
                                  when OpCode_Add =>
                                      tNextInsn := Insn_Add;                                 -- OPCODE: 00000101 (ADD)
                                  when OpCode_Or =>
                                      tNextInsn := Insn_Or;                                  -- OPCODE: 00000111 (OR)
                                  when OpCode_And =>
                                      tNextInsn := Insn_And;                                 -- OPCODE: 00000110 (AND)
                                  when OpCode_Load =>
                                      tNextInsn := Insn_Load;                                -- OPCODE: 00001000 (LOAD)
                                  when OpCode_Not =>
                                      tNextInsn := Insn_Not;                                 -- OPCODE: 00001001 (NOT)
                                  when OpCode_Flip =>
                                      tNextInsn := Insn_Flip;                                -- OPCODE: 00001010 (FLIP)
                                  when OpCode_Store =>
                                      tNextInsn := Insn_Store;                               -- OPCODE: 00001100 (STORE)
                                  when OpCode_PopSP =>
                                      tNextInsn := Insn_PopSP;                               -- OPCODE: 00001101 (POPSP)
                                  when others =>
                                      tNextInsn := Insn_Break;                               -- OPCODE: 00000000 (BREAK)
                              end case; -- tOpcode(3 downto 0)
                          end if; -- tOpcode
                          tDecodedOpcode(i) := tNextInsn;
                          
                      end loop; -- 0 to wordBytes-1

                      insn              <= tDecodedOpcode(bytesBitsCnt);
                      tDecodedOpcode(0) := Insn_InsnFetch; -- once we wrap, we need to fetch
                      decodedOpcode     <= tDecodedOpcode;
                      state             <= State_Execute;
                      shiftA            <= stackA;
                      shiftB            <= stackB;

                    
                  --------------------------------------------------------------------------------------
                  -- STATE: EXECUTE
                  -- Each instruction must:
                  --   1. set idim_flag
                  --   2. increase PC if applicable
                  --   3. set next state if appliable
                  --   4. do it's operation
                  -- Currently available at this state:    
                  --   1. insn          : current decoded instruction
                  --   2. decodedOpcode : the decoded instruction pipe (due to reading 32bit words,
                  --                      but instruction is 8bit)
                  --   3  opcode        : array with opcodes length = nBits/8 (for 32bit = 4)
                  --   4. stackA        : stack variable A (TOS)  = mem[SP]
                  --   5. stackB        : stack variable B        = mem[SP+1]
                  --------------------------------------------------------------------------------------
                  when State_Execute =>
                      insn <= decodedOpcode(to_integer(nextPC(byteBits-1 downto 0)));

                      case insn is
                          when Insn_InsnFetch =>
                              --  we have exausted the decoded instruction pipeline,
                              --  therefore now we go and fetch the next 32bit
                              --  instruction (to be precise, wordSize bits)
                              state <= State_Fetch;

                          when Insn_Im =>
                              --       OPCODE: IM
                              -- MACHINE CODE: 1xxxxxxx
                              -- set idim_flag to '1'
                              -- NOTE: a) idim_flag='1' means that after an IM, the 2nd, 3rd etc IM will load
                              --          values to stackA by shifting previous values like
                              --          this: stackA = stackA<<7 + newOffset
                              --
                              --       b) interrupts are disabled during IM instruction
                              if in_mem_busy = '0' then
                                  idim_flag  <= '1';    -- signal execution of IM instruction
                                  pc         <= pc + 1; -- decode next intruction

                                  if idim_flag = '1' then -- previously executed IM?
                                      -- continue loading stackA from a previous IM instruction
                                      stackA(wordSize-1 downto 7) <= stackA(wordSize-8 downto 0);
                                      stackA(6 downto 0)          <= unsigned(opcode(bytesBitsCnt)(6 downto 0));
                                  else
                                      -- start loading process
                                      mem_writeEnable <= '1';                       -- we wish to write cached stackB
                                      mem_addr        <= std_logic_vector(incSp);   -- to memory addr = SP+1
                                      mem_write       <= std_logic_vector(stackB);  -- save cached stackB value
                                      stackB          <= stackA;                    -- new stackB is now stackA
                                      sp              <= decSp;                     -- decrement SP (because we push to stack)
                                      for i in wordSize-1 downto 7 loop             -- perform sign extension on stackA
                                          stackA(i) <= opcode(bytesBitsCnt)(6);
                                      end loop;
                                      stackA(6 downto 0) <= unsigned(opcode(bytesBitsCnt)(6 downto 0)); -- load lower bits of stackA with x
                                  end if; -- idim_flag
                              end if; -- in_mem_busy

                          when Insn_StoreSP =>
                              --       OPCODE: STORESP
                              -- MACHINE CODE: 010xxxxx
                              -- set idim_flag to '0'
                              if in_mem_busy = '0' then
                                  idim_flag       <= '0';
                                  state           <= State_StoreSP2;                -- StoreSP2 required to load stackB in Popped
                                  mem_writeEnable <= '1';                           -- we wish to write
                                  mem_addr        <= std_logic_vector(sp+spOffset); -- write to address: SP+offset
                                  mem_write       <= std_logic_vector(stackA);      -- value in stackA (TOS)
                                  stackA          <= stackB;                        -- new stackA = old stackB
                                  sp              <= incSp;                         -- increment SP
                              end if;

                            
                          when Insn_LoadSP =>
                              --       OPCODE: LOADSP
                              -- MACHINE CODE: 011xxxxx
                              -- set idim_flag to '0'
                              if in_mem_busy = '0' then
                                  idim_flag       <= '0';
                                  state           <= State_LoadSP2;
                                  sp              <= decSp;                        -- decrement SP (required by push)
                                  mem_writeEnable <= '1';                          -- we wish to writeback cached value
                                  mem_addr        <= std_logic_vector(incSp);      -- memory position mem[SP+1]
                                  mem_write       <= std_logic_vector(stackB);     -- save stackB @ mem[SP+1]
                              end if;

                          when Insn_Emulate =>
                              --       OPCODE: EMULATE x
                              -- MACHINE CODE: 001xxxxx
                              -- set idim_flag to '0'
                              if in_mem_busy = '0' then
                                  idim_flag                        <= '0';
                                  sp                               <= decSp;                     -- decrement SP 
                                  mem_writeEnable                  <= '1';                       -- we wish to writeback cached value
                                  mem_addr                         <= std_logic_vector(incSp);   -- memory position mem[SP+1]
                                  mem_write                        <= std_logic_vector(stackB);  -- save stackB @ mem[SP+1]
                                  stackA                           <= (others => DontCareValue); -- make sure higher-bit values are set to zero
                                  stackA(maxAddrBitIncIO downto 0) <= pc + 1;                    -- stackA = return address
                                  stackB                           <= stackA;

                                  -- The emulate address is:
                                  --        98 7654 3210
                                  -- 0000 00aa aaa0 0000
                                  pc             <= (others => '0');                             -- make sure higher order bits = '0'
                                  pc(9 downto 5) <= unsigned(opcode(bytesBitsCnt)(4 downto 0));  -- pc = 32*x
                                  state          <= State_Fetch;
                              end if; -- in_mem_busy

                          when Insn_CallPCrel =>
                              --       OPCODE: CALLPCREL
                              -- MACHINE CODE: 00111110
                              -- set idim_flag to '0'
                              if in_mem_busy = '0' then
                                  idim_flag                        <= '0';
                                  stackA                           <= (others => DontCareValue);
                                  stackA(maxAddrBitIncIO downto 0) <= pc + 1;
                                  pc                               <= pc + stackA(maxAddrBitIncIO downto 0);
                                  state                            <= State_Fetch;
                              end if;

                          when Insn_Call =>
                            if in_mem_busy = '0' then
                              idim_flag                        <= '0';
                              stackA                           <= (others => DontCareValue);
                              stackA(maxAddrBitIncIO downto 0) <= pc + 1;
                              pc                               <= stackA(maxAddrBitIncIO downto 0);
                              state                            <= State_Fetch;
                            end if;

                          when Insn_AddSP =>
                            if in_mem_busy = '0' then
                              idim_flag  <= '0';
                              state      <= State_AddSP2;

                              mem_readEnable <= '1';
                              mem_addr       <= std_logic_vector(sp+spOffset);
                            end if;

                          when Insn_PushSP =>
                            if in_mem_busy = '0' then
                              idim_flag  <= '0';
                              pc         <= pc + 1;

                              sp                                        <= decSp;
                              stackA                                    <= (others => '0');
                              stackA(maxAddrBitIncIO downto minAddrBit) <= sp;
                              stackB                                    <= stackA;
                              mem_writeEnable                           <= '1';
                              mem_addr                                  <= std_logic_vector(incSp);
                              mem_write                                 <= std_logic_vector(stackB);
                            end if;

                          when Insn_PopPC =>
                            if in_mem_busy = '0' then
                              idim_flag  <= '0';
                              pc         <= stackA(maxAddrBitIncIO downto 0);
                              sp         <= incSp;

                              mem_writeEnable <= '1';
                              mem_addr        <= std_logic_vector(incSp);
                              mem_write       <= std_logic_vector(stackB);
                              state           <= State_Resync;
                            end if;

                          when Insn_PopPCrel =>
                            if in_mem_busy = '0' then
                              idim_flag  <= '0';
                              pc         <= stackA(maxAddrBitIncIO downto 0) + pc;
                              sp         <= incSp;

                              mem_writeEnable <= '1';
                              mem_addr        <= std_logic_vector(incSp);
                              mem_write       <= std_logic_vector(stackB);
                              state           <= State_Resync;
                            end if;

                          when Insn_AShiftLeft =>
                            idim_flag  <= '0';

                            shiftA <= stackA;
                            shiftB <= stackB;
                            state  <= State_AShiftLeft2;

                          when Insn_AShiftRight =>
                            idim_flag  <= '0';

                            shiftA <= stackA;
                            shiftB <= stackB;
                            state  <= State_AShiftRight2;

                          when Insn_LShiftRight =>
                            idim_flag  <= '0';

                            shiftA <= stackA;
                            shiftB <= stackB;
                            state  <= State_LShiftRight2;

                          when Insn_Add =>
                            if in_mem_busy = '0' then
                              idim_flag  <= '0';
                              stackA     <= stackA + stackB;

                              mem_readEnable <= '1';
                              mem_addr       <= std_logic_vector(incIncSp);
                              sp             <= incSp;
                              state          <= State_Popped;
                            end if;

                          when Insn_Sub =>
                            if in_mem_busy = '0' then
                              idim_flag      <= '0';
                              binaryOpResult <= stackB - stackA;
                              state          <= State_BinaryOpResult;
                            end if;

                          when Insn_Pop =>
                            if in_mem_busy = '0' then
                              idim_flag      <= '0';
                              mem_addr       <= std_logic_vector(incIncSp);
                              mem_readEnable <= '1';
                              sp             <= incSp;
                              stackA         <= stackB;
                              state          <= State_Popped;
                            end if;

                          when Insn_PopDown =>
                            if in_mem_busy = '0' then
                                                      -- PopDown leaves top of stack unchanged
                              idim_flag      <= '0';
                              mem_addr       <= std_logic_vector(incIncSp);
                              mem_readEnable <= '1';
                              sp             <= incSp;
                              state          <= State_Popped;
                            end if;

                          when Insn_Or =>
                            if in_mem_busy = '0' then
                              idim_flag      <= '0';
                              stackA         <= stackA or stackB;
                              mem_readEnable <= '1';
                              mem_addr       <= std_logic_vector(incIncSp);
                              sp             <= incSp;
                              state          <= State_Popped;
                            end if;

                          when Insn_And =>
                            if in_mem_busy = '0' then
                              idim_flag  <= '0';

                              stackA         <= stackA and stackB;
                              mem_readEnable <= '1';
                              mem_addr       <= std_logic_vector(incIncSp);
                              sp             <= incSp;
                              state          <= State_Popped;
                            end if;

                          when Insn_Xor =>
                            if in_mem_busy = '0' then
                              idim_flag  <= '0';

                              stackA         <= stackA xor stackB;
                              mem_readEnable <= '1';
                              mem_addr       <= std_logic_vector(incIncSp);
                              sp             <= incSp;
                              state          <= State_Popped;
                            end if;

                          when Insn_Eq =>
                            if in_mem_busy = '0' then
                              idim_flag  <= '0';

                              binaryOpResult <= (others => '0');
                              if (stackA = stackB) then
                                binaryOpResult(0) <= '1';
                              end if;
                              state <= State_BinaryOpResult;
                            end if;

                          when Insn_Ulessthan =>
                            if in_mem_busy = '0' then
                              idim_flag  <= '0';

                              binaryOpResult <= (others => '0');
                              if (stackA < stackB) then
                                binaryOpResult(0) <= '1';
                              end if;
                              state <= State_BinaryOpResult;
                            end if;

                          when Insn_Ulessthanorequal =>
                            if in_mem_busy = '0' then
                              idim_flag  <= '0';

                              binaryOpResult <= (others => '0');
                              if (stackA     <= stackB) then
                                binaryOpResult(0) <= '1';
                              end if;
                              state <= State_BinaryOpResult;
                            end if;

                          when Insn_Lessthan =>
                            if in_mem_busy = '0' then
                              idim_flag  <= '0';

                              binaryOpResult <= (others => '0');
                              if (signed(stackA) < signed(stackB)) then
                                binaryOpResult(0) <= '1';
                              end if;
                              state <= State_BinaryOpResult;
                            end if;

                          when Insn_Lessthanorequal =>
                            if in_mem_busy = '0' then
                              idim_flag  <= '0';

                              binaryOpResult     <= (others => '0');
                              if (signed(stackA) <= signed(stackB)) then
                                binaryOpResult(0) <= '1';
                              end if;
                              state <= State_BinaryOpResult;
                            end if;

                          when Insn_Load =>
                            if in_mem_busy = '0' then
                              idim_flag  <= '0';
                              state      <= State_Load2;

                              mem_addr       <= std_logic_vector(stackA(maxAddrBitIncIO downto minAddrBit));
                              mem_readEnable <= '1';
                            end if;

                          when Insn_Dup =>
                            if in_mem_busy = '0' then
                              idim_flag  <= '0';
                              pc         <= pc + 1;

                              sp              <= decSp;
                              stackB          <= stackA;
                              mem_write       <= std_logic_vector(stackB);
                              mem_addr        <= std_logic_vector(incSp);
                              mem_writeEnable <= '1';
                            end if;

                          when Insn_DupStackB =>
                            if in_mem_busy = '0' then
                              idim_flag  <= '0';
                              pc         <= pc + 1;

                              sp              <= decSp;
                              stackA          <= stackB;
                              stackB          <= stackA;
                              mem_write       <= std_logic_vector(stackB);
                              mem_addr        <= std_logic_vector(incSp);
                              mem_writeEnable <= '1';
                            end if;

                          when Insn_Store =>
                            if in_mem_busy = '0' then
                              idim_flag       <= '0';
                              pc              <= pc + 1;
                              mem_addr        <= std_logic_vector(stackA(maxAddrBitIncIO downto minAddrBit));
                              mem_write       <= std_logic_vector(stackB);
                              mem_writeEnable <= '1';
                              sp              <= incIncSp;
                              state           <= State_Resync;
                            end if;

                          when Insn_PopSP =>
                            if in_mem_busy = '0' then
                              idim_flag  <= '0';
                              pc         <= pc + 1;

                              mem_write       <= std_logic_vector(stackB);
                              mem_addr        <= std_logic_vector(incSp);
                              mem_writeEnable <= '1';
                              sp              <= stackA(maxAddrBitIncIO downto minAddrBit);
                              state           <= State_Resync;
                            end if;

                          when Insn_Nop =>
                            idim_flag  <= '0';
                            pc         <= pc + 1;

                          when Insn_Not =>
                            idim_flag  <= '0';
                            pc         <= pc + 1;

                            stackA     <= not stackA;

                          when Insn_Flip =>
                            idim_flag  <= '0';
                            pc         <= pc + 1;

                            for i in 0 to wordSize-1 loop
                              stackA(i) <= stackA(wordSize-1-i);
                            end loop;

                          when Insn_AddTop =>
                            idim_flag  <= '0';
                            pc         <= pc + 1;

                            stackA     <= stackA + stackB;

                          when Insn_Shift =>
                            idim_flag  <= '0';
                            pc         <= pc + 1;

                            stackA(wordSize-1 downto 1) <= stackA(wordSize-2 downto 0);
                            stackA(0)                   <= '0';

                          when Insn_PushSPadd =>
                            idim_flag  <= '0';
                            pc         <= pc + 1;

                            stackA                                    <= (others => '0');
                            stackA(maxAddrBitIncIO downto minAddrBit) <= stackA(maxAddrBitIncIO-minAddrBit downto 0)+sp;

                          when Insn_Neqbranch =>
                            -- branches are almost always taken as they form loops
                            idim_flag  <= '0';
                            sp         <= incIncSp;
                            if (stackB /= 0) then
                              pc <= stackA(maxAddrBitIncIO downto 0) + pc;
                            else
                              pc <= pc + 1;
                            end if;
                            -- need to fetch stack again.                           
                            state <= State_Resync;

                          when Insn_Mult =>
                            idim_flag  <= '0';

                            multA <= stackA;
                            multB <= stackB;
                            state <= State_Mult2;

                          when Insn_Break =>
                            report "Break instruction encountered" severity failure;
                            break <= '1';

                          when Insn_Loadb =>
                            if in_mem_busy = '0' then
                              idim_flag  <= '0';
                              state      <= State_Loadb2;

                              mem_addr       <= std_logic_vector(stackA(maxAddrBitIncIO downto minAddrBit));
                              mem_readEnable <= '1';
                            end if;

                          when Insn_Storeb =>
                            if in_mem_busy = '0' then
                              idim_flag  <= '0';
                              state      <= State_Storeb2;

                              mem_addr       <= std_logic_vector(stackA(maxAddrBitIncIO downto minAddrBit));
                              mem_readEnable <= '1';
                            end if;
                            
                          when others =>
                            sp    <= (others => DontCareValue);
                            report "Illegal instruction" severity failure;
                            break <= '1';

                    end case; -- insn/State_Execute

                  --------------------------------------------------------------------------------------
                  -- STATE: STORESP2
                  --------------------------------------------------------------------------------------
                  when State_StoreSP2 =>
                      if in_mem_busy = '0' then
                          mem_addr       <= std_logic_vector(incSp);         -- mem[SP+1]
                          mem_readEnable <= '1';                             -- we wish to read
                          state          <= State_Popped;                    -- this state will load stackB
                      end if;

                  --------------------------------------------------------------------------------------
                  -- STATE: LOADSP2
                  --------------------------------------------------------------------------------------
                  when State_LoadSP2 =>
                      if in_mem_busy = '0' then
                          state          <= State_LoadSP3;
                          mem_readEnable <= '1';                             -- we wish to read
                          mem_addr       <= std_logic_vector(sp+spOffset+1); -- fetch value at mem[SP+offset]
                      end if;

                  --------------------------------------------------------------------------------------
                  -- STATE: LOADSP3
                  --------------------------------------------------------------------------------------
                  when State_LoadSP3 =>
                      if in_mem_busy = '0' then
                          pc     <= pc + 1;                                  -- increment program counter
                          state  <= State_Execute;                           -- execute next instr.
                          stackB <= stackA;                                  -- stackB = old stackA
                          stackA <= unsigned(mem_read);                      -- stackA = fetched value
                      end if;

                  --------------------------------------------------------------------------------------
                  -- STATE: ADDSP2
                  --------------------------------------------------------------------------------------
                  when State_AddSP2 =>
                    if in_mem_busy = '0' then
                      pc     <= pc + 1;
                      state  <= State_Execute;
                      stackA <= stackA + unsigned(mem_read);
                    end if;

                  --------------------------------------------------------------------------------------
                  -- STATE: LOAD2
                  --------------------------------------------------------------------------------------
                  when State_Load2 =>
                    if in_mem_busy = '0' then
                      stackA <= unsigned(mem_read);
                      pc     <= pc + 1;
                      state  <= State_Execute;
                    end if;

                  --------------------------------------------------------------------------------------
                  -- STATE: LOADB2
                  --------------------------------------------------------------------------------------
                  when State_Loadb2 =>
                    if in_mem_busy = '0' then
                      stackA             <= (others => '0');
                      stackA(7 downto 0) <= unsigned(mem_read(((wordBytes-1-to_integer(stackA(byteBits-1 downto 0)))*8+7) downto (wordBytes-1-to_integer(stackA(byteBits-1 downto 0)))*8));
                      pc                 <= pc + 1;
                      state              <= State_Execute;
                    end if;

                  --------------------------------------------------------------------------------------
                  -- STATE: STOREB2
                  --------------------------------------------------------------------------------------
                  when State_Storeb2 =>
                    if in_mem_busy = '0' then
                      mem_addr                                                                                                                              <= std_logic_vector(stackA(maxAddrBitIncIO downto minAddrBit));
                      mem_write                                                                                                                             <= mem_read;
                      mem_write(((wordBytes-1-to_integer(stackA(byteBits-1 downto 0)))*8+7) downto (wordBytes-1-to_integer(stackA(byteBits-1 downto 0)))*8) <= std_logic_vector(stackB(7 downto 0));
                      mem_writeEnable                                                                                                                       <= '1';
                      pc                                                                                                                                    <= pc + 1;
                      sp                                                                                                                                    <= incIncSp;
                      state                                                                                                                                 <= State_Resync;
                    end if;

                  --------------------------------------------------------------------------------------
                  -- STATE: FETCH
                  --------------------------------------------------------------------------------------
                  when State_Fetch =>
                    if in_mem_busy = '0' then
                      mem_addr       <= std_logic_vector(pc(maxAddrBitIncIO downto minAddrBit));
                      mem_readEnable <= '1';
                      state          <= State_Decode;
                    end if;

                  when State_Mult2 =>
                    state <= State_Mult3;

                  when State_Mult3 =>
                    state <= State_Mult4;

                  when State_Mult4 =>
                    state <= State_Mult5;

                  when State_Mult5 =>
                    if in_mem_busy = '0' then
                      stackA         <= multResult3;
                      mem_readEnable <= '1';
                      mem_addr       <= std_logic_vector(incIncSp);
                      sp             <= incSp;
                      state          <= State_Popped;
                    end if;

                  --------------------------------------------------------------------------------------
                  -- STATE: BINARYOPRESULT
                  --------------------------------------------------------------------------------------
                  when State_BinaryOpResult =>
                    state <= State_BinaryOpResult2;

                  --------------------------------------------------------------------------------------
                  -- STATE: BINARYOPRESULT2
                  --------------------------------------------------------------------------------------
                  when State_BinaryOpResult2 =>
                    mem_readEnable <= '1';
                    mem_addr       <= std_logic_vector(incIncSp);
                    sp             <= incSp;
                    stackA         <= binaryOpResult2;
                    state          <= State_Popped;

                  --------------------------------------------------------------------------------------
                  -- STATE: POPPED
                  -- this state reloads the stackB variable since the SP has changed
                  -- Note: stackA must be loaded previously, since after Popped, the next
                  --       state is always Execute, and stackA and stackB must be set to proper values
                  --------------------------------------------------------------------------------------
                  when State_Popped =>
                     if in_mem_busy = '0' then
                        pc     <= pc + 1;
                        stackB <= unsigned(mem_read);
                        state  <= State_Execute;
                     end if;

                  --------------------------------------------------------------------------------------
                  -- STATE: SHIFTLEFT2
                  --------------------------------------------------------------------------------------
                  when State_AShiftLeft2 =>
                    if shiftA = "00000000" then
                      state          <= State_ShiftDone;
                    else
                      shiftA         <= (shiftA - 1);
                      shiftB         <= (shiftB sll 1);
                    end if;

                  --------------------------------------------------------------------------------------
                  -- STATE: ASHIFTRIGHT2
                  --------------------------------------------------------------------------------------
                  when State_AShiftRight2 =>
                    if shiftA = "00000000" then
                      state          <= State_ShiftDone;
                    else
                      shiftA         <= (shiftA - 1);
                      shiftB         <= shiftB(wordSize-1) & shiftB(wordSize-1 downto 1);
                    end if;

                  --------------------------------------------------------------------------------------
                  -- STATE: LSHIFTRIGHT2
                  --------------------------------------------------------------------------------------
                  when State_LShiftRight2 =>
                    if shiftA = "00000000" then
                      state          <= State_ShiftDone;
                    else
                      shiftA         <= (shiftA - 1);
                      shiftB         <= '0' & shiftB(wordSize-1 downto 1);
                    end if;

                  --------------------------------------------------------------------------------------
                  -- STATE: SHIFTDONE
                  --------------------------------------------------------------------------------------
                  when State_ShiftDone =>
                    if in_mem_busy = '0' then
                      stackA         <= shiftB;
                      mem_readEnable <= '1';
                      mem_addr       <= std_logic_vector(incIncSp);
                      sp             <= incSp;
                      state          <= State_Popped;
                    end if;


                  --------------------------------------------------------------------------------------
                  -- STATE: OTHERS
                  --------------------------------------------------------------------------------------
                  when others =>
                      sp    <= (others => DontCareValue);
                      break <= '1';
                      report "Illegal state" severity failure;

              end case; -- state
          end if;
      end if; -- clk'event
  end process;

end behave;
