library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity rom is
    port ( clk  : in  std_logic;
           addr : in  std_logic_vector(3 downto 0);
           dout : out std_logic_vector(7 downto 0)
	 );
end entity;

architecture arch of rom is
    type memory is array (0 to 15) of std_logic_vector(7 downto 0);
    constant myRom : memory := (
             0  => "11111111",
	     1  => "11001100",
	     2  => "01100110",
	     3  => "10011011",
	     4  => "00010100",
	     5  => "11000000",
	others  => "00000000"
    );

begin
    process (clk)
    begin
        if rising_edge(clk) then
            dout <= myRom(conv_integer(addr));
        end if;
    end process;
end arch;

