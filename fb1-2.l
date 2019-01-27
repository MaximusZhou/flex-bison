/* 
* English -> American
* $flex fb1-2.l
* $cc -o fb1-2 lex.yy.c -lfl
* $./fb1-2
*/

%%
"colour" { printf("color"); }
"flavour" { printf("flavor"); }
"clever" { printf("smart"); }
"smart" { printf("elegant"); }
"liberal" { printf("conservative"); }
. { printf("%s", yytext); }
%%
main()
{
  yylex();
}

yywrap() { return 1; }
