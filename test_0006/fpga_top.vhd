library ieee;
use ieee.std_logic_1164.all;

library work;
use work.zpu_config.all;

use work.zpupkg.all;

entity fpga_top is
  port ( clk       : in  std_logic;
         reset     : in  std_logic;
         IO_Port0  : out std_logic_vector(wordSize-1 downto 0)
       );
end fpga_top;

architecture behave of fpga_top is
    signal mem_read        : std_logic_vector(wordSize-1 downto 0);
    signal mem_write       : std_logic_vector(wordSize-1 downto 0);
    signal mem_addr        : std_logic_vector(maxAddrBitIncIO downto 0);
    signal mem_writeEnable : std_logic;
    signal mem_readEnable  : std_logic;
    signal mem_writeMask   : std_logic_vector(wordBytes-1 downto 0);
    signal enable          : std_logic;
    signal dram_mem_busy   : std_logic;
    signal dram_mem_read   : std_logic_vector(wordSize-1 downto 0);
    signal dram_ready      : std_logic;
    signal dram_writeEn    : std_logic;
    signal io_readEn       : std_logic;
    signal io_writeEn      : std_logic;
    signal break           : std_logic;
    signal IO_port_0       : std_logic_vector(wordSize-1 downto 0);

begin

    IO_Port0 <= IO_port_0;

    zpu: zpu_core
    port map (
        clk                 => clk,
        reset               => reset,
        enable              => enable,
        in_mem_busy         => dram_mem_busy,
        mem_read            => mem_read,
        mem_write           => mem_write,
        out_mem_addr        => mem_addr,
        out_mem_writeEnable => mem_writeEnable,
        out_mem_readEnable  => mem_readEnable,
        mem_writeMask       => mem_writeMask,
        interrupt           => '0',
        break               => break
    );

    dram4K: dram
    port map (
        clk             => clk ,
        areset          => reset,
        mem_busy        => dram_mem_busy,
        mem_read        => dram_mem_read,
        mem_write       => mem_write,
        mem_addr        => mem_addr(maxAddrBit downto 0),
        mem_writeEnable => dram_writeEn,
        mem_readEnable  => mem_readEnable,
        mem_writeMask   => mem_writeMask
    );

    readControl: process(dram_mem_read, dram_ready, IO_port_0, io_readEn)
    begin
--        mem_read <= (others => 'U');
        mem_read <= (others=>'0');
        if dram_ready ='1' then
            mem_read <= dram_mem_read;
        end if;
        if io_readEn ='1' then
            mem_read <= IO_port_0;
        end if;
    end process;

    writeControl: process(clk,io_writeEn,mem_write)
    begin
        if rising_edge(clk) then
            if io_writeEn ='1' then
                IO_port_0 <= mem_write;
            end if;
        end if;
    end process;

    io_readEn    <= mem_readEnable  and     mem_addr(maxAddrBitIncIO);
    io_writeEn   <= mem_writeEnable and     mem_addr(maxAddrBitIncIO);
    dram_writeEn <= mem_writeEnable and not mem_addr(maxAddrBitIncIO);

    memoryControlSync: process(clk, reset)
    begin
        if reset = '1' then
            enable       <= '0';
            dram_ready   <= '0';
        elsif rising_edge(clk) then
            enable       <= '1';
            dram_ready   <= mem_readEnable  and not mem_addr(maxAddrBitIncIO);
        end if;
    end process;

end architecture behave;
