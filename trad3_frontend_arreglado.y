/*211, Ivan Ciller Lopez, Mohamed Rida Chahdaoui Moujib, */
/* 100522245@alumnos.uc3m.es, 100522202@alumnos.uc3m.es*/

%{
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <stdlib.h>

int yylex () ;
int yyerror (char *mensaje) ;
char *my_malloc (int) ;
char *gen_code (const char *) ;

char *escape_lisp_string (const char *) ;
char *concat_blocks (const char *, const char *) ;
char *concat_words (const char *, const char *) ;
char *indent_block (const char *) ;
char *wrap_progn (const char *) ;
char *build_defun (const char *, const char *, const char *) ;
char *build_call (const char *, const char *) ;
char *build_binary (const char *, const char *, const char *) ;
char *build_unary (const char *, const char *) ;
char *build_if (const char *, const char *, const char *) ;
char *build_while (const char *, const char *) ;
char *build_for (const char *, const char *, const char *, const char *) ;
char *build_case_block (const char *, const char *) ;
char *build_switch (const char *, const char *) ;
char *translate_printf (char *, char *) ;
char *next_printf_arg (char **) ;
void add_printf_piece (char *, int *, const char *) ;

char temp [4096] ;

#define MAX_LOCALS 256
char *local_vars [MAX_LOCALS] ;
int n_locals = 0 ;
char current_func [256] = "main" ;

typedef struct s_chain {
    char *op ;
    char *arg ;
    struct s_chain *next ;
} t_chain ;

t_chain *new_chain (const char *, const char *, t_chain *) ;
char *fold_chain (const char *, t_chain *) ;

void reset_locals (const char *fname)
{
    int i ;
    for (i = 0 ; i < MAX_LOCALS ; i++)
        local_vars [i] = NULL ;
    n_locals = 0 ;
    strncpy (current_func, fname, sizeof (current_func) - 1) ;
    current_func [sizeof (current_func) - 1] = '\0' ;
}

void add_local (const char *name)
{
    if (n_locals < MAX_LOCALS)
        local_vars [n_locals++] = gen_code (name) ;
}

int is_local (const char *name)
{
    int i ;
    for (i = 0 ; i < n_locals ; i++) {
        if (strcmp (local_vars [i], name) == 0)
            return 1 ;
    }
    return 0 ;
}

char *transform_id (const char *name)
{
    if (is_local (name)) {
        sprintf (temp, "%s_%s", current_func, name) ;
        return gen_code (temp) ;
    }
    return gen_code (name) ;
}

typedef struct s_attr {
    int value ;
    char *code ;
    t_chain *chain ;
} t_attr ;

#define YYSTYPE t_attr

%}

%token NUMBER
%token IDENTIF
%token INTEGER
%token STRING
%token MAIN
%token WHILE
%token IF ELSE
%token FOR SWITCH CASE DEFAULT BREAK RETURN
%token PRINTF PUTS
%token AND OR NOT IGUAL DIFERENTE MENOR_IGUAL MAYOR_IGUAL

%%

axioma:
      top_level_list funcion_main
        {
            if (strlen ($1.code) == 0)
                printf ("%s\n", $2.code) ;
            else
                printf ("%s\n%s\n", $1.code, $2.code) ;
        }
;

top_level_list:
      top_item top_level_list
        { $$.code = concat_blocks ($1.code, $2.code) ; }
    | /* lambda */
        { $$.code = gen_code ("") ; }
;

top_item:
      declaracion ';'
        { $$.code = $1.code ; }
    | funcion
        { $$.code = $1.code ; }
;

funcion:
      INTEGER IDENTIF
        { reset_locals ($2.code) ; }
      '(' parametros ')' '{' declaraciones_locales lista_sentencias '}'
        { $$.code = build_defun ($2.code, $5.code, concat_blocks ($8.code, $9.code)) ; }
    | IDENTIF
        { reset_locals ($1.code) ; }
      '(' parametros ')' '{' declaraciones_locales lista_sentencias '}'
        { $$.code = build_defun ($1.code, $4.code, concat_blocks ($7.code, $8.code)) ; }
;

