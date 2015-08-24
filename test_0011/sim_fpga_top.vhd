library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.all;

entity sim_fpga_top is
    generic ( maxAddrBit : integer := 8;
              wordSize   : integer := 8
            );
end sim_fpga_top;

architecture behave of sim_fpga_top is
    component  fpga_top is
        generic (
            maxAddrBit : integer := maxAddrBit;
            wordSize   : integer := wordSize );

        port ( clk     : in  std_logic;
               areset  : in  std_logic;
               data    : out std_logic_vector(wordSize-1 downto 0);
               memAddr : out std_logic_vector(maxAddrBit-1 downto 0);
               memRD   : out std_logic
             );
    end component;

    signal clk    : std_logic;
    signal areset : std_logic := '0';
    signal data   : std_logic_vector(wordSize-1 downto 0);

begin
    areset <= '1' after 2 ns;

    TOP_FPGA: fpga_top
    port map ( clk     => clk,
               areset  => areset,
               data    => data
             );

    -- wiggle the clock @ 100MHz
    clock : process begin
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;
    end process clock;

end behave;

