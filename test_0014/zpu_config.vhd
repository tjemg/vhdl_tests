library ieee;
use ieee.std_logic_1164.all;

-- NOTE: (a) spStart needs to reserve enough space for startup routines
--           in particular for the first push() instruction after starting
--           up the CPU, otherwise, the memory address will overflow or
--           roll-over, producing undesired results
--       (b) for this implementation, the highest order bit is set to zero
--           because the IO port(s) / IO addresses are placed on the highest
--           memory region. This can be changed depending on the application
package zpu_config is
    constant wordPower       : integer   := 5;   -- 2^5 = 32bit
    constant maxAddrBitIncIO : integer   := 12;
    constant maxAddrBitDRAM  : integer   := 11;
    constant maxAddrBitBRAM  : integer   := 11;
    constant spStart         : std_logic_vector(maxAddrBitIncIO downto 0) := "0111111111000";
    constant DontCareValue   : std_logic := '0';
end zpu_config;
