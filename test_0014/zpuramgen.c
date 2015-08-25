// zpuramgen.c (adapted from zpuromgen.c)
//
// Program to turn a binary file into a VHDL lookup table.
//   by Adam Pierce
//   29-Feb-2008
//
// This software is free to use by anyone for any purpose.
//
// 2015.03.03: Generation of full VHDL code
//

#include <unistd.h>
#include <stdio.h>
#include <stdint.h>

typedef uint8_t BYTE;

main(int argc, char **argv) {
    BYTE    opcode[4];
    int     fd;
    int     addr = 0;
    ssize_t s;

    // Check the user has given us an input file.
    if(argc < 2) {
        printf("Usage: %s <binary_file>\n\n", argv[0]);
        return 1;
    }

    // Open the input file.
    fd = open(argv[1], 0);
    if(fd == -1) {
        perror("File Open");
        return 2;
    }
    printf("--\n");
    printf("-- (C) 2015, ZPURAMGEN, Tiago Gasiba\n");
    printf("--           Automatically Generated RAM file\n");
    printf("--           Please do NOT CHANGE!\n");
    printf("--\n");
    printf("library ieee;\n");
    printf("use ieee.std_logic_1164.all;\n");
    printf("use ieee.numeric_std.all;\n");
    printf("\n");
    printf("\n");
    printf("library work;\n");
    printf("use work.zpu_config.all;\n");
    printf("use work.zpupkg.all;\n");
    printf("\n");
    printf("entity dram is\n");
    printf("port (clk             : in std_logic;\n");
    printf("      areset          : in std_logic;\n");
    printf("      mem_writeEnable : in std_logic;\n");
    printf("      mem_readEnable  : in std_logic;\n");
    printf("      mem_addr        : in std_logic_vector(maxAddrBit downto 0);\n");
    printf("      mem_write       : in std_logic_vector(wordSize-1 downto 0);\n");
    printf("      mem_read        : out std_logic_vector(wordSize-1 downto 0);\n");
    printf("      mem_busy        : out std_logic;\n");
    printf("      mem_writeMask   : in std_logic_vector(wordBytes-1 downto 0));\n");
    printf("end dram;\n");
    printf("\n");
    printf("architecture dram_arch of dram is\n");
    printf("\n");
    printf("\n");
    printf("type ram_type is array(natural range 0 to ((2**(maxAddrBitDRAM+1))/4)-1) of std_logic_vector(wordSize-1 downto 0);\n");
    printf("\n");
    printf("shared variable ram : ram_type := (\n");

    while(1) {
        // Read 32 bits.
        s = read(fd, opcode, 4);
        if(s == -1) {
            perror("File read");
            return 3;
        }

        if(s == 0)
            break; // End of file.

        // Output to STDOUT.
        printf("%6d => x\"%02x%02x%02x%02x\",\n", addr++, opcode[0], opcode[1], opcode[2], opcode[3]);
    }
    printf("others => x\"00000000\"\n");
    printf(");\n");
    printf("\n");
    printf("begin\n");
    printf("\n");
    printf("mem_busy<=mem_readEnable; -- we're done on the cycle after we serve the read request\n");
    printf("\n");
    printf("process (clk, areset)\n");
    printf("begin\n");
    printf("    if areset = '1' then\n");
    printf("        elsif (clk'event and clk = '1') then\n");
    printf("            if (mem_writeEnable = '1') then\n");
    printf("                ram(to_integer(unsigned(mem_addr(maxAddrBit downto minAddrBit)))) := mem_write;\n");
    printf("            end if;\n");
    printf("        if (mem_readEnable = '1') then\n");
    printf("            mem_read <= ram(to_integer(unsigned(mem_addr(maxAddrBit downto minAddrBit))));\n");
    printf("        end if;\n");
    printf("    end if;\n");
    printf("end process;\n");
    printf("\n");
    printf("end dram_arch;\n");

    close(fd);
    return 0;
}

