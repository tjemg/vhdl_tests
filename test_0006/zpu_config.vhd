library ieee;
use ieee.std_logic_1164.all;

package zpu_config is

    constant    Generate_Trace      : boolean := true;
    constant    wordPower           : integer := 5;
    -- during simulation, set this to '0' to get matching trace.txt 
    constant    DontCareValue       : std_logic := '0';
    -- Clock frequency in MHz.
    constant    ZPU_Frequency       : std_logic_vector(7 downto 0) := x"48";
    constant    maxAddrBitIncIO     : integer := 12;
    constant    maxAddrBitDRAM      : integer := 11;
    constant    maxAddrBitBRAM      : integer := 11;
    constant    spStart             : std_logic_vector(maxAddrBitIncIO downto 0) := "0111111111000";
    
end zpu_config;
