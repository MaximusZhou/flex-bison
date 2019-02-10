/* 基于抽象语法树的计算器 */

%{
#  include <stdio.h>
#  include <stdlib.h>
#  include "fb3-1.h"
%}

/* 声明语法分析器中符号值的类型，在bison语法分析器中，每个语法符号，
   包括token和非终结符，都可以有一个相应的值。默认情况下所有的符号值都是整数。*/
%union {
  struct ast *a;
  double d;
}

/* 一旦联合类型被定义，我们需要告诉bison每种语法符号使用的值类型，
   通过放置在尖括号(<>)中的联合类型的相应成员名字来确定。
   记号NUMBER代表了输入中的数字，它通过符号值<d>来保存具体的数值。
   新的声明%type把值<a>赋给exp,factor和term，
   如果不使用记号或者非终结符的值，则不需要为它们声明类型，比如下面的EOL，
   当声明中存在%union时，如果试图使用一个没有被赋予类型的符号值，bison会报错，记住如果没有
   显式的语义动作代码时，规则将使用默认语义动作$$ = $1，而当左边符号与右边符号具有不同的类型时，bison也会报错 */
%token <d> NUMBER
%token EOL

%type <a> exp factor term

%%

calclist: /* 空 */
| calclist exp EOL {
     printf("= %4.4g\n", eval($2));
     treefree($2);
     printf("> ");
 }

 | calclist EOL { printf("> "); } /* 空行或者注释 */
 ;

/* 直接使用文字字符（literal character，比如下面的'+'）token来表示操作符，
   我们并不需要为每个token定义一个名字（也就是定义一个宏），相反，单引号引起来的
   字符也可以作为token，token的ASCII值将称为token的编号（bison对于命名token的编号从
   258开始，所以不会冲突）。按照通用习惯，文字字符token用来代表具有相同字符的输入token；
   例如，记号'+'代表了输入记号+，所以它们只是用在标点和操作符上面。除非你需要声明文字字符
   记号的类型，否则就不要显式声明它们。
   这里使用了三种不同的语法符号，exp、factor和term来设置操作符的优先级和结合性。
*/
exp: factor
 | exp '+' factor { $$ = newast('+', $1,$3); }
 | exp '-' factor { $$ = newast('-', $1,$3);}
 ;

factor: term
 | factor '*' term { $$ = newast('*', $1,$3); }
 | factor '/' term { $$ = newast('/', $1,$3); }
 ;

term: NUMBER   { $$ = newnum($1); }
 | '|' term    { $$ = newast('|', $2, NULL); }
 | '(' exp ')' { $$ = $2; }
 | '-' term    { $$ = newast('M', $2, NULL); }
 ;
%%
