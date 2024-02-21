/*
 * Author: Sawyer Maloney - malonesm@bc.edu
 */
%{
#include <string.h>

#include "errormsg.h"
#include "util.h"
#include "y.tab.h"

int char_pos = 1;
void adjust();
int yywrap();
char *copy_unescaped(char* str);
%}

%option nounput noinput

space [ \t]
ws {space}+
digit [0-9]

%x comment
%%

{ws}        { adjust(); continue; }
\n	        { adjust(); EM_newline(); continue; }
\r	        { adjust(); continue; }
","	        { adjust(); return COMMA; }
for 	    { adjust(); return FOR; }
let         { adjust(); return LET; }
var         { adjust(); return VAR; }
end         { adjust(); return END; }
then        { adjust(); return THEN; }
else        { adjust(); return ELSE; }
while       { adjust(); return WHILE; }
to          { adjust(); return TO; }
do          { adjust(); return DO; }
in          { adjust(); return IN; }
of          { adjust(); return OF; }
break       { adjust(); return BREAK; }
nil         { adjust(); return NIL; }
function    { adjust(); return FUNCTION; }
type        { adjust(); return TYPE; }
array       { adjust(); return ARRAY; }
if          { adjust(); return IF; }
"/*"        { adjust(); BEGIN(comment); continue; }
<comment>"*/"       { adjust(); BEGIN(INITIAL); continue; }
<comment>\n        { adjust(); continue; }
<comment>.         { adjust(); continue; }
:=          { adjust(); return ASSIGN; }
:           { adjust(); return COLON; }
;           { adjust(); return SEMICOLON; }
"("           { adjust(); return LPAREN; }
")"           { adjust(); return RPAREN; }
"["           { adjust(); return LBRACK; }
"]"         { adjust(); return RBRACK; }
"{"           { adjust(); return LBRACE; }
"}"           { adjust(); return RBRACE; }
"."           { adjust(); return DOT; }
"+"           { adjust(); return PLUS; }
"-"           { adjust(); return MINUS; }
"*"          { adjust(); return TIMES; }           
"/"         { adjust(); return DIVIDE; }
"="         { adjust(); return EQ; }
"!="        { adjust(); return NEQ; }
">"         { adjust(); return GT; }
">="        { adjust(); return GE; }
"<"         { adjust(); return LT; }
"<="        { adjust(); return LE; }
"&"         { adjust(); return AND; }
"|"         { adjust(); return OR; }
[a-zA-Z_][a-zA-Z0-9_]*      { adjust(); yylval.sval=make_String(yytext); return ID; }
\"([^"])*\"       { adjust(); yylval.sval = copy_unescaped(yytext); return STRING; }
{digit}+	{ adjust(); yylval.ival = atoi(yytext); return INT; }
.	        { adjust(); EM_error(EM_token_pos, "illegal token"); }

%%
int yywrap() {
    char_pos = 1;
    return 1;
}
void adjust() {
    EM_token_pos = char_pos;
    char_pos += yyleng;
}

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
