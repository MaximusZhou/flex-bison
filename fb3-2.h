/*
 * 高级计算器的声明
 */

/* 符号表 */
struct symbol {
  char *name;  /* 符号名 */
  double value; /* 保存符号对应的值 */
  struct ast *func;	/* 用户自定义的函数体，即用抽象树语法树表示的该函数的用户代码 */
  struct symlist *syms; /* 虚拟参数列表，这些参数也是符号 */
};

/* 固定大小的简单符号表 */
#define NHASH 9997
struct symbol symtab[NHASH];

struct symbol *lookup(char*);

/* 符号列表，作为参数列表 */
struct symlist {
  struct symbol *sym;
  struct symlist *next;
};

struct symlist *newsymlist(struct symbol *sym, struct symlist *next);
void symlistfree(struct symlist *sl);

/* 节点类型
 *  + - * / |
 *  0-7 比较操作符, 位编码： 04 等于, 02 小于, 01 大于
 *  M 负号操作符
 *  L 表达式或者语句列表
 *  I IF 语句
 *  W WHILE 语句 
 *  N 符号引用
 *  = 赋值
 *  S 符号列表
 *  F 内置函数调用
 *  C 用户自定义函数调用
 */ 

enum bifs {			/* 内置函数 */
  B_sqrt = 1,
  B_exp,
  B_log,
  B_print
};

/* 抽象语法树节点，遍历AST的时候，域nodetype来确定节点的类型,
 * 每个抽象语法树都有相应的值，对于if/then/else来说，它的值就是所选择的分支的值，
 * while/do的值则是do语句列表的最后一条语句的值，而表达式列表的值是由最后一个表达式确定的。*/
struct ast {
  int nodetype;
  struct ast *l;
  struct ast *r;
};

/* 内置函数 */
struct fncall {
  int nodetype;   /* 类型是F */
  struct ast *l;  /* 参数列表 */
  enum bifs functype; /* 内置的函数类型 */
};

/* 用户自定义函数 */
struct ufncall {
  int nodetype;  /* 类型是C */
  struct ast *l; /* 参数列表 */
  struct symbol *s;
};

/* 流程表达式节点 */
struct flow {
  int nodetype;			/* 类型是 I 或者 W */
  struct ast *cond;		/* 条件语句 */
  struct ast *tl;		/* then 分组或者 do 分支 */
  struct ast *el;		/* 可选的else分支 */
};

/* 常量数值节点 */
struct numval {
  int nodetype;
  double number;
};

/* 符号引用节点 */
struct symref {
  int nodetype;
  struct symbol *s;
};

/* 赋值节点 */
struct symasgn {
  int nodetype;
  struct symbol *s; /* 被赋值的符号指针 */
  struct ast *v;
};

/* 构建AST */
struct ast *newast(int nodetype, struct ast *l, struct ast *r);
struct ast *newcmp(int cmptype, struct ast *l, struct ast *r);
struct ast *newfunc(int functype, struct ast *l);
struct ast *newcall(struct symbol *s, struct ast *l);
struct ast *newref(struct symbol *s);
struct ast *newasgn(struct symbol *s, struct ast *v);
struct ast *newnum(double d);
struct ast *newflow(int nodetype, struct ast *cond, struct ast *tl, struct ast *tr);

/* 用于定义自定义函数 */
void dodef(struct symbol *name, struct symlist *syms, struct ast *stmts);

/* 计算AST */
double eval(struct ast *);

/* 删除和释放AST */
void treefree(struct ast *);

/* 词法分析器相关的接口 */
extern int yylineno;
void yyerror(char *s, ...);

extern int debug;
void dumpast(struct ast *a, int level);
