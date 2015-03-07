library ieee;
use ieee.std_logic_1164.all;

library work;

entity sim_fpga_top is
end sim_fpga_top;

architecture behave of sim_fpga_top is
    signal clk  : std_logic;
    signal led  : std_logic;

    component blink is
        port ( clk  : in  std_logic;
               led  : out std_logic
             );
  end component blink;
begin

    myTopLevel: blink
    port map (
        clk  => clk,
        led  => led
    );


    -- wiggle the clock @ 100MHz
    clock : process begin
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;
    end process clock;

end architecture behave;
