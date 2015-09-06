/*
    (C) 2015, Tiago Gasiba, tiago.gasiba@gmail.com

    This backend is used for debugging purposes and does not target any known CPU
*/

#include "supp.h"


static char FILE_[]=__FILE__;

// Name and copyright
char cg_copyright[]="vbcc tracer generator V0.01 (C) 2015 by Tiago Gasiba";

//  command line flags the code generator accepts:
//             0: just a flag
//       VALFLAG: a value must be specified
//    STRINGFLAG: a string can be specified
//      FUNCFLAG: a function will be called
int g_flags[MAXGF] = { 0 };

// the flag-name
// NOTE: do not use names beginning with l, L, I, D or U, because they collide with the frontend
char *g_flags_name[MAXGF]={ "test" };

// the results of parsing the command-line-flags will be stored here
union ppi g_flags_val[MAXGF];

//  Alignment-requirements for all types in bytes
zmax align[MAX_TYPE+1];

//  Alignment that is sufficient for every object
zmax maxalign;

//  CHAR_BIT for the target machine
zmax char_bit;

//  sizes of the basic types (in bytes)
zmax sizetab[MAX_TYPE+1];

//  Minimum and Maximum values each type can have
//  Must be initialized in init_cg()
zmax  t_min[MAX_TYPE+1];
zumax t_max[MAX_TYPE+1];
zumax tu_max[MAX_TYPE+1];

//  Names of all registers. will be initialized in init_cg(),
//  register number 0 is invalid, valid registers start at 1
char *regnames[MAXR+1];

//  The Size of each register in bytes
zmax regsize[MAXR+1];

//  a type which can store each register
struct Typ *regtype[MAXR+1];

//  regsa[reg]!=0 if a certain register is allocated and should not be used by the compiler pass
int regsa[MAXR+1];

//  Specifies which registers may be scratched by functions
int regscratch[MAXR+1];

//  specifies the priority for the register-allocator, if the same estimated cost-saving can be
//  obtained by several registers, the one with the highest priority will be used
int reg_prio[MAXR+1];

// an empty reg-handle representing initial state
struct reg_handle empty_reg_handle = {0,0};

// Names of target-specific variable attributes
char *g_attr_name[] = {"__interrupt",0};

// alignment of basic data-types, used to initialize align[]
static long malign[MAX_TYPE+1]   = {1,1,2,4,4,4,4,8,8,1,4,1,1,1,4,1};

// sizes of basic data-types, used to initialize sizetab[]
static long msizetab[MAX_TYPE+1] = {1,1,2,4,4,8,4,8,8,0,4,0,0,0,4,0};

// used to initialize regtyp[] */
static struct Typ ltyp  = {LONG};
static struct Typ ldbl  = {DOUBLE};
static struct Typ lchar = {CHAR};

// macros defined by the backend
static char *marray[] = { "__section(x)=__vattr(\"section(\"#x\")\")",
                          "__GENERIC__",
                          0
                        };

// assembly prefix for labels 
static char *labprefix="l";
// assemvly prefix for external identifiers */
static char *idprefix="_";

#define isreg(x)   ((p->x.flags&(REG|DREFOBJ))   == REG  )
#define isconst(x) ((p->x.flags&(KONST|DREFOBJ)) == KONST)
#define dt(t)      (((t)&UNSIGNED)?udt[(t)&NQ]:sdt[(t)&NQ])
static char *sdt[MAX_TYPE+1] = {"??","c","s","i","l","ll","f","d","ld","v","p"};
static char *udt[MAX_TYPE+1] = {"??","uc","us","ui","ul","ull","f","d","ld","v","p"};

// represents the currently offset to the original SP at the function begin
// shall be used to compute stack offsets when accessing local variables
// because those offsets depend on how much data was previously pushed onto the
// stack before.
// NOTE: this shall be used later for optimization strategy
//       currently, every Intermediate Code instruction is implemented such that
//       the stack shall be cleared at the end of each IC
long globalFunctionOffset = 0;

// #########################################################################################################################
// #                                                 PRIVATE FUNCTIONS                                                     #
// #########################################################################################################################

#define UNHANDLED_CASE(case_str)                              \
        printf("***WARNING*** Unhandled case: "case_str"\n"); \
	exit(0);

