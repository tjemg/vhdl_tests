/*
  (C) 2015, Tiago Gasiba, tiago.gasiba@gmail.com

  Very Trivial Assembly Compiler for ZPU
  Do not expect too much from this crap!
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

//
// IM x               1xxx xxxx
// PUSHSPADD          0011 1101
// POPSP              0000 1101
// STORESP x          010X xxxx
// NOP                0000 1011
// PUSHSP             0000 0010
// ADD                0000 0101
// STORE              0000 1100
// PUSHPC             0011 1011
// POPPC              0000 0100
//
//
////////////////////////////////////////
//
// BREAKPOINT         0000 0000
//
// POP                0101 0000
// POPDOWN            0101 0001
//
// LOADSP x           011X xxxx
// DUP                0111 0000
// DUPSTACKB          0111 0001
// ADDSP x            0001 xxxx
// SHIFT              0001 0000
// ADDTOP             0001 0001
// EMULATE x          001x xxxx
// LOAD               0000 1000
// AND                0000 0110
// OR                 0000 0111
// NOT                0000 1001
// FLIP               0000 1010
// LOADH              0010 0010
// STOREH             0010 0011
// LESSTHAN           0010 0100
// LESSTHANOREQUAL    0010 0101
// ULESSTHAN          0010 0110
// ULESSTHANOREQUAL   0010 0111
// MULT               0010 1001
// LSHIFTRIGHT        0010 1010
// ASHIFTLEFT         0010 1011
// ASHIFTRIGHT        0010 1100
// CALL               0010 1101
// EQ                 0010 1110
// NEQ                0010 1111
// NEG                0011 0000
// SUB                0011 0001
// XOR                0011 0010
// LOADB              0011 0011
// STOREB             0011 0100
// DIV                0011 0101
// MOD                0011 0110
// EQBRANCH           0011 0111
// NEQBRANCH          0011 1000
// POPPCREL           0011 1001
// HALFMULT           0011 1110
// CALLPCREL          0011 1111


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

    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"IM")) {
        if ( isInteger(operand) ) {
            tmp                         = atoi(operand) & 0x7f;
            machineCode                 = 0x80 | tmp;
            memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
            memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
            printf("0x%.02x\n",machineCode);
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
        printf("0x%.02x\n",machineCode);
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"POPSP")) {
        machineCode                 = 0x0d;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        printf("0x%.02x\n",machineCode);
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"STORESP")) {
        if ( isInteger(operand) ) {
            tmp                         = atoi(operand) & 0x1f;
            machineCode                 = 0x40 | tmp ^ 0x10;
            memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
            memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
            printf("0x%.02x\n",machineCode);
            goto couldFinal;
        }
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"NOP")) {
        machineCode                 = 0x0b;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        printf("0x%.02x\n",machineCode);
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"PUSHSP")) {
        machineCode                 = 0x02;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        printf("0x%.02x\n",machineCode);
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"ADD")) {
        machineCode                 = 0x05;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        printf("0x%.02x\n",machineCode);
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"STORE")) {
        machineCode                 = 0x0c;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        printf("0x%.02x\n",machineCode);
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"PUSHPC")) {
        machineCode                 = 0x3b;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        printf("0x%.02x\n",machineCode);
        goto couldFinal;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////
    if (0==strcmp(mnemonic,"POPPC")) {
        machineCode                 = 0x04;
        memoryLayout.final[memPos]  = 1;             // could finalize the encoding...
        memoryLayout.memVal[memPos] = machineCode;   // encoded mnemonic
        printf("0x%.02x\n",machineCode);
        goto couldFinal;
    }

cannotFinal:
    memoryLayout.final[memPos] = 0;
    memoryLayout.mnemonic[memPos] = (char *)malloc(1+sizeof(mnemonic));
    strcpy( memoryLayout.mnemonic[memPos], mnemonic );
    memoryLayout.operand[memPos] = (char *)malloc(1+sizeof(operand));
    strcpy( memoryLayout.operand[memPos], operand);
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

    printf("(C) 2015, Tiago Gasiba\n");
    printf("\n");

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

    if (argc!=2) {
        printf("ERROR: missing file name\n");
        exit(0);
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
        printf("<MEM: 0x%04x> <LBL: '%10s'>  <MNM: '%15s'>  <OP: '%5s'>\n", memCnt, label, mnemonic, operand);

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
    printf("USAGE: %d bytes\n", 1+maxMem);

    for (ii=0; ii<=maxMem; ii++) {
        if (1==memoryLayout.final[ii])
            printf("0x%04x: 0x%02x\n",ii, memoryLayout.memVal[ii]);
        else
            printf("0x%04x: 0x%02x ! <%s %s>\n",ii, memoryLayout.memVal[ii],
                                                    memoryLayout.mnemonic[ii],
                                                    memoryLayout.operand[ii]);
    }
    return 0;
}
