/* parse.h - global parser support functions */
/* (c) in 2009-2015 by Volker Barthelmann and Frank Wille */

#ifndef PARSE_H
#define PARSE_H 

/* defines */
#define MAXLINELENGTH 4096
#ifndef MAXMACPARAMS
#define MAXMACPARAMS 9
#endif
#ifndef MAXMACRECURS
#define MAXMACRECURS 1000
#endif


struct macarg {
  struct macarg *argnext;
  size_t arglen;
  char argname[1];  /* extended to real argument length + '\0' */
};
#define MACARG_REQUIRED 0xffff  /* arglen: indicates there is no default */

struct macro {
  struct macro *next;
  char *name;
  char *text;
  size_t size;
  int num_argnames;		/* -1 for no named arguments used */
  struct macarg *argnames;
  struct macarg *defaults;
  int vararg;
  int recursions;
};

struct namelen {
  size_t len;
  char *name;
};

/* global variables */
extern int esc_sequences,nocase_macros;
extern int maxmacparams,maxmacrecurs;

/* functions */
char *escape(char *,char *);
char *cut_trail_blanks(char *);
char *parse_name(char **);
char *skip_line(char *);
char *skip_identifier(char *);
char *parse_identifier(char **);
char *skip_string(char *,char,size_t *);
char *read_string(char *,char *,char,int);
dblock *parse_string(char **,char,int);
char *parse_symbol(char **);
char *parse_labeldef(char **,int);
int check_indir(char *,char *);
void include_binary_file(char *,long,unsigned long);
int real_line(void);
void new_repeat(int,struct namelen *,struct namelen *);
int find_macarg_name(source *,char *,size_t);
struct macarg *addmacarg(struct macarg **,char *,char *);
macro *new_macro(char *,struct namelen *,char *);
int execute_macro(char *,int,char **,int *,int,char *);
int leave_macro(void);
int undef_macro(char *);
int copy_macro_param(source *,int,char *,int);
int copy_macro_qual(source *,int,char *,int);
int new_structure(char *);
int end_structure(section **);
section *find_structure(char *,int);
char *read_next_line(void);
int init_parse(void);

/* macros which may be overwritten by the syntax module */
#ifndef SKIP_MACRO_ARGNAME
#define SKIP_MACRO_ARGNAME(p) skip_identifier(p)
#endif
#ifndef MACRO_ARG_OPTS
#define MACRO_ARG_OPTS(m,n,a,p) NULL
#endif
#ifndef MACRO_ARG_SEP
#define MACRO_ARG_SEP(p) (*p==',' ? skip(p+1) : NULL)
#endif
#ifndef MACRO_PARAM_SEP
#define MACRO_PARAM_SEP(p) (*p==',' ? skip(p+1) : NULL)
#endif
#ifndef EXEC_MACRO
#define EXEC_MACRO(s)
#endif

#endif /* PARSE_H */
