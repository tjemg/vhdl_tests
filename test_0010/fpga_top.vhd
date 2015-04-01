library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.all;

entity fpga_top is
    generic ( maxAddrBit : integer := 8;
              wordSize   : integer := 16
            );

    port ( clk     : in  std_logic;
           areset  : in  std_logic;
           data    : out std_logic_vector(wordSize-1 downto 0)
         );
end fpga_top;

architecture behave of fpga_top is
    component  driver is
        generic (
            maxAddrBit : integer := maxAddrBit;
            wordSize   : integer := wordSize );

        port ( clk             : in  std_logic;
               areset          : in  std_logic;
               mem_writeEnable : out std_logic;
               mem_readEnable  : out std_logic;
               mem_addr        : out std_logic_vector(maxAddrBit-1 downto 0);
               mem_write       : out std_logic_vector(wordSize-1 downto 0)
             );
    end component;

    component  dram is
        generic (
            maxAddrBit : integer := maxAddrBit;
            wordSize   : integer := wordSize );

         port (clk             : in  std_logic;
               areset          : in  std_logic;
               mem_writeEnable : in  std_logic;
               mem_readEnable  : in  std_logic;
               mem_addr        : in  std_logic_vector(maxAddrBit-1 downto 0);
               mem_write       : in  std_logic_vector(wordSize-1 downto 0);
               mem_read        : out std_logic_vector(wordSize-1 downto 0);
               mem_busy        : out std_logic
             );
    end component;

    signal mem_writeEnable : std_logic;
    signal mem_readEnable  : std_logic;
    signal mem_addr        : std_logic_vector(maxAddrBit-1 downto 0);
    signal mem_write       : std_logic_vector(wordSize-1 downto 0);
    signal mem_busy        : std_logic;

begin
    TOP_DRIVER: driver
    port map ( clk             => clk,
               areset          => areset,
               mem_writeEnable => mem_writeEnable,
               mem_readEnable  => mem_readEnable,
               mem_addr        => mem_addr,
               mem_write       => mem_write
             );

    TOP_DRAM: dram
    port map ( clk             => clk,
               areset          => areset,
               mem_writeEnable => mem_writeEnable,
               mem_readEnable  => mem_readEnable,
               mem_addr        => mem_addr,
               mem_write       => mem_write,
               mem_read        => data,
               mem_busy        => mem_busy         -- not connected...
             );
end behave;