char *objType(int type) {
    static char typeName[512] = {0};

    sprintf(typeName,"");

    if (  1==(type&1  )){ strcat(typeName, "CONST ");   }
    if (  2==(type&2  )){ strcat(typeName, "VAR ");     }
    if (  8==(type&8  )){ strcat(typeName, "SCRATCH "); }
    if ( 16==(type&16 )){ strcat(typeName, "STACK ");   }
    if ( 32==(type&32 )){ strcat(typeName, "DREFOBJ "); }
    if ( 64==(type&64 )){ strcat(typeName, "REG ");     }
    if (128==(type&128)){ strcat(typeName, "VARADR ");  }
    if (256==(type&256)){ strcat(typeName, "DONTREG "); }
    if (512==(type&512)){ strcat(typeName, "VCONST ");  }

    return typeName;
}

// Generate Function Pre-Amble
void functionPreamble( FILE *f, struct IC *p, struct Var *v, zmax offset) {
    long reqStackSpace = 4*((offset+3)/4);
    
    printf("Generate Function Preamble (required stack-space = %d bytes)\n", reqStackSpace);
    emit(f,"%s%s:\n", idprefix, v->identifier);  // function label
    emit(f,"\tIM %d\n", (-reqStackSpace + 4)/4); // [SP]   +4 because this function decreases SP by 4
    emit(f,"\tPUSHSPADD\n" );                    // [SP-4] since we added 4 before, the net-effect is (SP-4) + (-r+4) = SP-r
    emit(f,"\tPOPSP\n");                         // [SP-r] now, we pop SP which means we make it = to SP-r as desired
    emit(f,"\n");
}

// Generate Function Closure
void functionClosure( FILE *f, struct IC *p, struct Var *v, zmax offset) {
    emit(f,"\tPUSHPC\n");
    emit(f,"\tPOPPC\n" );
    emit(f,"\n");
}

void printVar( struct Var *v ) {
    static char storageClass[20];
    
    if (1==v->storage_class) { strcpy(storageClass,"AUTO");     }
    if (2==v->storage_class) { strcpy(storageClass,"REGISTER"); }
    if (3==v->storage_class) { strcpy(storageClass,"STATIC");   }
    if (4==v->storage_class) { strcpy(storageClass,"EXTERN");   }
    if (5==v->storage_class) { strcpy(storageClass,"TYPEDEF");  }
    
    printf("VAR :          name = '%s'\n", v->identifier);
    printf("      storage_class = %s\n", storageClass);
    if (isauto(v->storage_class)!=0) {
        // offset contains the offset inside the local-variables section
        printf("             offset = %d\n", v->offset);
    }
    printf("                   = ");
    if ( USEDASSOURCE == (USEDASSOURCE & v->flags)   ) { printf("USEDASSOURCE ");  }
    if ( USEDASDEST == (USEDASDEST & v->flags)       ) { printf("USEDASDEST ");    }
    if ( DEFINED == (DEFINED & v->flags)             ) { printf("DEFINED ");       }
    if ( USEDASADR == (USEDASADR & v->flags)         ) { printf("USEDASADR ");     }
    if ( GENERATED == (GENERATED & v->flags)         ) { printf("GENERATED ");     }
    if ( CONVPARAMETER == (CONVPARAMETER & v->flags) ) { printf("CONVPARAMETER "); }
    if ( TENTATIVE == (TENTATIVE & v->flags)         ) { printf("TENTATIVE ");     }
    if ( USEDBEFORE == (USEDBEFORE & v->flags)       ) { printf("USEDBEFORE ");    }
    if ( INLINEV == (INLINEV & v->flags)             ) { printf("INLINEV ");       }
    if ( PRINTFLIKE == (PRINTFLIKE & v->flags)       ) { printf("PRINTFLIKE ");    }
    if ( SCANFLIKE == (SCANFLIKE & v->flags)         ) { printf("SCANFLIKE ");     }
    if ( NOTTYPESAFE == (NOTTYPESAFE & v->flags)     ) { printf("NOTTYPESAFE ");   }
    if ( DNOTTYPESAFE == (DNOTTYPESAFE & v->flags)   ) { printf("DNOTTYPESAFE ");  }
    if ( REGPARM == (REGPARM & v->flags)             ) { printf("REGPARM ");       }
    if ( DBLPUSH == (DBLPUSH & v->flags)             ) { printf("DBLPUSH ");       }
    if ( NOTINTU == (NOTINTU & v->flags)             ) { printf("NOTINTU ");       }
    if ( REFERENCED == (REFERENCED & v->flags)       ) { printf("REFERENCED ");    }
    printf("\n");
}


