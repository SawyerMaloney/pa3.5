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

{ws}              { continue; }
\n                { ++yylineno; colnum = 1; continue; }
","               { return COMMA; }
for               { return FOR; }
{digit}+          { yylval.ival = atoi(yytext); return INT; }
.                 { EM_error(to_E_Pos(yylloc), "illegal token: %s", yytext); }

%%

int yywrap() {
    return 1;
}

