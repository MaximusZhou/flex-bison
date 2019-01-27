/* 
* fb1-1 just like unix wc
* $flex fb1-1.l
* $cc -o fb1-1 lex.yy.c -lfl
* $./fb1-1
*/

%{
int chars = 0;
int words = 0;
int lines = 0;
%}

%%

[^ \t\n\r\f\v]+	{ words++; chars += strlen(yytext); }
\n		{ chars++; lines++; }
.		{ chars++; }

%%

main()
{
  yylex();
  printf("lines=%d,words=%d,chars=%d\n", lines, words, chars);
}
