--
-- (C) 2015, ZPURAMGEN, Tiago Gasiba
--           Automatically Generated RAM file
--           Please do NOT CHANGE!
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


library work;
use work.zpu_config.all;
use work.zpupkg.all;

entity dram is
port (clk             : in std_logic;
      areset          : in std_logic;
      mem_writeEnable : in std_logic;
      mem_readEnable  : in std_logic;
      mem_addr        : in std_logic_vector(maxAddrBit downto 0);
      mem_write       : in std_logic_vector(wordSize-1 downto 0);
      mem_read        : out std_logic_vector(wordSize-1 downto 0);
      mem_busy        : out std_logic;
      mem_writeMask   : in std_logic_vector(wordBytes-1 downto 0));
end dram;

architecture dram_arch of dram is


type ram_type is array(natural range 0 to ((2**(maxAddrBitDRAM+1))/4)-1) of std_logic_vector(wordSize-1 downto 0);

signal ram : ram_type := (
     0 => x"b1040b0b",
     1 => x"0b0b0b0b",
     2 => x"00000000",
     3 => x"00000000",
     4 => x"00000000",
     5 => x"00000000",
     6 => x"00000000",
     7 => x"00000000",
     8 => x"fe3d0d81",
     9 => x"53825283",
    10 => x"51751590",
    11 => x"0c843d0d",
    12 => x"04fd3d0d",
    13 => x"94528a51",
    14 => x"e73f9008",
    15 => x"54738c11",
    16 => x"a0800c53",
    17 => x"853d0d04",
others => x"00000000"
);

begin

mem_busy<=mem_readEnable; -- we're done on the cycle after we serve the read request

process (clk, areset)
begin
    if areset = '1' then
        elsif (clk'event and clk = '1') then
            if (mem_writeEnable = '1') then
                ram(to_integer(unsigned(mem_addr(maxAddrBit downto minAddrBit)))) <= mem_write;
            end if;
        if (mem_readEnable = '1') then
            mem_read <= ram(to_integer(unsigned(mem_addr(maxAddrBit downto minAddrBit))));
        end if;
    end if;
end process;

end dram_arch;
