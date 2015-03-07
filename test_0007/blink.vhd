library ieee;
use ieee.std_logic_1164.all;

entity blink is
  port ( clk       : in  std_logic;
         led       : out std_logic
       );
end blink;

architecture behave of blink is
    constant  max_value       : natural := 48000000;

begin
    led_blink: process (clk)
        variable count : natural range 0 to max_value;
    begin
        if rising_edge(clk) then
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
