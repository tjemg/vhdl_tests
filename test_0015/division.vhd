library ieee;

use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

library work;

-- function divide( a: unsigned; b: unsigned) return unsigned is
--     variable a1: unsigned( a'length-1 downto 0) := a;
--     variable b1: unsigned( b'length-1 downto 0) := b;
--     variable p1: unsigned( b'length   downto 0) := (others=>'0');
--     variable  i: integer                        := 0;
-- begin
--     for i in 0 to b'length-1 loop
--         p1(b'length-1 downto 1) := p1(b'length-2 downto 0);
--         p1(0)                   := a1(a'length-1);
--         a1(a'length-1 downto 1) := a1(a'length-2 downto 0);
--         p1 := p1 - b1;
--         if (p1(b'length-1)='1') then
--             a1(0) := '0';
--             p1    := p1 + b1;
--         else
--             a1(0) := '1';
--         end if;
--     end loop;
--     return a1;
-- end divide;

entity DIV is
    generic (SIZE: INTEGER := 32);

    port ( reset : in  std_logic;
           en    : in  std_logic;
           clk   : in  std_logic;
           num   : in  std_logic_vector((SIZE - 1) downto 0);
           den   : in  std_logic_vector((SIZE - 1) downto 0);
           res   : out std_logic_vector((SIZE - 1) downto 0);
           rm    : out std_logic_vector((SIZE - 1) downto 0);
           done  : out std_logic
         );
end entity DIV;

architecture behav of DIV is
    signal buf  : std_logic_vector((2 * SIZE - 1) downto 0);
    signal dbuf : std_logic_vector(    (SIZE - 1) downto 0);
    signal sm   : integer range 0 to SIZE;

    alias buf1 is buf((2 * SIZE - 1) downto SIZE);
    alias buf2 is buf(    (SIZE - 1) downto 0);
begin

    p_001: process(reset, en, clk)
    begin
        if reset = '1' then
            res  <= (others => '0');
            rm   <= (others => '0');
            sm   <= 0;
            done <= '0';
        elsif rising_edge(clk) then
            if en = '1' then
                case sm is
                    when 0 =>
                        buf1 <= (others => '0');
                        buf2 <= num;
                        dbuf <= den;
                        res  <= buf2;
                        rm   <= buf1;
                        sm   <= sm + 1;
                        done <= '0';
                    when others =>
                        if unsigned(buf((2 * SIZE - 2) downto (SIZE - 1))) >= unsigned(dbuf) then
                            buf1 <= '0' & (buf((2 * SIZE - 3) downto (SIZE - 1)) - dbuf((SIZE - 2) downto 0));
                            buf2 <= buf2((SIZE - 2) downto 0) & '1';
                        else
                            buf <= buf((2 * SIZE - 2) downto 0) & '0';
                        end if;
                        if sm /= SIZE then
                            sm <= sm + 1;
                        else
                            sm   <= 0;
                            done <= '1';
                        end if;
                end case;
            end if;
        end if;
    end process;
end behav;

