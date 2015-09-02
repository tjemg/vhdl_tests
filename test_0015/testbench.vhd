library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.all;

entity testbench is
end testbench;

architecture simulate of testbench is
    signal clk         : std_logic;
    signal areset      : std_logic := '1';
    signal numerator   : std_logic_vector(31 downto 0)  := std_logic_vector(to_unsigned(4029,32));
    signal denominator : std_logic_vector(31 downto 0)  := std_logic_vector(to_unsigned(27,32));
    signal result      : std_logic_vector(31 downto 0);
    signal remainder   : std_logic_vector(31 downto 0);
    signal doneSig     : std_logic;

    component DIV is
        port ( reset : in  std_logic;
               en    : in  std_logic;
               clk   : in  std_logic;
               num   : in  std_logic_vector(31 downto 0);
               den   : in  std_logic_vector(31 downto 0);
               res   : out std_logic_vector(31 downto 0);
               rm    : out std_logic_vector(31 downto 0);
               done  : out std_logic
             );
    end component DIV;
begin

    divComponent: DIV
    port map ( reset => areset,
               en    => '1',
               clk   => clk,
               num   => numerator,
               den   => denominator,
               res   => result,
               rm    => remainder,
               done  => doneSig      );

    clock_proc: process begin
        clk <= '0';
        wait for 5 ns;
        clk <= '1';
        wait for 5 ns;
        areset <= '0';
    end process clock_proc;

end architecture simulate;

