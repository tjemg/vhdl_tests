--------------------------------------------------------------------------------
-- ZPU
--
-- Copyright 2004-2008 oharboe - yvind Harboe - oyvind.harboe@zylin.com
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
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.zpu_config.all;

entity fpga_top is
end fpga_top;

use work.zpupkg.all;

architecture behave of fpga_top is
    signal clk             : std_logic;
    signal areset          : std_logic := '1';
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

    zpu: zpu_core
    port map (
        clk                 => clk,
        reset               => areset,
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

    dram_imp: dram
    port map (
        clk             => clk ,
        areset          => areset,
        mem_busy        => dram_mem_busy,
        mem_read        => dram_mem_read,
        mem_write       => mem_write,
        mem_addr        => mem_addr(maxAddrBit downto 0),
        mem_writeEnable => dram_writeEn,
        mem_readEnable  => mem_readEnable,
        mem_writeMask   => mem_writeMask
    );

    -- Memory reads either come from IO or DRAM. We need to pick the right one.
    readControl: process(dram_mem_read, dram_ready, IO_port_0)
    begin
        mem_read <= (others => 'U');
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

    memoryControlSync: process(clk, areset)
    begin
        if areset = '1' then
            enable       <= '0';
            dram_ready   <= '0';
        elsif rising_edge(clk) then
            enable       <= '1';
            dram_ready   <= mem_readEnable  and not mem_addr(maxAddrBitIncIO);
        end if;
    end process;

    -- wiggle the clock @ 100MHz
    clock : process
       begin
            clk <= '0';
           wait for 5 ns;
            clk <= '1';
           wait for 5 ns;
           areset <= '0';
    end process clock;

end architecture behave;
