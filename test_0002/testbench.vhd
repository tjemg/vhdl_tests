library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity testbench is
end testbench;

architecture test of testbench is
    component ROM_512x24 is
        port ( addr: IN std_logic_vector(8 downto 0);
               inst: OUT std_logic_vector(23 downto 0)
             );
    end component;

    signal A  :  std_logic_vector(8 downto 0) := "000000000";
    signal I  :  std_logic_vector(23 downto 0);

begin

    ROM_1: ROM_512x24
      port map ( addr => A,
                 inst => I
               );

    A   <= std_logic_vector( unsigned(A) + 1 ) after 50 ps;

end test;


