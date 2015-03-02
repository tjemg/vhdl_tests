library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity testbench is
end testbench;

architecture test of testbench is
    component rom is
        port ( clk  : in  std_logic;
               addr : in  std_logic_vector(3 downto 0);
               dout : out std_logic_vector(7 downto 0)
             );
    end component;

    signal clk  :  std_logic                    := '0';
    signal A    :  std_logic_vector(3 downto 0) := "0000";
    signal data :  std_logic_vector(7 downto 0);

begin

    ROM_1: rom
      port map ( clk  => clk,
                 addr => A,
                 dout => data
               );

    clk <= not clk after 25 ps;
    A   <= std_logic_vector( unsigned(A) + 1 ) after 50 ps;

end test;


