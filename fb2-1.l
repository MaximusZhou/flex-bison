/* 
* fb2-1 just like unix wc with explicit input
* $flex fb2-1.l
* $cc -o fb2-1 lex.yy.c -lfl
* $./fb2-1 lex.yy.c 
lines=1778,words=6660,chars=44735
*/

%{
int chars = 0;
int words = 0;
int lines = 0;
%}

%%

[a-zA-Z]+	{ words++; chars += strlen(yytext); }
\n		{ chars++; lines++; }
.		{ chars++; }

%%

int main(int argc, char **argv)
{
  int y_ret;
  if(argc > 1)
  {
    if(!(yyin = fopen(argv[1], "r")))
	{
      perror(argv[1]);
      return (1);
    }
  }

  y_ret = yylex();
  printf("yylex ret=%d\n", y_ret);
  printf("lines=%d,words=%d,chars=%d\n", lines, words, chars);

  return 0;
}

int yywrap() { return 1; }