// loadInt: pushes an immediate integer into the stack
// NOTE - since the ZPU IM instruction can only push 7 bits each time
//        several IM instructions are issued for a single integer.
//        The number of IM instructions depends on the integer value
//        and can range from 1 to 5 (for 32-bit architecture)
void loadInt( FILE *f, int val ){
    int          remainder = val;
    signed char  val7;
    signed char  values[5];
    int          ii;
    int          flagPositive;

    flagPositive = (val>0) ? 1 : 0;

    for (ii=0; ii<5; ii++) {
         values[4-ii] = remainder & 0x7f;
	 if ( 0x40 == (remainder & 0x40) ) {
             values[4-ii] |= 0x80;
	 }
        remainder >>= 7;
    }
    for (ii=0; ii<5; ii++) {
        if (ii!=4) {
            if ( (values[ii]!=values[ii+1]) && !((-1==values[ii] && 0x80==(values[ii+1]&0x80)) || (0==values[ii] && 0x00==(values[ii+1]&0x80))) ) {
                if (flagPositive) {
                    emit(f,"\tIM %d\n",0x7f & values[ii]);
                } else {
                    emit(f,"\tIM %d\n",(signed int)values[ii]);
                }
            }
        } else {
            if (flagPositive) {
                emit(f,"\tIM %d  ;  %d  (0x%.08x)\n", 0x7f & values[ii], val, val);
            } else {
                emit(f,"\tIM %d  ;  %d  (0x%.08x)\n",(signed int)values[ii], val, val);
            }
        }
    }
    printf("\n");
}

