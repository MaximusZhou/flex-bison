/* 
* recognize tokens for the calculator and print them out
* $flex fb1-3.l
* $cc -o fb1-3 lex.yy.c -lfl
* $./fb1-3
*/

%%
"+"	{ printf("PLUS\n"); }
"-"	{ printf("MINUS\n"); }
"*"	{ printf("TIMES\n"); }
"/"	{ printf("DIVIDE\n"); }
"|"     { printf("ABS\n"); }
[0-9]+	{ printf("NUMBER %s\n", yytext); }
\n      { printf("NEWLINE\n"); }
[ \t] { }
.	{ printf("Mystery character %s\n", yytext); }
%%
