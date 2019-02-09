/* 基于抽象语法树的计算器对应的C程序 */

#  include <stdio.h>
#  include <stdlib.h>
#  include <stdarg.h>
#  include "fb3-1.h"

/* 创建抽象树的非叶子节点 */
struct ast * newast(int nodetype, struct ast *l, struct ast *r)
{
  struct ast *a = malloc(sizeof(struct ast));
  
  if(!a)
  {
    yyerror("out of space");
    exit(0);
  }

  a->nodetype = nodetype; /* 使用nodetype来区分节点的类型 */
  a->l = l;
  a->r = r;

  return a;
}

/* 创建抽象树的叶子节点 */
struct ast * newnum(double d)
{
  struct numval *a = malloc(sizeof(struct numval));
  
  if(!a)
  {
    yyerror("out of space");
    exit(0);
  }
  a->nodetype = 'K'; /* 使用nodetype来区分节点的类型 */
  a->number = d;

  return (struct ast *)a;
}

double eval(struct ast *a)
{
  double v;

  /* 使用了深度优先的算法遍历AST */
  switch(a->nodetype)
  {
	  case 'K': v = ((struct numval *)a)->number; break;

	  case '+': v = eval(a->l) + eval(a->r); break;
	  case '-': v = eval(a->l) - eval(a->r); break;
	  case '*': v = eval(a->l) * eval(a->r); break;
	  case '/': v = eval(a->l) / eval(a->r); break;
	  case '|': v = eval(a->l); if(v < 0) v = -v; break;
	  case 'M': v = -eval(a->l); break;
	  default: printf("internal error: bad node %c\n", a->nodetype);
  }

  return v;
}

void treefree(struct ast *a)
{
  switch(a->nodetype)
  {
	  /* 两颗子树的操作节点 */
	  case '+':
	  case '-':
	  case '*':
	  case '/':
		  treefree(a->r);

		  /* 一颗子树的操作节点 */
	  case '|':
	  case 'M':
		  treefree(a->l);

		  /* 叶子节点 */
	  case 'K':
		  free(a);
		  break;

	  default: printf("internal error: free bad node %c\n", a->nodetype);
  }

}

void yyerror(char *s, ...)
{
  va_list ap;
  va_start(ap, s);

  fprintf(stderr, "%d: error: ", yylineno);
  vfprintf(stderr, s, ap);
  fprintf(stderr, "\n");
}

int main()
{
  printf("> "); 
  return yyparse();
}