// Operation  : ASSIGN
// Description: Copy q1 to z
void opASSIGN( FILE *f, struct IC *p ) {
    struct obj *q1 = &p->q1;
    struct obj *z  = &p->z;

    printf("ASSIGN: (lin:%.4d) src: %s\n", p->line, objType(q1->flags));
    printf("                   dst: %s", objType(z->flags));
    printf("\n");
    printf("INFO SRC:\n");
    if (KONST==(KONST&q1->flags)) {
        printf("   const:%d\n", q1->val.vint );
    }
    if (q1->v) { printVar(q1->v); }
    printf("INFO DST:\n");
    if (z->v) { printVar(z->v); }
    printf("\n\n");

    if ( (KONST == q1->flags) && (VAR == VAR && z->flags) ){
        // Assign a constant to a variable
        if ( (VAR==z->flags) && (AUTO == z->v->storage_class) ) {
            // variable is located in stack
	    printf("CONST -> STACK\n");
	    loadInt(f,q1->val.vint);                       // [SP-4] q1.val
            emit(f,"\tSTORESP %d\n", (z->v->offset+4)/4);  // we need to add 4 since there is one value on the stack
            emit(f,"\n");
	    return;
        }
        if ( (DREFOBJ==(DREFOBJ&z->flags)) && (AUTO == z->v->storage_class) ) {
            // variable needs to be dereferenced
            loadInt(f,q1->val.vint);    // [SP-4]:q1.val
            emit(f,"\tNOP\n");          // [SP-4]:
	    loadInt(f,z->v->offset+8);  // [SP-8]: 8+z.ofs,  [SP-4]: q1.val
            emit(f,"\tPUSHSP\n");       // [SP-12]: SP-8,    [SP-8] 8+z.ofs, [SP-4]: q1.val
            emit(f,"\tADD\n");          // [SP-8]: SP+z.ofs, [SP-4]: q1.val
            emit(f,"\tSTORE\n");        // -
            emit(f,"\n");
	    return;
        }
        UNHANDLED_CASE("ASSIGN KONST -> ?");
    }
    UNHANDLED_CASE("ASSIGN ? -> ?");
}
// Operation  : ADD
// Description: q1+q2 -> z
void opADD( FILE *f, struct IC *p ) {
    struct obj *q1 = &p->q1;
    struct obj *q2 = &p->q2;
    struct obj *z  = &p->z;

    printf("ADD: (lin:%.4d) src1: %s\n", p->line, objType(q1->flags));
    printf("                src2: %s\n", objType(q2->flags));
    printf("                 dst: %s"  , objType(z->flags));
    printf("\n");
    printf("INFO SRC_1:\n");
    if (KONST==(KONST&q1->flags)) {
        printf("   const:%d\n", q1->val.vint );
    }
    if (q1->v) { printVar(q1->v); }
    printf("INFO SRC_2:\n");
    if (KONST==(KONST&q2->flags)) {
        printf("   const:%d\n", q2->val.vint );
    }
    if (q2->v) { printVar(q2->v); }
    printf("INFO DST:\n");
    if (z->v) { printVar(z->v); }
    printf("\n\n");
    
    // VAR, VAR -> VAR
    if ( (VAR==q1->flags) && (VAR==q2->flags) && (VAR==z->flags) ){
        // TODO optimize in case of small offsets (use STORESP, LOADSP, ADDSP, etc...)
        //  STACK IMAGE                                   | [SP-8]     | [SP-4]     | [SP] | 
        //                                           SP   |            |            | (?)  |  we add 4 here since we wish to load v2_addr into stack
        emit(f,"\tIM %d\n",(q2->v->offset+4)/4);  // SP-4 |            | (v2_x)     |  ?   |  we add 4 here since we wish to load v2_addr into stack
        emit(f,"\tPUSHSPADD\n");                  // SP-4 |            | (v2_addr)  |  ?   |  add SP-4 + (v2_o+4) = SP + v2_o = v2_addr
        emit(f,"\tLOAD\n");                       // SP-4 |            | (*v2_addr) |  ?   |  this loads TOS = *v2_addr
        emit(f,"\tIM %d\n",(q1->v->offset+8)/4);  // SP-8 | (v1_x)     |  *v2_addr  |  ?   |  we add 8 here sinwe we wish to load v1_addr into stack
        emit(f,"\tPUSHSPADD\n");                  // SP-8 | (v1_addr)  |  *v2_addr  |  ?   |  add SP-8 + (v1_o+8) = SP + v1_o = v1_addr
        emit(f,"\tLOAD\n");                       // SP-8 | (*v1_addr) |  *v2_addr  |  ?   |  this loads TOS = *v1_addr
        emit(f,"\tADD\n");                        // SP-4 |            |   (SUM)    |  ?   |  add the two values
        emit(f,"\tIM %d\n",(z->v->offset+8)/4);   // SP-8 | (vz_x)     |    SUM     |  ?   |  load vz_x
        emit(f,"\tPUSHSPADD\n");                  // SP-8 | (vz_addr)  |    SUM     |  ?   |  now TOS = vz_addr
        emit(f,"\tSTORE\n");                      // SP   |            |            | (?)  |  STORE pops two values A=mem, B=val
        emit(f,"\n");
        return;
    }
    UNHANDLED_CASE("ADD ? -> ?");
}


// #########################################################################################################################
// #                                            BACKEND REQUIRED FUNCTIONS                                                 #
// #########################################################################################################################

