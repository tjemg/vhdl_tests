/*
  (C) 2015, Tiago Gasiba, tiago.gasiba@gmail.com

  Very Trivial Assembly Compiler for ZPU
  Do not expect too much from this crap!
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define MEM_SIZE    16*1024*1025     // 16Mb should be enough...
struct {
    unsigned char  *memVal;    // encoded value in memory
    char           *final;     // =0 final value, =1 needs further processing
    char          **instLabel; // the instruction label
    char          **mnemonic;  // mnemonic (if cannot encode)
    char          **operand;   // operand (if cannot encode)
    char           *populated; // =0 if memory is free, =1 is not free
} memoryLayout;


void trim( char *s ) {
    char *p = s;
    int   l = strlen(p);

    while (isspace(p[l - 1])  ) p[--l] = 0;
    while (* p && isspace(* p)) ++p, --l;

    memmove(s, p, l + 1);
}

char *rtrim( char* s ) {
    char* end = s + strlen( s);

    while ((end != s) && isspace( *(end-1))) {
            --end;
    }
    *end = '\0';
    return s;
}

int isInteger( char *str ){
    int ii = 0;

    if (str[ii]=='-') ii++;
    for (; ii<strlen(str); ii++) {
        if (!isdigit(str[ii]))
            return 0;
    }
    return 1;
}

int encodeMnemonic( unsigned long memPos, char *mnemonic, char *operand ){
    int           encLen = 1;
    int           tmp;
    unsigned char machineCode;

    memoryLayout.mnemonic[memPos] = (char *)malloc(1+sizeof(mnemonic));
    strcpy( memoryLayout.mnemonic[memPos], mnemonic );
    memoryLayout.operand[memPos] = (char *)malloc(1+sizeof(operand));
    strcpy( memoryLayout.operand[memPos], operand);

    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"IM")) {
        if ( isInteger(operand) ) {
            tmp                         = atoi(operand) & 0x7f;
            machineCode                 = 0x80 | tmp;
            memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
            memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
            goto couldFinal;
        } else {
            // cannot finalize encoding
            goto cannotFinal;
        }
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"PUSHSPADD")) {
        machineCode                 = 0x3d;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"POPSP")) {
        machineCode                 = 0x0d;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"STORESP")) {
        if ( isInteger(operand) ) {
            tmp                         = atoi(operand) & 0x1f;
            machineCode                 = 0x40 | tmp ^ 0x10;
            memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
            memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
            goto couldFinal;
        }
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"ADDSP")) {
        if ( isInteger(operand) ) {
            tmp                         = atoi(operand) & 0x0f;
            machineCode                 = 0x40 | tmp ^ 0x10;
            memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
            memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
            goto couldFinal;
        }
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"NOP")) {
        machineCode                 = 0x0b;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"BREAK")) {
        machineCode                 = 0x00;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"PUSHSP")) {
        machineCode                 = 0x02;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"ADD")) {
        machineCode                 = 0x05;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"STORE")) {
        machineCode                 = 0x0c;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"PUSHPC")) {
        machineCode                 = 0x3b;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"POPPC")) {
        machineCode                 = 0x04;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"POP")) {
        machineCode                 = 0x50;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"POPDOWN")) {
        machineCode                 = 0x51;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"LOADSP")) {
        if ( isInteger(operand) ) {
            tmp                         = atoi(operand) & 0x1f;
            machineCode                 = 0x60 | tmp ^ 0x10;
            memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
            memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
            goto couldFinal;
        }
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"DUP")) {
        machineCode                 = 0x70;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"DUPSTACKB")) {
        machineCode                 = 0x71;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"SHIFT")) {
        machineCode                 = 0x10;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"ADDTOP")) {
        machineCode                 = 0x11;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"LOAD")) {
        machineCode                 = 0x08;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"AND")) {
        machineCode                 = 0x06;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"OR")) {
        machineCode                 = 0x07;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"NOT")) {
        machineCode                 = 0x09;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"FLIP")) {
        machineCode                 = 0x0a;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"LOADH")) {
        machineCode                 = 0x22;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"STOREH")) {
        machineCode                 = 0x23;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"LESSTHAN")) {
        machineCode                 = 0x24;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"LESSTHANOREQUAL")) {
        machineCode                 = 0x25;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"ULESSTHAN")) {
        machineCode                 = 0x26;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"ULESSTHANOREQUAL")) {
        machineCode                 = 0x27;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"MULT")) {
        machineCode                 = 0x29;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"LSHIFTRIGHT")) {
        machineCode                 = 0x2a;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"ASHIFTLEFT")) {
        machineCode                 = 0x2b;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"ASHIFTRIGHT")) {
        machineCode                 = 0x2c;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"CALL")) {
        machineCode                 = 0x2d;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"EQ")) {
        machineCode                 = 0x2e;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"NEQ")) {
        machineCode                 = 0x2f;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"NEG")) {
        machineCode                 = 0x30;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"SUB")) {
        machineCode                 = 0x31;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"XOR")) {
        machineCode                 = 0x32;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"LOADB")) {
        machineCode                 = 0x33;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"STOREB")) {
        machineCode                 = 0x56;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"DIV")) {
        machineCode                 = 0x35;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"MOD")) {
        machineCode                 = 0x36;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"EQBRANCH")) {
        machineCode                 = 0x37;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"NEQBRANCH")) {
        machineCode                 = 0x38;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"POPPCREL")) {
        machineCode                 = 0x39;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"HALFMULT")) {
        machineCode                 = 0x3e;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"CALLPCREL")) {
        machineCode                 = 0x3f;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        goto couldFinal;
    }

cannotFinal:
    memoryLayout.final[memPos] = 0;
    return encLen;

couldFinal:
    memoryLayout.final[memPos] = 1;   // could finalize the encoding...
    return encLen;

}

int main( int argc, char **argv ) {
    FILE          *fp;
    char          *line  = NULL;
    size_t         len   = 0;
    ssize_t        read;
    int            ii;
    char           label[256];
    char           mnemonic[256];
    char           operand[256];
    char          *tmp;
    char          *tmpLine;  // due to the 'trim' magic, we do not wish to corrupt libc free()...
    unsigned long  memCnt = 0;
    int            numBytes;
    int            flagComplete;
    unsigned long  maxMem;
    int            produceVHDL = 0;

    memoryLayout.memVal    = (unsigned char  *)malloc(MEM_SIZE*sizeof(unsigned char));
    memoryLayout.final     = (         char  *)malloc(MEM_SIZE*sizeof(         char));
    memoryLayout.populated = (         char  *)malloc(MEM_SIZE*sizeof(         char));
    memoryLayout.instLabel = (         char **)malloc(MEM_SIZE*sizeof(       char *));
    memoryLayout.mnemonic  = (         char **)malloc(MEM_SIZE*sizeof(       char *));
    memoryLayout.operand   = (         char **)malloc(MEM_SIZE*sizeof(       char *));

    for (ii=0; ii<MEM_SIZE; ii++) {
        memoryLayout.memVal[ii]    = 0;
        memoryLayout.final[ii]     = 0;
        memoryLayout.populated[ii] = 0;
        memoryLayout.instLabel[ii] = NULL;
        memoryLayout.mnemonic[ii]  = NULL;
        memoryLayout.operand[ii]   = NULL;
    }

    if ( (2!=argc) && (3!=argc) ) {
        printf("(C) 2015, Tiago Gasiba\n");
        printf("\n");
        printf("ERROR: syntax asm file_name [-vhdl]\n");
        exit(0);
    }

    if (3==argc) {
        if (0==strcmp("-vhdl",argv[2])) {
            produceVHDL = 1;
        } else {
            printf("(C) 2015, Tiago Gasiba\n");
            printf("\n");
            printf("ERROR: unknown parameter '%s'\n",argv[2]);
            exit(0);
        }
    } else {
        printf("(C) 2015, Tiago Gasiba\n");
        printf("\n");
    }

    // FIRST STEP
    fp = fopen(argv[1],"r");
    while ((read = getline(&line, &len, fp)) != -1) {
        tmpLine = line;
        trim(line);
        if (tmp=index(line,';')) {  // remove comments
            *tmp = 0;
        }
        rtrim(line);
        for (ii=0; ii<strlen(line); ii++) {
           line[ii] = toupper(line[ii]);
        }

        if (tmp=index(line,':')) {  // retrieve label
            *tmp = 0;
            strcpy(label,line);
            trim(label);
            rtrim(label);
            line = tmp+1;
            trim(line);
            rtrim(line);
        } else {
            strcpy(label,"");
        }
        if (tmp=index(line,' ')) {
            *tmp = 0;
            strcpy(mnemonic,line);
            trim(mnemonic);
            rtrim(mnemonic);
            line = tmp+1;
            trim(line);
            rtrim(line);
            strcpy(operand,line);
        } else {
            strcpy(mnemonic,line);
            strcpy(operand,"");
        }

        if ( (0==strcmp(label,"")) && (0==strcmp(mnemonic,"")) ) { continue; }
//        printf("<MEM: 0x%04x> <LBL: '%10s'>  <MNM: '%15s'>  <OP: '%5s'>\n", memCnt, label, mnemonic, operand);

        if (0!=strcmp(label,"")) {
            tmp = (char *)malloc(1+strlen(label));
            strcpy(tmp,label);
            memoryLayout.instLabel[memCnt] = tmp;
        }

        if (0!=strcmp(mnemonic,"")) {
            numBytes = encodeMnemonic(memCnt,mnemonic, operand);
            for (ii=0; ii<numBytes; ii++) {
               memoryLayout.populated[memCnt+ii] = 1;
            }
            memCnt  += numBytes;
        }
        line = tmpLine;
    }
    fclose(fp);

    // SECOND STEP
    flagComplete = 1;
    for (ii=0; ii<MEM_SIZE; ii++) {
        if ( (1==memoryLayout.populated[ii]) && (0==memoryLayout.final[ii]) ) {
            flagComplete = 0;
            break;
        }
    }
    if (flagComplete) {
        goto doneCompiling;
    }

doneCompiling:
    for (ii=0; ii<MEM_SIZE; ii++) {
        if (1==memoryLayout.populated[ii]) {
            maxMem = ii;
        }
    }

    if (0==produceVHDL) {
        printf("USAGE: %d bytes\n", 1+maxMem);

        for (ii=0; ii<=maxMem; ii++) {
            if (1==memoryLayout.final[ii])
                printf("0x%04x: 0x%02x   < %-18s %-5s >\n",ii, memoryLayout.memVal[ii],
                                                               memoryLayout.mnemonic[ii],
                                                               memoryLayout.operand[ii]);
            else
                printf("0x%04x: 0x%02x ! < %-18s %-5s >\n",ii, memoryLayout.memVal[ii],
                                                               memoryLayout.mnemonic[ii],
                                                               memoryLayout.operand[ii]);
        }
    }  else {
        printf("--\n");
        printf("-- (C) 2015, ASM2VHDL, Tiago Gasiba\n");
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
        printf("signal ram : ram_type := (\n");

        for (ii=0; ii<(1+maxMem>>2); ii++) {
            printf("%6d => x\"%02x%02x%02x%02x\",\n", ii, memoryLayout.memVal[4*ii+0],
                                                          memoryLayout.memVal[4*ii+1],
                                                          memoryLayout.memVal[4*ii+2],
                                                          memoryLayout.memVal[4*ii+3] );
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
        printf("                ram(to_integer(unsigned(mem_addr(maxAddrBit downto minAddrBit)))) <= mem_write;\n");
        printf("            end if;\n");
        printf("        if (mem_readEnable = '1') then\n");
        printf("            mem_read <= ram(to_integer(unsigned(mem_addr(maxAddrBit downto minAddrBit))));\n");
        printf("        end if;\n");
        printf("    end if;\n");
        printf("end process;\n");
        printf("\n");
        printf("end dram_arch;\n");
    }
    return 0;
}
