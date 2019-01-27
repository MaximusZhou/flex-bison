/* 
* recognize tokens for the calculator and print them out
* $flex fb1-5.l
*/

%{
# include "fb1-5.tab.h"
%}

%%
"+"	{ return ADD; }
"-"	{ return SUB; }
"*"	{ return MUL; }
"/"	{ return DIV; }
"|"     { return ABS; }
"("     { return OP; }
")"     { return CP; }
[0-9]+	{ yylval = atoi(yytext); return NUMBER; }
0x[a-f0-9]+	{char *p_end; yylval = strtol(yytext, &p_end, 16); return NUMBER; }

\n      { return EOL; }
"//".*     /* ignore this comment */
"/*".*"*/" /* ignore this comment */
[ \t]   { /* ignore white space */ }
.	{ yyerror("Mystery character %c\n", *yytext); }
%%
