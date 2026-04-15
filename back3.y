/* Grupo XX - RELLENAR_NOMBRE_1, RELLENAR_NOMBRE_2 */
/* correo1@ejemplo.com correo2@ejemplo.com */

%{                          // SECTION 1 Declarations for C-Bison
#include <stdio.h>
#include <ctype.h>            // tolower()
#include <string.h>           // strcmp()
#include <stdlib.h>           // exit()

#define FF fflush(stdout);    // to force immediate printing

int yylex () ;
void yyerror (char *) ;
char *my_malloc (int) ;

char *gen_code (char *) ;

// Definitions for explicit attributes
typedef struct s_attr {
    int value ;    // - Numeric value of a NUMBER
    char *code ;   // - IDENTIFIER names, strings and other translations
} t_attr ;

#define YYSTYPE t_attr     // stack of PDA has type t_attr

// Track already-declared global variables to avoid redeclaring them with "variable".
typedef struct s_var {
    char *name ;
    struct s_var *next ;
} t_var ;

static t_var *declared_vars = NULL ;

int is_declared (char *name) ;
void declare_var (char *name) ;

%}

// Definitions for explicit attributes

%token NUMBER
%token IDENTIF
%token STRING

%token MAIN
%token WHILE
%token LOOP
%token DO
%token SETQ
%token SETF
%token DEFUN
%token PRINT
%token PRINC
%token AND
%token OR
%token NOT
%token IF
%token PROGN
%token MOD

%token LE     // <=
%token GE     // >=
%token NE     // /= or !=
%token EQ     // ==

%%

axiom:        exprSeq                           { ; }
            ;


exprSeq:      form                              { ; }
                 r_exprSeq                      { ; }
            ;


r_exprSeq:    exprSeq                           { ; }
            |  /* lambda */                     { ; }
            ;


exprSeqOpt:   exprSeq                           { ; }
            |  /* lambda */                     { ; }
            ;


form:         expression                        { ; }  // Lisp REPL-like arithmetic or boolean expression

            | '(' SETQ IDENTIF expression ')'   {
                    if (!is_declared ($3.code)) {
                        printf (" variable %s ", $3.code) ;
                        declare_var ($3.code) ;
                    }
                    printf (" %s ! ", $3.code) ;
                }

            | '(' SETF IDENTIF expression ')'   { printf (" %s ! ", $3.code) ; }

            | '(' PRINT STRING ')'              { printf (" .\" %s\" cr ", $3.code) ; }
            | '(' PRINT expression ')'          { printf (" . cr ") ; }

            | '(' PRINC STRING ')'              { printf (" .\" %s\" ", $3.code) ; }
            | '(' PRINC expression ')'          { printf (" . ") ; }

            | '(' PROGN exprSeqOpt ')'          { ; }

            | '(' MAIN ')'                      { printf (" main ") ; }
            | '(' IDENTIF ')'                   { printf (" %s ", $2.code) ; }

            | '(' DEFUN MAIN                    { printf (" : main ") ; }
                '(' ')' exprSeqOpt ')'          { printf (" ; ") ; }

            | '(' LOOP WHILE                    { printf (" begin ") ;  }
                 expression                     { printf (" while ") ; }
                 DO exprSeqOpt ')'              { printf (" repeat ") ; }

            | '(' ifHead  form ')'              { printf (" then ") ; }

            | '(' ifHead  form                  { printf (" else ") ; }
                 form ')'                       { printf (" then ") ; }
            ;


ifHead:       IF expression                     { printf (" if ") ; }
            ;


expression:   operand                                   { ; }

            | '(' '+' expression expression ')'         { printf (" + ") ; }
            | '(' '-' expression expression ')'         { printf (" - ") ; }      // binary minus operator
            | '(' '*' expression expression ')'         { printf (" * ") ; }
            | '(' '/' expression expression ')'         { printf (" / ") ; }
            | '(' MOD expression expression ')'         { printf (" mod ") ; }

            | '(' AND expression expression ')'         { printf (" and ") ; }
            | '(' OR expression expression ')'          { printf (" or ") ; }
            | '(' NOT expression ')'                    { printf (" 0= ") ; }

            | '(' '<' expression expression ')'         { printf (" < ") ; }
            | '(' LE expression expression ')'          { printf (" <= ") ; }
            | '(' '>' expression expression ')'         { printf (" > ") ; }
            | '(' GE expression expression ')'          { printf (" >= ") ; }
            | '(' '=' expression expression ')'         { printf (" = ") ; }
            | '(' EQ expression expression ')'          { printf (" = ") ; }
            | '(' NE expression expression ')'          { printf (" = 0= ") ; }

            | '(' '-' expression ')'                    { printf (" negate ") ; }  // unary minus operator
            ;


operand:      IDENTIF                                  { printf (" %s @ ", $1.code) ; }
            | number                                   { ; }
            ;


number:       NUMBER                                   { printf (" %d ", $1.value) ; }
            ;


%%

int n_line = 1 ;

void yyerror (char *message)
{
    fprintf (stderr, "%s in line %d\n", message, n_line) ;
    printf ("\n") ;
}

char *gen_code (char *name)   // copy the argument to a string in dynamic memory
{
    char *p ;
    int l ;

    l = strlen (name) + 1 ;
    p = (char *) my_malloc (l) ;
    strcpy (p, name) ;

    return p ;
}

