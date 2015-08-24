library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity dram is
    generic ( maxAddrBit : integer := 8;
              wordSize   : integer := 8
            );
    port (clk             : in  std_logic;
          areset          : in  std_logic;
          mem_writeEnable : in  std_logic;
          mem_readEnable  : in  std_logic;
          mem_addr        : in  std_logic_vector(maxAddrBit-1 downto 0);
          mem_write       : in  std_logic_vector(wordSize-1 downto 0);
          mem_read        : out std_logic_vector(wordSize-1 downto 0);
          mem_busy        : out std_logic
        );
end dram;

architecture dram_arch of dram is


type ram_type is array(natural range 0 to (2**maxAddrBit)-1) of std_logic_vector(wordSize-1 downto 0);

shared variable ram : ram_type := (
     0 => x"00",
     1 => x"01",
     2 => x"00",
     3 => x"01",
     4 => x"01",
     5 => x"00",
     6 => x"01",
     7 => x"01",
     8 => x"01",
     9 => x"00",
    10 => x"01",
    11 => x"01",
    12 => x"01",
    13 => x"01",
    14 => x"00",
    15 => x"00",
    16 => x"00",
others => x"00"
);

begin

mem_busy <= mem_readEnable; -- we're done on the cycle after we serve the read request

process (clk, areset)
begin
    if areset = '1' then
    elsif (clk'event and clk = '1') then
        if (mem_writeEnable = '1') then
            ram(to_integer(unsigned(mem_addr(maxAddrBit-1 downto 0)))) := mem_write;
        end if;
        if (mem_readEnable = '1') then
            mem_read <= ram(to_integer(unsigned(mem_addr(maxAddrBit-1 downto 0))));
        end if;
    end if;
end process;

end dram_arch;
