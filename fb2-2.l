/* 
* fb2-1 just like unix wc can read serveral files
* $flex fb2-2.l
* $cc -o fb2-2 lex.yy.c 
* $./fb2-2  lex.yy.c README.md 
lex.yy.c: lines=1808,words=6732,chars=45290
README.md: lines=10,words=17,chars=377
totlines=1818,totwords=6749,totchars=45667
*/

%option noyywrap

%{
int chars = 0;
int words = 0;
int lines = 0;

int totchars = 0;
int totwords = 0;
int totlines = 0;
%}

%%

[a-zA-Z]+	{ words++; chars += strlen(yytext); }
\n		{ chars++; lines++; }
.		{ chars++; }

%%

int main(int argc, char **argv)
{
  int i;

  if(argc < 2)
  { 
	/* just read stdin */
    yylex();
	printf("lines=%d,words=%d,chars=%d\n", lines, words, chars);
    return 0;
  }

  for(i = 1; i < argc; i++)
  {
    FILE *f = fopen(argv[i], "r");
  
    if(!f)
	{
      perror(argv[1]);
      return (1);
    }

    yyrestart(f);
    yylex();
    fclose(f);
	printf("%s: lines=%d,words=%d,chars=%d\n", argv[i], lines, words, chars);
    totchars += chars; chars = 0;
    totwords += words; words = 0;
    totlines += lines; lines = 0;
  }

  if(argc > 1)
  {
	printf("totlines=%d,totwords=%d,totchars=%d\n", totlines, totwords, totchars);
  }

  return 0;
}
