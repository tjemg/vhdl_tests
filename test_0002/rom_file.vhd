library ieee;

--use ieee.numeric_std.all;
--use ieee.std_logic_unsigned.conv_integer;
--use ieee.std_logic_unsigned."+";

use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;
use ieee.std_logic_textio.all;


entity ROM_512x24 is
    port ( addr: IN std_logic_VECTOR(8 downto 0);
           inst: OUT std_logic_VECTOR(23 downto 0)
         );
end ROM_512x24;


architecture behavioral of ROM_512x24 is

    type rom_type is array (0 to 511) of std_logic_vector (23 downto 0);

    impure function InitRomFromFile (RomFileName : in string) return rom_type is
        FILE romfile : text is in RomFileName;
        variable RomFileLine : line;
        variable rom : rom_type;
    begin
        for i in rom_type'range loop
            readline(romfile, RomFileLine);
            hread(RomFileLine, rom(i));
        end loop;
        return rom;
    end function;


    signal rom : rom_type := InitRomFromFile("rom.data");
begin
    inst <= rom(conv_integer(addr));
end behavioral;