//  Does necessary initializations for the code-generator. Gets called 
//  once at the beginning and should return 0 in case of problems
int init_cg(void) {
    int i;

    //  Initialize some values which cannot be statically initialized because they are stored in the target's arithmetic
    maxalign   = l2zm(8L);
    char_bit   = l2zm(8L);
    stackalign = l2zm(4);

    for (i=0; i<=MAX_TYPE; i++ ){
        sizetab[i] = l2zm(msizetab[i]);
        align[i]   = l2zm(malign[i]);
    }

    regnames[0]="noreg";
    for ( i=1; i<=MAXR; i++){
        regnames[i] = mymalloc(10);
        sprintf(regnames[i],"reg%d",i-1);
        regsize[i] = l2zm(4L);
        regtype[i] = &ltyp;
    }

    //  Initialize the min/max-settings. Note that the types of the
    //  host system may be different from the target system and you may
    //  only use the smallest maximum values ANSI guarantees if you
    //  want to be portable
    //  That's the reason for the subtraction in t_min[INT]. Long could
    //  be unable to represent -2147483648 on the host system
    t_min[CHAR]    = l2zm(-128L);
    t_min[SHORT]   = l2zm(-32768L);
    t_min[INT]     = zmsub(l2zm(-2147483647L),l2zm(1L));
    t_min[LONG]    = t_min(INT);
    t_min[LLONG]   = zmlshift(l2zm(1L),l2zm(63L));
    t_min[MAXINT]  = t_min(LLONG);
    t_max[CHAR]    = ul2zum(127L);
    t_max[SHORT]   = ul2zum(32767UL);
    t_max[INT]     = ul2zum(2147483647UL);
    t_max[LONG]    = t_max(INT);
    t_max[LLONG]   = zumrshift(zumkompl(ul2zum(0UL)),ul2zum(1UL));
    t_max[MAXINT]  = t_max(LLONG);
    tu_max[CHAR]   = ul2zum(255UL);
    tu_max[SHORT]  = ul2zum(65535UL);
    tu_max[INT]    = ul2zum(4294967295UL);
    tu_max[LONG]   = t_max(UNSIGNED|INT);
    tu_max[LLONG]  = zumkompl(ul2zum(0UL));
    tu_max[MAXINT] = t_max(UNSIGNED|LLONG);
    
    for (i=1; i<=MAXR; i++)
        regsa[i] = 1;

    target_macros = marray;
    return 1;
}

// initialize debugging information
void init_db( FILE *f ) {
}

//  Returns the register in which variables of type t are returned.
//  If the value cannot be returned in a register returns 0.
//  A pointer MUST be returned in a register. The code-generator
//  has to simulate a pseudo register if necessary.
//  TODO: fix this function
int freturn( struct Typ *t ) {
    printf("FRETURN\n");
    //if (ISFLOAT(t->flags)) 
    //    return 2;
    //if (ISSTRUCT(t->flags)||ISUNION(t->flags)) 
    //    return 0;
    //if (zmleq(szof(t), l2zm(4L))) 
    //    return 2;
    //else
    return 0;
}

// Returns 0 if the register is no register pair. If r is a register pair non-zero will
// be returned and the structure pointed to p will be filled with the two elements
int reg_pair( int r, struct rpair *p) {
    printf("REG_PAIR\n");
    return 0;
}

// estimate the cost-saving if object o from IC p is placed in register r
int cost_savings( struct IC *p, int r, struct obj *o ){
    printf("COST_SAVINGS\n");
    return 0;
}

//  Returns 0 if register r cannot store variables of type t. If t==POINTER and mode!=0 then it returns
//  non-zero only if the register can store a pointer and dereference a pointer to mode
int regok( int r, int t, int mode ) {
    printf("REGOK\n");
    return 0;  // cannot store anything on register
}


//  Returns zero if the IC p can be safely executed without danger of exceptions or similar things.
//  vbcc may generate code in which non-dangerous ICs are sometimes executed although control-flow may
//  never reach them (mainly when moving computations out of loops).
//  Typical ICs that generate exceptions on some machines are:
//      - accesses via pointers
//      - division/modulo
//      - overflow on signed integer/floats
int dangerous_IC( struct IC *p ) {
    printf("DANGEROUS_IC\n");
    int c=p->code;
    if ( (p->q1.flags & DREFOBJ) || (p->q2.flags & DREFOBJ) || (p->z.flags & DREFOBJ) )
        return 1;
    if ( (c==DIV || c==MOD ) && !isconst(q2) )
        return 1;
    return 0;
}

//  Returns zero if code for converting np to type t can be omitted.
//  On the PowerPC cpu pointers and 32bit integers have the same representation and can use the same registers.
int must_convert( int o, int t, int const_expr ) {
    printf("MUST_CONVERT\n");
    int op = o&NQ;
    int tp = t&NQ;
    if ( (op==INT || op==LONG || op==POINTER) && (tp==INT || tp==LONG || tp==POINTER) )
        return 0;
    if (op==DOUBLE && tp==LDOUBLE) return 0;
    if (op==LDOUBLE && tp==DOUBLE) return 0;
    return 1;
}

//  This function has to create <size> bytes of storage initialized with zero
void gen_ds( FILE *f, zmax size, struct Typ *t ) {
    printf("GEN_DS\n");
    emit(f,"\t.space\t%ld\n",zm2l(size));
}

//  This function has to make sure the next data is aligned to multiples of <align> bytes
void gen_align( FILE *f, zmax align ) {
    printf("GEN_ALIGN\n");
}

