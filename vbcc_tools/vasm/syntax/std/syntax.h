/* syntax.h  syntax header file for vasm */
/* (c) in 2002-2005,2015 by Volker Barthelmann and Frank Wille */

/* macros to recognize identifiers */
#if defined(VASM_CPU_PPC)
#define ISIDSTART(x) ((x)=='.'||(x)=='_'||(x)=='@'||isalpha((unsigned char)(x)))
#define ISIDCHAR(x) ((x)=='.'||(x)=='_'||(x)=='$'||isalnum((unsigned char)(x)))
#else
#define ISIDSTART(x) ((x)=='.'||(x)=='_'||isalpha((unsigned char)(x)))
#define ISIDCHAR(x) ((x)=='.'||(x)=='_'||isalnum((unsigned char)(x)))
#endif
#define ISEOL(x) (*(x)=='\0'||*(x)==commentchar)
#if defined(VASM_CPU_M68K)
char *chkidend(char *,char *);
#define CHKIDEND(s,e) chkidend((s),(e))
#endif

/* result of a boolean operation */
#define BOOLEAN(x) -(x)

#ifndef CPU_DEF_ALIGN
#define CPU_DEF_ALIGN 2	 /* power2-alignment is default for .align */
#endif

/* overwrite macro defaults */
#define MAXMACPARAMS 64
char *macro_arg_opts(macro *,int,char *,char *);
#define MACRO_ARG_OPTS(m,n,a,p) macro_arg_opts(m,n,a,p)
#define MACRO_ARG_SEP(p) (*p==',' ? skip(p+1) : p)
#define MACRO_PARAM_SEP(p) (*p==',' ? skip(p+1) : p)
void my_exec_macro(source *);
#define EXEC_MACRO(s) my_exec_macro(s)
