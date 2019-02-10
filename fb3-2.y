/* 基于抽象语法树的高级计算器 */

%{
#  include <stdio.h>
#  include <stdlib.h>
#  include "fb3-2.h"
%}

%union {
  struct ast *a;
  double d;
  struct symbol *s;		/* 用于指定符号 */
  struct symlist *sl;
  int fn;			/* 用于指定内置函数，包括比较操作符 */
}

/* 声明所有的token类型，以及对应的值类型 */
%token <d> NUMBER
%token <s> NAME
%token <fn> FUNC /* token FUNC即表示内置函数了 */
%token EOL

%token IF THEN ELSE WHILE DO LET

/* 这的CMP是比较操作符，使用单一token来表示多个语义接近的操作符，
   这里的方法可以帮助我们缩短语法的长度 */
%nonassoc <fn> CMP
%right '='
%left '+' '-'
%left '*' '/'
%nonassoc '|' UMINUS

/* 非终结符节点的类型 */
%type <a> exp stmt list explist
%type <sl> symlist

/* start 声明定义了顶层规则，因此不需要把这条规则放到语法分析器的开始部分 */
%start calclist

%%

/* 语句规则 */
stmt: IF exp THEN list           { $$ = newflow('I', $2, $4, NULL); }
   | IF exp THEN list ELSE list  { $$ = newflow('I', $2, $4, $6); }
   | WHILE exp DO list           { $$ = newflow('W', $2, $4, NULL); }
   | exp
;

/* list是右递归的，也就是说是stmt;list，而不是list stmt;，这对于语言识别没有任何差异，
   但我们因此会更容易构造一个从头到尾而不是相反方向的语句链表。每当stmt;list规则被归约的时候，
   它构建一个链表把语句添加到当前链表的头部，如果规则是list stmt;，则语句要被添加到链表的尾部，
   这样的话就要求一个更复杂的循环链表或者反转链表算法。
   使用右递归而不是左递归的缺点是它把所有需要被归约的语句都要放在语法分析器的堆栈里，
   直到链表的尾部才能归约，而左递归在分析输入时每次遇到语句都立刻将其添加到链表中，这样可以避免堆栈溢出。
   并且左递归通常容易调试，因为每条语句都有输出*/
list: /* 空的 */ { $$ = NULL; }
   | stmt ';' list { if ($3 == NULL)
                       $$ = $1; /* 如果lis为空，则这条规则的值为前面语句返回的值 */
					 else
					   $$ = newast('L', $1, $3);
                   };

/* 表达式规则，前面已经定义他们的优先级和结合性了 */
exp: exp CMP exp          { $$ = newcmp($2, $1, $3); }
   | exp '+' exp          { $$ = newast('+', $1,$3); }
   | exp '-' exp          { $$ = newast('-', $1,$3);}
   | exp '*' exp          { $$ = newast('*', $1,$3); }
   | exp '/' exp          { $$ = newast('/', $1,$3); }
   | '|' exp              { $$ = newast('|', $2, NULL); }
   | '(' exp ')'          { $$ = $2; }
   | '-' exp %prec UMINUS { $$ = newast('M', $2, NULL); }
   | NUMBER               { $$ = newnum($1); }
   | FUNC '(' explist ')' { $$ = newfunc($1, $3); }  /* 内建函数 */
   | NAME                 { $$ = newref($1); }
   | NAME '=' exp         { $$ = newasgn($1, $3); }
   | NAME '(' explist ')' { $$ = newcall($1, $3); }  /* 用户自定义函数，explist是调用函数的实参 */
;

explist: exp
 | exp ',' explist  { $$ = newast('L', $1, $3); } /* 右递归的方式定义的 */
;
symlist: NAME       { $$ = newsymlist($1, NULL); }
 | NAME ',' symlist { $$ = newsymlist($1, $3); } /* 右递归的方式定义的 */
;

calclist: /* 空的 */
  | calclist stmt EOL {  /* 语句列表 */
    if(debug) dumpast($2, 0);
     printf("= %4.4g\n> ", eval($2));
     treefree($2);
    } 
  | calclist LET NAME '(' symlist ')' '=' list EOL {  /* 函数声明，其中symlist 是定义的函数的虚参 */
                       dodef($3, $5, $8);  /* 保存函数声明，用于后面使用 */
                       printf("Defined %s\n> ", $3->name); }

  | calclist error EOL { yyerrok; printf("> "); }
 ;
%%