// This function has to create the head of a variable definition, i.e. the label and information for linkage etc
void gen_var_head( FILE *f, struct Var *v ) {
    int   constflag;
    char *sec;

    printf("GEN_VAR_HEAD\n");
    if (v->clist)
        constflag = is_const(v->vtyp);

    // static variable
    if (v->storage_class==STATIC) {
        if (ISFUNC(v->vtyp->flags)) return;
        emit(f,"%s%ld:\n",labprefix,zm2l(v->offset));
    }

    // external variable
    if (v->storage_class==EXTERN){
        emit(f,"\t.globl\t%s%s\n",idprefix,v->identifier);
        if(v->flags&(DEFINED|TENTATIVE)){
            emit(f,"\t.global\t%s%s\n\t.%scomm\t%s%s,",idprefix,v->identifier,labprefix,idprefix,v->identifier);
        }
    }
}

//  This function has to create static storage initialized with const-list p
void gen_dc( FILE *f, int t, struct const_list *p ) {
    unsigned char *ip;

    printf("GEN_DC\n");
    emit(f,"\tdc.%s\t", dt(t&NQ) );
    if (!p->tree) {
        if (ISFLOAT(t)) {
          //  auch wieder nicht sehr schoen und IEEE noetig
          ip = (unsigned char *)&p->val.vdouble;
          emit(f,"0x%02x%02x%02x%02x",ip[0],ip[1],ip[2],ip[3]);
          if ((t&NQ)!=FLOAT) {
              emit(f,",0x%02x%02x%02x%02x",ip[4],ip[5],ip[6],ip[7]);
          }
        } else {
          emitval(f,&p->val,t&NU);
        }
    } else {
        //emit_obj(f,&p->tree->o,t&NU);
    }
    emit(f,"\n");
}

