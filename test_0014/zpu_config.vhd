library ieee;
use ieee.std_logic_1164.all;

package zpu_config is
    constant wordPower       : integer   := 5;   -- 2^5 = 32bit
    constant maxAddrBitIncIO : integer   := 12;
    constant maxAddrBitDRAM  : integer   := 11;
    constant maxAddrBitBRAM  : integer   := 11;
    constant spStart         : std_logic_vector(maxAddrBitIncIO downto 0) := "0111111111000";
    constant DontCareValue   : std_logic := '0';
end zpu_config;