char *my_malloc (int nbytes)     // reserve n bytes of dynamic memory
{
    char *p ;
    static long int nb = 0 ;     // used to count the memory
    static int nv = 0 ;          // required in total

    p = malloc (nbytes) ;
    if (p == NULL) {
      fprintf (stderr, "No memory left for additional %d bytes\n", nbytes) ;
      fprintf (stderr, "%ld bytes reserved in %d calls \n", nb, nv) ;
      exit (0) ;
    }
    nb += (long) nbytes ;
    nv++ ;

    return p ;
}

int is_declared (char *name)
{
    t_var *it = declared_vars ;

    while (it != NULL) {
        if (strcmp (it->name, name) == 0) {
            return 1 ;
        }
        it = it->next ;
    }

    return 0 ;
}

void declare_var (char *name)
{
    t_var *new_var = (t_var *) my_malloc (sizeof (t_var)) ;

    new_var->name = gen_code (name) ;
    new_var->next = declared_vars ;
    declared_vars = new_var ;
}


/***************************************************************************/
/***************************** Keyword Section *****************************/
/***************************************************************************/

typedef struct s_keyword { // reserved words and multi-char operators
    char *name ;
    int token ;
} t_keyword ;

t_keyword keywords [] = {
    {"main",        MAIN},
    {"defun",       DEFUN},
    {"setq",        SETQ},
    {"setf",        SETF},
    {"print",       PRINT},
    {"princ",       PRINC},
    {"loop",        LOOP},
    {"while",       WHILE},
    {"do",          DO},
    {"and",         AND},
    {"or",          OR},
    {"not",         NOT},
    {"if",          IF},
    {"progn",       PROGN},
    {"mod",         MOD},

    {"<=",          LE},
    {">=",          GE},
    {"/=",          NE},
    {"!=",          NE},
    {"==",          EQ},
    {"&&",          AND},
    {"||",          OR},

    {NULL,          0}
} ;

t_keyword *search_keyword (char *symbol_name)
{
    int i ;
    t_keyword *sim ;

    i = 0 ;
    sim = keywords ;
    while (sim [i].name != NULL) {
        if (strcmp (sim [i].name, symbol_name) == 0) {
            return &(sim [i]) ;
        }
        i++ ;
    }

    return NULL ;
}


/***************************************************************************/
/******************** Section for the Lexical Analyzer  ********************/
/***************************************************************************/

int yylex ()
{
    int i ;
    int c ;
    int cc ;
    char expandable_ops [] = "!<>=|%&/-*+" ;
    char temp_str [256] ;
    t_keyword *symbol ;

    do {
        c = getchar () ;
        if (c == '#') { // Ignore lines starting with # (#define, #include)
            do {
                c = getchar () ;
            } while (c != '\n') ;
        }
        if (c == '/') { // character / can be the beginning of a comment.
            cc = getchar () ;
            if (cc != '/') {
                ungetc (cc, stdin) ;
            } else {
                c = getchar () ;
                if (c == '@') { // Lines starting with //@ are transcribed as inline output
                    do {
                        c = getchar () ;
                        putchar (c) ;
                    } while (c != '\n' && c != EOF) ;
                    if (c == EOF) {
                        ungetc (c, stdin) ;
                    }
                } else { // comment, ignore the line
                    while (c != '\n' && c != EOF) {
                        c = getchar () ;
                    }
                    if (c == EOF) {
                        ungetc (c, stdin) ;
                    }
                }
            }
        }
        if (c == '\n') {
            n_line++ ;
        }
    } while (c == ' ' || c == '\n' || c == 10 || c == 13 || c == '\t') ;

    if (c == '\"') {
        i = 0 ;
        do {
            c = getchar () ;
            temp_str [i++] = c ;
        } while (c != '\"' && c != EOF && i < 255) ;

        if (i == 256) {
            printf ("WARNING: string with more than 255 characters in line %d\n", n_line) ;
        }

        temp_str [--i] = '\0' ;
        yylval.code = gen_code (temp_str) ;
        return (STRING) ;
    }

    if (c >= '0' && c <= '9') {
        ungetc (c, stdin) ;
        if (scanf ("%d", &yylval.value) != 1) {
            yylval.value = 0 ;
        }
        return NUMBER ;
    }

    if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')) {
        i = 0 ;
        while (((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') ||
            (c >= '0' && c <= '9') || c == '_') && i < 255) {
            temp_str [i++] = tolower (c) ; // all to small letters
            c = getchar () ;
        }
        temp_str [i] = '\0' ;
        ungetc (c, stdin) ;

        yylval.code = gen_code (temp_str) ;
        symbol = search_keyword (yylval.code) ;
        if (symbol == NULL) {
            return (IDENTIF) ;
        }
        return (symbol->token) ;
    }

    if (strchr (expandable_ops, c) != NULL) {
        cc = getchar () ;
        sprintf (temp_str, "%c%c", (char) c, (char) cc) ;
        symbol = search_keyword (temp_str) ;
        if (symbol == NULL) {
            ungetc (cc, stdin) ;
            yylval.code = NULL ;
            return (c) ;
        }
        yylval.code = gen_code (temp_str) ;
        return (symbol->token) ;
    }

    if (c == EOF || c == 255 || c == 26) {
        return 0 ;
    }

    return c ;
}


int main ()
{
    yyparse () ;
    printf ("\n") ;
    return 0 ;
}