funcion_main:
      INTEGER MAIN
        { reset_locals ("main") ; }
      '(' ')' '{' declaraciones_locales lista_sentencias '}'
        { $$.code = build_defun ("main", "", concat_blocks ($7.code, $8.code)) ; }
    | MAIN
        { reset_locals ("main") ; }
      '(' ')' '{' declaraciones_locales lista_sentencias '}'
        { $$.code = build_defun ("main", "", concat_blocks ($6.code, $7.code)) ; }
;

parametros:
      parametro resto_parametros
        { $$.code = concat_words ($1.code, $2.code) ; }
    | /* lambda */
        { $$.code = gen_code ("") ; }
;

resto_parametros:
      ',' parametro resto_parametros
        { $$.code = concat_words ($2.code, $3.code) ; }
    | /* lambda */
        { $$.code = gen_code ("") ; }
;

parametro:
      INTEGER IDENTIF
        { $$.code = gen_code ($2.code) ; }
    | IDENTIF
        { $$.code = gen_code ($1.code) ; }
;

declaraciones_locales:
      declaracion_local ';' declaraciones_locales
        { $$.code = concat_blocks ($1.code, $3.code) ; }
    | /* lambda */
        { $$.code = gen_code ("") ; }
;

declaracion:
      INTEGER lista_vars
        { $$.code = $2.code ; }
;

declaracion_local:
      INTEGER lista_vars_locales
        { $$.code = $2.code ; }
;

lista_vars:
      vars resto_vars
        { $$.code = concat_blocks ($1.code, $2.code) ; }
;

resto_vars:
      ',' vars resto_vars
        { $$.code = concat_blocks ($2.code, $3.code) ; }
    | /* lambda */
        { $$.code = gen_code ("") ; }
;

lista_vars_locales:
      vars_locales resto_vars_locales
        { $$.code = concat_blocks ($1.code, $2.code) ; }
;

resto_vars_locales:
      ',' vars_locales resto_vars_locales
        { $$.code = concat_blocks ($2.code, $3.code) ; }
    | /* lambda */
        { $$.code = gen_code ("") ; }
;

vars:
      IDENTIF
        {
            sprintf (temp, "(setq %s 0)", $1.code) ;
            $$.code = gen_code (temp) ;
        }
    | IDENTIF '=' cte
        {
            sprintf (temp, "(setq %s %s)", $1.code, $3.code) ;
            $$.code = gen_code (temp) ;
        }
    | IDENTIF '[' cte ']'
        {
            sprintf (temp, "(setq %s (make-array %s))", $1.code, $3.code) ;
            $$.code = gen_code (temp) ;
        }
;

vars_locales:
      IDENTIF
        {
            add_local ($1.code) ;
            sprintf (temp, "(setq %s_%s 0)", current_func, $1.code) ;
            $$.code = gen_code (temp) ;
        }
    | IDENTIF '=' cte
        {
            add_local ($1.code) ;
            sprintf (temp, "(setq %s_%s %s)", current_func, $1.code, $3.code) ;
            $$.code = gen_code (temp) ;
        }
    | IDENTIF '[' cte ']'
        {
            add_local ($1.code) ;
            sprintf (temp, "(setq %s_%s (make-array %s))", current_func, $1.code, $3.code) ;
            $$.code = gen_code (temp) ;
        }
;

cte:
      NUMBER
        {
            sprintf (temp, "%d", $1.value) ;
            $$.code = gen_code (temp) ;
        }
    | '+' NUMBER
        {
            sprintf (temp, "%d", $2.value) ;
            $$.code = gen_code (temp) ;
        }
    | '-' NUMBER
        {
            sprintf (temp, "-%d", $2.value) ;
            $$.code = gen_code (temp) ;
        }
;

lista_sentencias:
      sentencia_item lista_sentencias
        { $$.code = concat_blocks ($1.code, $2.code) ; }
    | /* lambda */
        { $$.code = gen_code ("") ; }
;

sentencia_item:
      sentencia ';'
        { $$.code = $1.code ; }
    | sentencia_control
        { $$.code = $1.code ; }
;

lista_argumentos:
      argumento_printf resto_argumentos
        {
            if (strlen ($2.code) == 0)
                $$.code = gen_code ($1.code) ;
            else {
                sprintf (temp, "%s\037%s", $1.code, $2.code) ;
                $$.code = gen_code (temp) ;
            }
        }
;

