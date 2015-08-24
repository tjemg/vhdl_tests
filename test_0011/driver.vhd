library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity driver is
    generic ( maxAddrBit : integer := 8;
              wordSize   : integer := 8
            );
    port ( clk             : in  std_logic;
           areset          : in  std_logic;
           mem_writeEnable : out std_logic;
           mem_readEnable  : out std_logic;
           mem_addr        : out std_logic_vector(maxAddrBit-1 downto 0);
           mem_write       : out std_logic_vector(wordSize-1 downto 0)
         );
end driver;

architecture behave of driver is
    signal counter : std_logic_vector(maxAddrBit-1 downto 0);
    signal counterT: std_logic_vector(maxAddrBit-1 downto 0);
    signal m_read  : std_logic;
begin
    mem_writeEnable <= '0';
    mem_readEnable  <= m_read;
    mem_write       <= (others=>'0');

    process (clk, areset)
    begin
        if areset='1' then
            counter  <= (others => '0');
            mem_addr <= (others => '0');
            m_read   <= '0';
        elsif (clk'event and clk='1') then
            counter                          <= std_logic_vector( unsigned(counter) + 1 );
            counterT(3 downto 0)             <= counter(3 downto 0);
            counterT(maxAddrBit-1 downto 4)  <= (others => '0');
            mem_addr                         <= counterT after 1 ns;
            m_read                           <= '1' after 1 ns;
        end if;
    end process;
end behave;

