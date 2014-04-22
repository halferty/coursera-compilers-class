/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
  if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
    YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;
int comment_caller;
int comment_depth;
int string_invalid = 0;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;


/*
 *  Add Your own definitions here
 */


%}

BEGIN(INITIAL);
/*
 * Define names for regular expressions here.
 */

A   [aA]
B   [bB]
C   [cC]
D   [dD]
E   [eE]
F   [fF]
G   [gG]
H   [hH]
I   [iI]
J   [jJ]
K   [kK]
L   [lL]
M   [mM]
N   [nN]
O   [oO]
P   [pP]
Q   [qQ]
R   [rR]
S   [sS]
T   [tT]
U   [uU]
V   [vV]
W   [wW]
X   [xX]
Y   [yY]
Z   [zZ]

DARROW              =>
DIGITS              [0-9]+
TYPE                [A-Z][0-9a-zA-Z_]*
OBJECT              [a-z][0-9a-zA-Z_]*
LINE_COMMENT        --.*
DASH                [\-]
INVALID             [\x01-\x19]
TAB                 [\t]
WHITESPACE          [ \f\t\v\r]+



 /********************* Define start conditions *********************/
%x str
%x comment
%x line_comment

 /********************* Matches start here *********************/
%%


<INITIAL>{
   /* Count the lines */
  \n      curr_lineno++;

  {DIGITS} { cool_yylval.symbol = inttable.add_string(yytext); return INT_CONST; }
  ";" return ';';
  "{" return '{';
  "}" return '}';
  "(" return '(';
  "," return ',';
  ")" return ')';
  ":" return ':';
  "@" return '@';
  "." return '.';
  "+" return '+';
  "-" return '-';
  "*" return '*';
  "/" return '/';
  "~" return '~';
  "<" return '<';
  "=" return '=';
  "<-" return ASSIGN;
  "=>" return DARROW;
  "<=" return LE;


  {LINE_COMMENT} { ; }
  {WHITESPACE} { ; }

  \"                        { string_buf_ptr = string_buf; BEGIN(str); }

  /* reserved words */
  {C}{A}{S}{E}              return CASE;
  {C}{L}{A}{S}{S}           return CLASS;
  {E}{S}{A}{C}              return ESAC;
  {E}{L}{S}{E}              return ELSE;
  {F}{I}                    return FI;
  {I}{F}                    return IF;
  {I}{N}                    return IN;
  {I}{N}{H}{E}{R}{I}{T}{S}  return INHERITS;
  {I}{S}{V}{O}{I}{D}        return ISVOID;
  {L}{E}{T}                 return LET;
  {L}{O}{O}{P}              return LOOP;
  {N}{E}{W}                 return NEW;
  {N}{O}{T}                 return NOT;
  {O}{F}                    return OF;
  {P}{O}{O}{L}              return POOL;
  {T}{H}{E}{N}              return THEN;
  {W}{H}{I}{L}{E}           return WHILE;

  t{R}{U}{E} {
    cool_yylval.boolean = true;
    return BOOL_CONST;
  }
  f{A}{L}{S}{E} {
    cool_yylval.boolean = false;
    return BOOL_CONST;
  }

  {OBJECT} { cool_yylval.symbol = idtable.add_string(yytext, yyleng); return (OBJECTID); }

  {TYPE} {cool_yylval.symbol = idtable.add_string(yytext, yyleng); return (TYPEID); }

  "(*" { comment_depth = 1; BEGIN(comment); }
  "*)" { cool_yylval.error_msg = ("Unmatched *)"); return ERROR; }
  "!" { cool_yylval.error_msg = ("!"); return ERROR; }
  "#" { cool_yylval.error_msg = ("#"); return ERROR; }
  "$" { cool_yylval.error_msg = ("$"); return ERROR; }
  "%" { cool_yylval.error_msg = ("%"); return ERROR; }
  "^" { cool_yylval.error_msg = ("^"); return ERROR; }
  "&" { cool_yylval.error_msg = ("&"); return ERROR; }
  "_" { cool_yylval.error_msg = ("_"); return ERROR; }
  ">" { cool_yylval.error_msg = (">"); return ERROR; }
  "?" { cool_yylval.error_msg = ("?"); return ERROR; }
  "`" { cool_yylval.error_msg = ("`"); return ERROR; }
  "[" { cool_yylval.error_msg = ("["); return ERROR; }
  "]" { cool_yylval.error_msg = ("]"); return ERROR; }
  "\\" { cool_yylval.error_msg = ("\\"); return ERROR; }
  "|"  { cool_yylval.error_msg = ("|"); return ERROR; }
  [\000-\039] {
    cool_yylval.error_msg = (yytext);
    return ERROR;
  }

}