resto_argumentos:
      ',' argumento_printf resto_argumentos
        {
            if (strlen ($3.code) == 0)
                $$.code = gen_code ($2.code) ;
            else {
                sprintf (temp, "%s\037%s", $2.code, $3.code) ;
                $$.code = gen_code (temp) ;
            }
        }
    | /* lambda */
        { $$.code = gen_code ("") ; }
;

argumento_printf:
      expresion
        { $$.code = $1.code ; }
    | STRING
        {
            char *esc = escape_lisp_string ($1.code) ;
            sprintf (temp, "\"%s\"", esc) ;
            $$.code = gen_code (temp) ;
        }
;

lista_expr:
      expresion resto_expr
        { $$.code = concat_words ($1.code, $2.code) ; }
    | /* lambda */
        { $$.code = gen_code ("") ; }
;

resto_expr:
      ',' expresion resto_expr
        { $$.code = concat_words ($2.code, $3.code) ; }
    | /* lambda */
        { $$.code = gen_code ("") ; }
;

sentencia:
      IDENTIF '=' expresion
        {
            char *final_id = transform_id ($1.code) ;
            sprintf (temp, "(setf %s %s)", final_id, $3.code) ;
            $$.code = gen_code (temp) ;
        }
    | IDENTIF '[' expresion ']' '=' expresion
        {
            char *final_id = transform_id ($1.code) ;
            sprintf (temp, "(setf (aref %s %s) %s)", final_id, $3.code, $6.code) ;
            $$.code = gen_code (temp) ;
        }
    | RETURN expresion
        {
            sprintf (temp, "(return-from %s %s)", current_func, $2.code) ;
            $$.code = gen_code (temp) ;
        }
    | PUTS '(' STRING ')'
        {
            char *esc = escape_lisp_string ($3.code) ;
            sprintf (temp, "(print \"%s\")", esc) ;
            $$.code = gen_code (temp) ;
        }
    | PRINTF '(' STRING ')'
        { $$.code = translate_printf ($3.code, "") ; }
    | PRINTF '(' STRING ',' lista_argumentos ')'
        { $$.code = translate_printf ($3.code, $5.code) ; }
    | IDENTIF '(' lista_expr ')'
        { $$.code = build_call ($1.code, $3.code) ; }
;

sentencia_control:
      WHILE '(' expresion ')' '{' lista_sentencias '}'
        { $$.code = build_while ($3.code, $6.code) ; }
    | IF '(' expresion ')' '{' lista_sentencias '}'
        { $$.code = build_if ($3.code, $6.code, "") ; }
    | IF '(' expresion ')' '{' lista_sentencias '}' ELSE '{' lista_sentencias '}'
        { $$.code = build_if ($3.code, $6.code, $10.code) ; }
    | FOR '(' for_init ';' expresion ';' for_step ')' '{' lista_sentencias '}'
        { $$.code = build_for ($3.code, $5.code, $7.code, $10.code) ; }
    | SWITCH '(' expresion ')' '{' lista_cases '}'
        { $$.code = build_switch ($3.code, $6.code) ; }
;

for_init:
      declaracion
        { $$.code = $1.code ; }
    | IDENTIF '=' expresion
        {
            char *final_id = transform_id ($1.code) ;
            sprintf (temp, "(setf %s %s)", final_id, $3.code) ;
            $$.code = gen_code (temp) ;
        }
;

for_step:
      IDENTIF '(' IDENTIF ')'
        {
            char *final_id = transform_id ($3.code) ;
            if (strcmp ($1.code, "inc") == 0)
                sprintf (temp, "(setf %s (+ %s 1))", final_id, final_id) ;
            else if (strcmp ($1.code, "dec") == 0)
                sprintf (temp, "(setf %s (- %s 1))", final_id, final_id) ;
            else {
                fprintf (stderr, "Error: en for solo se permite INC(x) o DEC(x)\n") ;
                sprintf (temp, "(setf %s %s)", final_id, final_id) ;
            }
            $$.code = gen_code (temp) ;
        }
    | IDENTIF '=' expresion
        {
            char *final_id = transform_id ($1.code) ;
            sprintf (temp, "(setf %s %s)", final_id, $3.code) ;
            $$.code = gen_code (temp) ;
        }
;

lista_cases:
      case_block lista_cases
        { $$.code = concat_blocks ($1.code, $2.code) ; }
    | /* lambda */
        { $$.code = gen_code ("") ; }
;

