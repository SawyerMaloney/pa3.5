%{
#include <stdio.h>
#include <string.h>

#include "absyn.h"
#include "errormsg.h"
#include "util.h"
#include "y.tab.h"

#define YY_USER_ACTION {yylloc.first_line = yylineno; \
   yylloc.first_column = colnum; \
   colnum = colnum + yyleng; \
   yylloc.last_column = colnum; \
   yylloc.last_line = yylineno; \
}

int colnum = 1;

E_Pos to_E_Pos(YYLTYPE pos);
%}

%option nounput noinput

space [ \t\r]
ws {space}+
digit [0-9]
letter [a-zA-Z]
alnum [a-zA-Z0-9_]

%%

{ws}        { continue; }
\n	        { ++yylineno; colnum = 1; continue; }
\r	        { continue; }
\t          { continue; }
","	        { return COMMA; }
for 	    { return FOR; }
let         { return LET; }
var         { return VAR; }
end         { return END; }
then        { return THEN; }
else        { return ELSE; }
while       { return WHILE; }
to          { return TO; }
do          { return DO; }
in          { return IN; }
of          { return OF; }
break       { return BREAK; }
nil         { return NIL; }
function    { return FUNCTION; }
type        { return TYPE; }
array       { return ARRAY; }
if          { return IF; }
"/*"        { BEGIN(comment); continue; }
<comment>"*/"      { BEGIN(INITIAL); continue; }
<comment>\n        { continue; }
<comment>.         { continue; }
:=          { return ASSIGN; }
:           { return COLON; }
;           { return SEMICOLON; }
"("         { return LPAREN; }
")"         { return RPAREN; }
"["         { return LBRACK; }
"]"         { return RBRACK; }
"{"         { return LBRACE; }
"}"         { return RBRACE; }
"."         { return DOT; }
"+"         { return PLUS; }
"-"         { return MINUS; }
"*"         { return TIMES; }           
"/"         { return DIVIDE; }
"="         { return EQ; }
"!="        { return NEQ; }
">"         { return GT; }
">="        { return GE; }
"<"         { return LT; }
"<="        { return LE; }
"&"         { return AND; }
"|"         { return OR; }

[a-zA-Z_][a-zA-Z0-9_]*      { yylval.sval=make_String(yytext); return ID; }
\"([^"])*\"       { yylval.sval = copy_unescaped(yytext); return STRING; }
{digit}+	{ yylval.ival = atoi(yytext); return INT; }
.	        { EM_error(to_E_Pos(yylloc), "illegal token: %s", yytext); }

char *copy_unescaped(char *str) {
    char *p = (char *) malloc(strlen(str) - 1); // we need size for null term. but not for quotations
    int sl = strlen(str);
    int _ = 0; // placing in p
    int i_to_add = 0;
    // iterate through the string
    for (int i = 1; i < sl - 1;) {
        if (str[i] == '\\') {
            if (i+1 < sl) {
                if (str[i+1] == 'n') {
                    *(p + _) = '\n';
                    i_to_add = 2;
                } else if (str[i+1] == 't') {
                    *(p + _) = '\t';
                    i_to_add = 2;
                } else if (str[i+1] == '\"') {
                    *(p + _) = '\"';
                    i_to_add = 2;
                } else if (str[i+1] == '\\') {
                    *(p + _) = '\\';
                    i_to_add = 2;
                } else if (str[i+1] == '^') {
                    // take whatever is next and slap it minus 0x40
                    *(p + _) = str[i+2] - 64;
                    i_to_add = 3;
                } else {
                    // check for octal code
                    if (str[i+1] >= 48 && str[i+1] <= 56) {
                        char *a = (char *) malloc(4);
                        *a = str[i+1];
                        *(a+1) = str[i+2];
                        *(a+2) = str[i+3];
                        *(a+3) = '\0';
                        *(p + _) = strtol(a, NULL, 8);
                        i_to_add = 4;
                    }
                }
            }
        } else {
            *(p + _) = str[i];
            i_to_add = 1;
        }
        _++;
        i += i_to_add;
        i_to_add = 0;
    }
    *(p + _) = '\0';
    return p;
}

%%

int yywrap() {
    return 1;
}