//  The main code-generation routine.  f is the stream the code should be written to.
//  p is a pointer to a doubly linked list of ICs containing the function body to generate code for.
//  v is a pointer to the function. offset is the size of the stackframe the function needs for local variables.
void gen_code( FILE *f, struct IC *p, struct Var *v, zmax offset) {
    int        c;  // code
    int        t;  // type
    int        i;
    struct IC *m;

    printf("GEN_CODE : %s%s (%s)\n", idprefix, v->identifier, v->filename);
    printf("var stackframe size = %d\n", offset);

    // FUNCTION PRE-AMBLE
    printf("Preamble\n");
    functionPreamble(f,p,v,offset);

    for (; p; p=p->next ){
        c = p->code;
        t = p->typf;
        if (KOMMA==c)        { printf("KOMMA\n");        }
        if (ASSIGN==c)       { opASSIGN(f,p);            }
        if (ASSIGNOP==c)     { printf("ASSIGNOP\n");     }
        if (COND==c)         { printf("COND\n");         }
        if (LOR==c)          { printf("LOR\n");          }
        if (LAND==c)         { printf("LAND\n");         }
        if (OR==c)           { printf("OR\n");           }
        if (XOR==c)          { printf("XOR\n");          }
        if (AND==c)          { printf("AND\n");          }
        if (EQUAL==c)        { printf("EQUAL\n");        }
        if (INEQUAL==c)      { printf("INEQUAL\n");      }
        if (LESS==c)         { printf("LESS\n");         }
        if (LESSEQ==c)       { printf("LESSEQ\n");       }
        if (GREATER==c)      { printf("GREATER\n");      }
        if (GREATEREQ==c)    { printf("GREATEREQ\n");    }
        if (LSHIFT==c)       { printf("LSHIFT\n");       }
        if (RSHIFT==c)       { printf("RSHIFT\n");       }
        if (ADD==c)          { opADD(f,p);               }
        if (SUB==c)          { printf("SUB\n");          }
        if (MULT==c)         { printf("MULT\n");         }
        if (DIV==c)          { printf("DIV\n");          }
        if (MOD==c)          { printf("MOD\n");          }
        if (NEGATION==c)     { printf("NEGATION\n");     }
        if (KOMPLEMENT==c)   { printf("KOMPLEMENT\n");   }
        if (PREINC==c)       { printf("PREINC\n");       }
        if (POSTINC==c)      { printf("POSTINC\n");      }
        if (PREDEC==c)       { printf("PREDEC\n");       }
        if (POSTDEC==c)      { printf("POSTDEC\n");      }
        if (MINUS==c)        { printf("MINUS\n");        }
        if (CONTENT==c)      { printf("CONTENT\n");      }
        if (ADDRESS==c)      { printf("ADDRESS\n");      }
        if (CAST==c)         { printf("CAST\n");         }
        if (CALL==c)         { printf("CALL\n");         }
        if (INDEX==c)        { printf("INDEX\n");        }
        if (DPSTRUCT==c)     { printf("DPSTRUCT\n");     }
        if (DSTRUCT==c)      { printf("DSTRUCT\n");      }
        if (IDENTIFIER==c)   { printf("IDENTIFIER\n");   }
        if (CEXPR==c)        { printf("CEXPR\n");        }
        if (STRING==c)       { printf("STRING\n");       }
        if (MEMBER==c)       { printf("MEMBER\n");       }
        if (CONVERT==c)      { printf("CONVERT\n");      }
        if (ADDRESSA==c)     { printf("ADDRESSA\n");     }
        if (FIRSTELEMENT==c) { printf("FIRSTELEMENT\n"); }
        if (PMULT==c)        { printf("PMULT\n");        }
        if (ALLOCREG==c)     { printf("ALLOCREG\n");     }
        if (FREEREG==c)      { printf("FREEREG\n");      }
        if (PCEXPR==c)       { printf("PCEXPR\n");       }
        if (TEST==c)         { printf("TEST\n");         }
        if (LABEL==c)        { printf("LABEL\n");        }
        if (BEQ==c)          { printf("BEQ\n");          }
        if (BNE==c)          { printf("BNE\n");          }
        if (BLT==c)          { printf("BLT\n");          }
        if (BGE==c)          { printf("BGE\n");          }
        if (BLE==c)          { printf("BLE\n");          }
        if (BGT==c)          { printf("BGT\n");          }
        if (BRA==c)          { printf("BRA\n");          }
        if (COMPARE==c)      { printf("COMPARE\n");      }
        if (PUSH==c)         { printf("PUSH\n");         }
        if (POP==c)          { printf("POP\n");          }
        if (ADDRESSS==c)     { printf("ADDRESSS\n");     }
        if (ADDI2P==c)       { printf("ADDI2P\n");       }
        if (SUBIFP==c)       { printf("SUBIFP\n");       }
        if (SUBPFP==c)       { printf("SUBPFP\n");       }
        if (PUSHREG==c)      { printf("PUSHREG\n");      }
        if (POPREG==c)       { printf("POPREG\n");       }
        if (POPARGS==c)      { printf("POPARGS\n");      }
        if (SAVEREGS==c)     { printf("SAVEREGS\n");     }
        if (RESTOREREGS==c)  { printf("RESTOREREGS\n");  }
        if (ILABEL==c)       { printf("ILABEL\n");       }
        if (DC==c)           { printf("DC\n");           }
        if (ALIGN==c)        { printf("ALIGN\n");        }
        if (COLON==c)        { printf("COLON\n");        }
        if (GETRETURN==c)    { printf("GETRETURN\n");    }
        if (SETRETURN==c)    { printf("SETRETURN\n");    }
        if (MOVEFROMREG==c)  { printf("MOVEFROMREG\n");  }
        if (MOVETOREG==c)    { printf("MOVETOREG\n");    }
        if (NOP==c)          { printf("NOP\n");          }
        if (BITFIELD==c)     { printf("BITFIELD\n");     }
        if (LITERAL==c)      { printf("LITERAL\n");      }
        if (REINTERPRET==c)  { printf("REINTERPRET\n");  }
    }
    
    functionClosure(f,p,v,offset);
}

int shortcut(int code,int typ) {
    printf("SHORTCUT\n");
    return 0;
}

int reg_parm( struct reg_handle *m, struct Typ *t,int vararg,struct Typ *d ) {
    printf("REG_PARM\n");
    return 0;
}

int handle_pragma(const char *s) {
    printf("HANDLE_PRAGMA\n");
}

void cleanup_cg(FILE *f) {
    printf("CLEANUP_CG\n");
}

void cleanup_db(FILE *f) {
    printf("CLEANUP_DB\n");
}

