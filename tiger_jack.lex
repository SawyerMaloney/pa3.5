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

E_Pos to_E_Pos(YYLTYPE pos);#include <string.h>

#define INITIAL_BUFFER_SIZE 16

//All strings sent to the buffer. Forward delcarations here
void adjust();
void initialize_buffer();
void add_character_to_buffer(char);

char * buffer;
int buffer_size;
int char_pos = 1;
int nesting_index = 0;

%}

    /* makes comments and strings mutually exlusive states */
%x COMMENT STRING_STATE 

%option nounput noinput

space [ \t]
ws {space}+
digit [0-9]

%%

    /* skip carriage returns and tabs, whitespaces */
[\r\t]      { adjust(); continue; }
{ws}        { adjust(); continue; }

    /* Also needed for the comments section? But I had errors/warnings trying */
\n          { adjust(); EM_newline(); continue; }

    /* reserving the words first so they're not matched as strings */ 
array       { adjust(); return ARRAY; }
if          { adjust(); return IF; }
in          { adjust(); return IN; }
then        { adjust(); return THEN; }
else        { adjust(); return ELSE; }
while       { adjust(); return WHILE; }
for  	    { adjust(); return FOR; }
do          { adjust(); return DO; }
to          { adjust(); return TO; }
let         { adjust(); return LET; }
end         { adjust(); return END; }
of          { adjust(); return OF; }
break       { adjust(); return BREAK; }
function    { adjust(); return FUNCTION; }
nil         { adjust(); return NIL; }
var         { adjust(); return VAR; }
type        { adjust(); return TYPE; }

    /* operators, assignment, punctuation */
":"         { adjust(); return COLON; }
";"         { adjust(); return SEMICOLON; }
"."         { adjust(); return DOT; }
","	        { adjust(); return COMMA; }
"("         { adjust(); return LPAREN; }
")"         { adjust(); return RPAREN; }
"["         { adjust(); return LBRACK; }
"]"         { adjust(); return RBRACK; }
"{"         { adjust(); return LBRACE; }
"}"         { adjust(); return RBRACE; }
"+"         { adjust(); return PLUS; }
"-"         { adjust(); return MINUS; }
"*"         { adjust(); return TIMES; }
"/"         { adjust(); return DIVIDE; }
"="         { adjust(); return EQ; }
"<>"        { adjust(); return NEQ; }
"<"         { adjust(); return LT; }
"<="        { adjust(); return LE; }
">"         { adjust(); return GT; }
">="        { adjust(); return GE; }
"&"         { adjust(); return AND; }
"|"         { adjust(); return OR; }
":="        { adjust(); return ASSIGN; }


{digit}+	{ adjust(); yylval.ival = atoi(yytext); return INT; }

[a-zA-Z][_a-zA-Z0-9]* { adjust(); yylval.sval = make_String(yytext); return ID; }

    /* string start */
\"          { initialize_buffer(); adjust(); BEGIN(STRING_STATE); }

    /* Alternative solution : Match the whole comment right away: /\*.*?\*/
    /* comment start */
"/*"        { adjust(); nesting_index++; BEGIN(COMMENT); }

    /* anything else not yet matched */
.	        { adjust(); EM_error(EM_token_pos, "illegal token"); }


    /* STRING_STATE is not exhaustive for all possible strings. Certain
      things like escaped double quotes and backslashes are unspecified */ 
<STRING_STATE>{

        /* End of string : free buffer holding on to string because it 
           will be initialized again upon the next call */ 
    \"      { 
                char_pos += yyleng;
                BEGIN(INITIAL);
                yylval.sval = make_String(buffer);
                free(buffer);
                return STRING;
            }

    \\n     { char_pos += yyleng; add_character_to_buffer('\n'); } 
    \\t     { char_pos += yyleng; add_character_to_buffer('\t'); } 
    \\      { char_pos += yyleng; add_character_to_buffer('\\'); } 
    \\\"    { char_pos += yyleng; add_character_to_buffer('\"'); }

    \\[0-9]{3} {
                 char_pos += yyleng;
                 int result;
                 /* converts to integer; +1 to skip the backslash */
                 sscanf(yytext + 1, "%d", &result);
                 if (result > 255) {
                    EM_error(EM_token_pos, "ASCII not in range");
                 }
                 add_character_to_buffer(result);
               }

        /* any other escape like \1234 is an error. Helpful specificity */
    \\[0-9]+  {
                 char_pos += yyleng;
                 EM_error(EM_token_pos, "Invalid escape sequence");
              }

        /* catch-all for escape sequences. Found online */
    "\^"[@A-Z\[\]\\\^_?] {
                           char_pos += yyleng;
                           add_character_to_buffer(yytext[1]-'@');
                         }

        /* rule that allows strings on new lines with \ at the end and start of lines */
     \\[\t\n\f]+\\ { char_pos += yyleng; int i;
                     for (i = 0; yytext[i]; i++) {
                        if (yytext[i] == '\n') {
                          EM_newline();
                        }
                     }
                     continue;
                   }

    <<EOF>> { adjust(); EM_error(EM_token_pos, "Unclosed string at end of file"); }

        /* anything else (hopefully just regular text) */
    .       { 
                char_pos += yyleng; 
                char * temp_ptr = yytext;
                add_character_to_buffer(*temp_ptr);
            } 
}

<COMMENT>{

    "/*" {
            adjust();
            nesting_index++;
            continue;
         }

    "*/" {
            adjust();
             nesting_index--;
             if (nesting_index == 0) {
                BEGIN(INITIAL);
             }
         }

    [\r\n]  { adjust(); }   

    <<EOF>> { adjust(); EM_error(EM_token_pos, "EOF is in a comment"); }   

    .    { adjust(); }
}

%%

int yywrap() {
    char_pos = 1;
    return 1;
}

void adjust() {
    EM_token_pos = char_pos;
    char_pos += yyleng;
}

void initialize_buffer() {
    buffer = malloc_checked(INITIAL_BUFFER_SIZE);
    buffer[0] = 0;
    buffer_size = INITIAL_BUFFER_SIZE;
}

void add_character_to_buffer(char ch) {
    int new_length = strlen(buffer) + 1;
    if (new_length >= buffer_size) {
        //double the buffer
        char * temp = malloc_checked(buffer_size * 2);
        memcpy(temp, buffer, new_length);
        free(buffer);
        buffer = temp;
    }
    buffer[new_length - 1] = ch;
    buffer[new_length] = 0;
}