case_block:
      CASE cte ':' lista_sentencias BREAK ';'
        { $$.code = build_case_block ($2.code, $4.code) ; }
    | DEFAULT ':' lista_sentencias
        { $$.code = build_case_block ("otherwise", $3.code) ; }
    | DEFAULT ':' lista_sentencias BREAK ';'
        { $$.code = build_case_block ("otherwise", $3.code) ; }
;

expresion:
      expr_or
        { $$.code = $1.code ; }
;

expr_or:
      expr_and resto_or
        { $$.code = fold_chain ($1.code, $2.chain) ; }
;

resto_or:
      OR expr_and resto_or
        { $$.chain = new_chain ("or", $2.code, $3.chain) ; }
    | /* lambda */
        { $$.chain = NULL ; }
;

expr_and:
      expr_igualdad resto_and
        { $$.code = fold_chain ($1.code, $2.chain) ; }
;

resto_and:
      AND expr_igualdad resto_and
        { $$.chain = new_chain ("and", $2.code, $3.chain) ; }
    | /* lambda */
        { $$.chain = NULL ; }
;

expr_igualdad:
      expr_relacional resto_igualdad
        { $$.code = fold_chain ($1.code, $2.chain) ; }
;

resto_igualdad:
      IGUAL expr_relacional resto_igualdad
        { $$.chain = new_chain ("=", $2.code, $3.chain) ; }
    | DIFERENTE expr_relacional resto_igualdad
        { $$.chain = new_chain ("/=", $2.code, $3.chain) ; }
    | /* lambda */
        { $$.chain = NULL ; }
;

expr_relacional:
      expr_aditiva resto_relacional
        { $$.code = fold_chain ($1.code, $2.chain) ; }
;

resto_relacional:
      '<' expr_aditiva resto_relacional
        { $$.chain = new_chain ("<", $2.code, $3.chain) ; }
    | '>' expr_aditiva resto_relacional
        { $$.chain = new_chain (">", $2.code, $3.chain) ; }
    | MENOR_IGUAL expr_aditiva resto_relacional
        { $$.chain = new_chain ("<=", $2.code, $3.chain) ; }
    | MAYOR_IGUAL expr_aditiva resto_relacional
        { $$.chain = new_chain (">=", $2.code, $3.chain) ; }
    | /* lambda */
        { $$.chain = NULL ; }
;

expr_aditiva:
      expr_multiplicativa resto_aditiva
        { $$.code = fold_chain ($1.code, $2.chain) ; }
;

resto_aditiva:
      '+' expr_multiplicativa resto_aditiva
        { $$.chain = new_chain ("+", $2.code, $3.chain) ; }
    | '-' expr_multiplicativa resto_aditiva
        { $$.chain = new_chain ("-", $2.code, $3.chain) ; }
    | /* lambda */
        { $$.chain = NULL ; }
;

expr_multiplicativa:
      expr_unaria resto_multiplicativa
        { $$.code = fold_chain ($1.code, $2.chain) ; }
;

resto_multiplicativa:
      '*' expr_unaria resto_multiplicativa
        { $$.chain = new_chain ("*", $2.code, $3.chain) ; }
    | '/' expr_unaria resto_multiplicativa
        { $$.chain = new_chain ("/", $2.code, $3.chain) ; }
    | '%' expr_unaria resto_multiplicativa
        { $$.chain = new_chain ("mod", $2.code, $3.chain) ; }
    | /* lambda */
        { $$.chain = NULL ; }
;

expr_unaria:
      NOT expr_unaria
        { $$.code = build_unary ("not", $2.code) ; }
    | '+' expr_unaria
        { $$.code = $2.code ; }
    | '-' expr_unaria
        { $$.code = build_unary ("-", $2.code) ; }
    | operando
        { $$.code = $1.code ; }
;

operando:
      IDENTIF
        {
            char *final_id = transform_id ($1.code) ;
            $$.code = gen_code (final_id) ;
        }
    | NUMBER
        {
            sprintf (temp, "%d", $1.value) ;
            $$.code = gen_code (temp) ;
        }
    | IDENTIF '[' expresion ']'
        {
            char *final_id = transform_id ($1.code) ;
            sprintf (temp, "(aref %s %s)", final_id, $3.code) ;
            $$.code = gen_code (temp) ;
        }
    | IDENTIF '(' lista_expr ')'
        { $$.code = build_call ($1.code, $3.code) ; }
    | '(' expresion ')'
        { $$.code = $2.code ; }
