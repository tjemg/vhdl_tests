library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;       -- required by 'unsigned' conversion function

entity blink is
  port ( clk       : in  std_logic;
         led       : out std_logic;
         clk_out_1 : out std_logic;
         clk_out_2 : out std_logic;
         clk_out_3 : out std_logic;
         clk_out_4 : out std_logic
       );
end blink;

architecture behave of blink is
    constant  max_value       : natural := 48000000;
    signal    clk_cnt         : std_logic_vector(3 downto 0) := (others => '0');

begin

    clk_out_1 <= clk_cnt(0);
    clk_out_2 <= clk_cnt(1); 
    clk_out_3 <= clk_cnt(2);
    clk_out_4 <= clk_cnt(3);
    
    led_blink: process (clk)
        variable count : natural range 0 to max_value;
    begin
        if rising_edge(clk) then
            clk_cnt <= std_logic_vector( unsigned(clk_cnt) + 1 );
            if count < max_value/2 then
                count := count + 1;
                led   <= '1';
            elsif count < max_value then
                count := count + 1;
                led   <= '0';
            else
                count := 0;
                led   <= '1';
            end if;
        end if;
    end process led_blink;
end architecture behave;
