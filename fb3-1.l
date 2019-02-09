/* 识别计算器中的token */

%option noyywrap nodefault yylineno
%{
# include "fb3-1.h"
# include "fb3-1.tab.h"
%}

 /* 浮点数指数部分 */
EXP	([Ee][-+]?[0-9]+)

%%
"+" |
"-" |
"*" |
"/" |
"|" |
"(" |
")"     { return yytext[0]; } /* 把他们自身作为token类型返回，当然下面仍然有NUMBER和EOL命名的符号 */
[0-9]+"."[0-9]*{EXP}? |
"."?[0-9]+{EXP}? { yylval.d = atof(yytext); return NUMBER; } /* 注意是赋值给联合体里面的成员，yylval自定义了 */

\n      { return EOL; }
"//".*  
[ \t]   { /* 忽略空白字符 */ }
.	{ yyerror("Mystery character %c\n", *yytext); }
%%