;

%%

int n_line = 1 ;

int yyerror (char *mensaje)
{
    fprintf (stderr, "%s en la linea %d\n", mensaje, n_line) ;
    return 0 ;
}

char *gen_code (const char *name)
{
    char *p ;
    int l = strlen (name) + 1 ;
    p = (char *) my_malloc (l) ;
    strcpy (p, name) ;
    return p ;
}

char *my_malloc (int nbytes)
{
    char *p = (char *) malloc (nbytes) ;
    if (p == NULL) {
        fprintf (stderr, "No queda memoria\n") ;
        exit (0) ;
    }
    return p ;
}

char *concat_blocks (const char *a, const char *b)
{
    char buffer [32768] ;

    if (a == NULL || a [0] == '\0')
        return gen_code (b == NULL ? "" : b) ;
    if (b == NULL || b [0] == '\0')
        return gen_code (a) ;

    sprintf (buffer, "%s\n%s", a, b) ;
    return gen_code (buffer) ;
}

char *concat_words (const char *a, const char *b)
{
    char buffer [8192] ;

    if (a == NULL || a [0] == '\0')
        return gen_code (b == NULL ? "" : b) ;
    if (b == NULL || b [0] == '\0')
        return gen_code (a) ;

    sprintf (buffer, "%s %s", a, b) ;
    return gen_code (buffer) ;
}

char *indent_block (const char *src)
{
    char buffer [32768] ;
    int i = 0, j = 0 ;

    if (src == NULL || src [0] == '\0')
        return gen_code ("") ;

    buffer [j++] = ' ' ;
    buffer [j++] = ' ' ;
    buffer [j++] = ' ' ;

    while (src [i] != '\0' && j < 32760) {
        buffer [j++] = src [i] ;
        if (src [i] == '\n' && src [i + 1] != '\0') {
            buffer [j++] = ' ' ;
            buffer [j++] = ' ' ;
            buffer [j++] = ' ' ;
        }
        i++ ;
    }

    buffer [j] = '\0' ;
    return gen_code (buffer) ;
}

char *wrap_progn (const char *block)
{
    char buffer [32768] ;
    char *indented ;

    if (block == NULL || block [0] == '\0')
        return gen_code ("(progn)") ;

    indented = indent_block (block) ;
    sprintf (buffer, "(progn\n%s\n)", indented) ;
    return gen_code (buffer) ;
}

char *build_defun (const char *name, const char *params, const char *body)
{
    char buffer [32768] ;
    char *indented ;

    if (body == NULL || body [0] == '\0') {
        sprintf (buffer, "(defun %s (%s))", name, params) ;
        return gen_code (buffer) ;
    }

    indented = indent_block (body) ;
    sprintf (buffer, "(defun %s (%s)\n%s\n)", name, params, indented) ;
    return gen_code (buffer) ;
}

char *build_call (const char *name, const char *args)
{
    char buffer [8192] ;

    if (args == NULL || args [0] == '\0')
        sprintf (buffer, "(%s)", name) ;
    else
        sprintf (buffer, "(%s %s)", name, args) ;

    return gen_code (buffer) ;
}

char *build_binary (const char *op, const char *left, const char *right)
{
    char buffer [8192] ;
    sprintf (buffer, "(%s %s %s)", op, left, right) ;
    return gen_code (buffer) ;
}

char *build_unary (const char *op, const char *expr)
{
    char buffer [8192] ;
    sprintf (buffer, "(%s %s)", op, expr) ;
    return gen_code (buffer) ;
}

char *build_if (const char *cond, const char *then_block, const char *else_block)
{
    char buffer [32768] ;
    char *then_code = wrap_progn (then_block) ;

    if (else_block == NULL || else_block [0] == '\0') {
        sprintf (buffer, "(if %s %s)", cond, then_code) ;
    } else {
        char *else_code = wrap_progn (else_block) ;
        sprintf (buffer, "(if %s %s %s)", cond, then_code, else_code) ;
    }

    return gen_code (buffer) ;
}

char *build_while (const char *cond, const char *body)
{
    char buffer [32768] ;
    char *indented = indent_block (body) ;

    if (body == NULL || body [0] == '\0')
        sprintf (buffer, "(loop while %s do)", cond) ;
    else
        sprintf (buffer, "(loop while %s do\n%s\n)", cond, indented) ;

    return gen_code (buffer) ;
}