<str>{
  [\0] {
    cool_yylval.error_msg = ("String contains null character.");
    string_invalid = 1;
    return ERROR;
  }
  \" {
    BEGIN(INITIAL);
    *string_buf_ptr = '\0';
    if (string_invalid) {
      string_invalid = 0;
    } else {
      cool_yylval.symbol = stringtable.add_string(string_buf);
      return STR_CONST;
    }
  }
  [^\\\n\"\0]+ {
    char *yptr = yytext;
    while ( *yptr ) {
      if (*yptr < 040 ) {
        if (*yptr == 011) {
          yptr++;
          *string_buf_ptr++ = '\t';
        } else if (*yptr == 012) {
          yptr++;
          *string_buf_ptr++ = '\n';
        } else if (*yptr == 014) {
          yptr++;
          *string_buf_ptr++ = '\f';
        } else {
          *string_buf_ptr++ = '\\';
          *string_buf_ptr++ = '0';
          *string_buf_ptr++ = (char)(((*yptr >> 3) & 7) +060);
          *string_buf_ptr++ = (char)((*yptr & 7) + 060);
          yptr++;
        }
      } else {
        *string_buf_ptr++ = *yptr++;
      }
    }
  }
  \\\0 {
    printf("ERROR \"String contains escaped null character.\"\n\n");
    yyterminate();
  }
  \\\" {
    *string_buf_ptr++ = '\\';
    *string_buf_ptr++ = '\"';
  }
  \\\n {
    *string_buf_ptr++ = '\n';
  }
  \n {
    ++curr_lineno;
    BEGIN(INITIAL);
    cool_yylval.error_msg = ("Unterminated string constant");
    return ERROR;
  }
  \\\t {
    *string_buf_ptr++ = '\\';
    *string_buf_ptr++ = 't';
  }
  \\\f {
    *string_buf_ptr++ = '\\';
    *string_buf_ptr++ = 'f';
  }
  \\\b {
    *string_buf_ptr++ = '\\';
    *string_buf_ptr++ = 'b';
  }
  \\t {
    *string_buf_ptr++ = '\t';
  }
  \\f {
    *string_buf_ptr++ = '\\';
    *string_buf_ptr++ = 'f';
  }
  \\b {
    *string_buf_ptr++ = '\\';
    *string_buf_ptr++ = 'b';
  }
  \\n {
    *string_buf_ptr++ = '\n';
  }
  \\\\ {
    *string_buf_ptr++ = '\\';
  }
  \\\\[a-zA-Z0-9] {
    *string_buf_ptr++ = '\\';
    *string_buf_ptr++ = '\\';
    *string_buf_ptr++ = yytext[2];
  }
  \\[a-zA-Z0-9] {
    *string_buf_ptr++ = yytext[1];
  }
  <<EOF>> {
    printf("ERROR \"EOF in string constant\"\n\n");
    yyterminate();
  }
}

<comment>{
  "*)" {
    if (--comment_depth == 0) {
      BEGIN(INITIAL);
    }
  }
  "(*" {
    comment_depth++;
  }
  . { ; }
  \n                  ++curr_lineno;
  <<EOF>> {
    printf("ERROR \"EOF in comment\"\n\n");
    yyterminate();}
}


%%
