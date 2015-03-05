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
--use work.fpga_top.all;
use work.zpupkg.all;

entity sim_fpga_top is
end sim_fpga_top;

architecture behave of sim_fpga_top is
    signal clk             : std_logic;
    signal areset          : std_logic := '1';
    signal IO_Port0        : std_logic_vector(wordSize-1 downto 0);

  component fpga_top is
      port ( clk       : in  std_logic;
             reset     : in  std_logic;
             IO_Port0  : out std_logic_vector(wordSize-1 downto 0)
           );
  end component fpga_top;
begin

    myTopLevel: fpga_top
    port map (
        clk                 => clk,
        reset               => areset,
	IO_Port0            => IO_Port0
    );


    -- wiggle the clock @ 100MHz
    clock : process begin
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;
        areset <= '0';
    end process clock;

end architecture behave;