char *build_for (const char *init, const char *cond, const char *step, const char *body)
{
    char buffer [32768] ;
    char *loop_body = concat_blocks (body, step) ;
    char *indented_loop = indent_block (loop_body) ;

    sprintf (buffer,
             "(progn\n   %s\n   (loop while %s do\n%s\n   )\n)",
             init, cond, indented_loop) ;
    return gen_code (buffer) ;
}

char *build_case_block (const char *label, const char *body)
{
    char buffer [32768] ;
    char *progn_code = wrap_progn (body) ;
    sprintf (buffer, "(%s %s)", label, progn_code) ;
    return gen_code (buffer) ;
}

char *build_switch (const char *expr, const char *cases)
{
    char buffer [32768] ;
    char *indented = indent_block (cases) ;

    if (cases == NULL || cases [0] == '\0')
        sprintf (buffer, "(case %s)", expr) ;
    else
        sprintf (buffer, "(case %s\n%s\n)", expr, indented) ;

    return gen_code (buffer) ;
}

char *escape_lisp_string (const char *src)
{
    char buffer [8192] ;
    int i = 0, j = 0 ;

    while (src [i] != '\0' && j < 8188) {
        if (src [i] == '"' || src [i] == '\\')
            buffer [j++] = '\\' ;
        buffer [j++] = src [i++] ;
    }

    buffer [j] = '\0' ;
    return gen_code (buffer) ;
}

t_chain *new_chain (const char *op, const char *arg, t_chain *next)
{
    t_chain *node = (t_chain *) my_malloc (sizeof (t_chain)) ;
    node->op = gen_code (op) ;
    node->arg = gen_code (arg) ;
    node->next = next ;
    return node ;
}

char *fold_chain (const char *left, t_chain *chain)
{
    char *acc ;

    if (chain == NULL)
        return gen_code (left) ;

    acc = build_binary (chain->op, left, chain->arg) ;
    return fold_chain (acc, chain->next) ;
}

char *next_printf_arg (char **cursor)
{
    char buffer [8192] ;
    int i = 0 ;

    if (cursor == NULL || *cursor == NULL || **cursor == '\0')
        return NULL ;

    while (**cursor != '\0' && **cursor != '\037' && i < 8191) {
        buffer [i++] = **cursor ;
        (*cursor)++ ;
    }

    buffer [i] = '\0' ;

    if (**cursor == '\037')
        (*cursor)++ ;

    return gen_code (buffer) ;
}

void add_printf_piece (char *dest, int *npieces, const char *piece)
{
    if (piece == NULL || piece [0] == '\0')
        return ;

    if (*npieces == 0)
        strcpy (dest, piece) ;
    else {
        strcat (dest, "\n") ;
        strcat (dest, piece) ;
    }

    (*npieces)++ ;
}

char *translate_printf (char *format, char *args)
{
    char result [32768] ;
    char literal [8192] ;
    char piece [8192] ;
    char final_code [32768] ;
    char *cursor = args ;
    char *arg ;
    int npieces = 0 ;
    int i = 0, j = 0 ;

    result [0] = '\0' ;
    literal [0] = '\0' ;

    while (format [i] != '\0') {
        if (format [i] == '%' && format [i + 1] != '\0') {
            if (format [i + 1] == '%') {
                literal [j++] = '%' ;
                i += 2 ;
                continue ;
            }

            literal [j] = '\0' ;
            if (j > 0) {
                char *esc = escape_lisp_string (literal) ;
                sprintf (piece, "(princ \"%s\")", esc) ;
                add_printf_piece (result, &npieces, piece) ;
                j = 0 ;
                literal [0] = '\0' ;
            }

            arg = next_printf_arg (&cursor) ;
            if (arg != NULL) {
                sprintf (piece, "(princ %s)", arg) ;
                add_printf_piece (result, &npieces, piece) ;
            }

            i += 2 ;
            continue ;
        }

        if (format [i] == '\\' && format [i + 1] != '\0') {
            literal [j++] = '\\' ;
            literal [j++] = format [i + 1] ;
            i += 2 ;
            continue ;
        }

        literal [j++] = format [i++] ;
    }

    literal [j] = '\0' ;
    if (j > 0) {
        char *esc = escape_lisp_string (literal) ;
        sprintf (piece, "(princ \"%s\")", esc) ;
        add_printf_piece (result, &npieces, piece) ;
    }

    while ((arg = next_printf_arg (&cursor)) != NULL) {
        sprintf (piece, "(princ %s)", arg) ;
        add_printf_piece (result, &npieces, piece) ;
    }

    if (npieces == 0)
        return gen_code ("") ;

    if (npieces == 1)
        return gen_code (result) ;

    sprintf (final_code, "(progn\n%s\n)", indent_block (result)) ;
    return gen_code (final_code) ;
}

typedef struct s_keyword {
    char *name ;
    int token ;
} t_keyword ;

t_keyword keywords [] = {
    "main",     MAIN,
    "printf",   PRINTF,
    "puts",     PUTS,
    "int",      INTEGER,
    "while",    WHILE,
    "if",       IF,
    "else",     ELSE,
    "for",      FOR,
    "switch",   SWITCH,
    "case",     CASE,
    "default",  DEFAULT,
    "break",    BREAK,
    "return",   RETURN,
    "&&",       AND,
    "||",       OR,
    "==",       IGUAL,
    "!=",       DIFERENTE,
    "<=",       MENOR_IGUAL,
    ">=",       MAYOR_IGUAL,
    "!",        NOT,
    NULL,         0
} ;

t_keyword *search_keyword (char *symbol_name)
{
    int i = 0 ;
    while (keywords [i].name != NULL) {
        if (strcmp (keywords [i].name, symbol_name) == 0)
            return &keywords [i] ;
        i++ ;
    }
    return NULL ;
}

int yylex ()
{
    int i ;
    unsigned char c ;
    unsigned char cc ;
    char ops_expandibles [] = "!<=|>%&/+-*" ;
    char temp_str [256] ;
    t_keyword *symbol ;

    do {
        c = getchar () ;

        if (c == '#') {
            do {
                c = getchar () ;
            } while (c != '\n') ;
        }

        if (c == '/') {
            cc = getchar () ;
            if (cc != '/') {
                ungetc (cc, stdin) ;
            } else {
                c = getchar () ;
                if (c == '@') {
                    do {
                        c = getchar () ;
                        putchar (c) ;
                    } while (c != '\n' && c != EOF) ;
                    if (c == EOF)
                        ungetc (c, stdin) ;
                } else {
                    while (c != '\n' && c != EOF)
                        c = getchar () ;
                    if (c == EOF)
                        ungetc (c, stdin) ;
                }
            }
        } else if (c == '\\') {
            c = getchar () ;
        }

        if (c == '\n')
            n_line++ ;

    } while (c == ' ' || c == '\n' || c == 10 || c == 13 || c == '\t') ;

    if (c == '"') {
        i = 0 ;
        do {
            c = getchar () ;
            temp_str [i++] = c ;
        } while (c != '"' && i < 255) ;
        if (i == 256)
            fprintf (stderr, "AVISO: string con mas de 255 caracteres en linea %d\n", n_line) ;
        temp_str [--i] = '\0' ;
        yylval.code = gen_code (temp_str) ;
        return STRING ;
    }

    if (c == '.' || (c >= '0' && c <= '9')) {
        ungetc (c, stdin) ;
        scanf ("%d", &yylval.value) ;
        return NUMBER ;
    }

    if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')) {
        i = 0 ;
        while (((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') ||
                (c >= '0' && c <= '9') || c == '_') && i < 255) {
            temp_str [i++] = tolower (c) ;
            c = getchar () ;
        }
        temp_str [i] = '\0' ;
        ungetc (c, stdin) ;

        yylval.code = gen_code (temp_str) ;
        symbol = search_keyword (yylval.code) ;
        if (symbol == NULL)
            return IDENTIF ;
        return symbol->token ;
    }

    if (strchr (ops_expandibles, c) != NULL) {
        cc = getchar () ;
        sprintf (temp_str, "%c%c", (char) c, (char) cc) ;
        symbol = search_keyword (temp_str) ;
        if (symbol == NULL) {
            ungetc (cc, stdin) ;
            yylval.code = NULL ;
            return c ;
        }
        yylval.code = gen_code (temp_str) ;
        return symbol->token ;
    }

    if (c == EOF || c == 255 || c == 26)
        return 0 ;

    return c ;
}

int main ()
{
    yyparse () ;
    return 0 ;
}
