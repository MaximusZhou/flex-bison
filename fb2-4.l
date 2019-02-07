/* 
* 构造符号表，记录所有的单词，所在的文件和行号
* $flex fb2-4.l
* $cc -o fb2-4 lex.yy.c
* $./fb2-4  test_include.c
*/

%option noyywrap nodefault yylineno case-insensitive

/* 符号表*/
%{
 
  /* 每个单词所对应的信息 */
  struct symbol {
    struct ref *reflist;
    char *name;
  };

  /* 用链表组织单词所在的文件和行号 */
  struct ref {
    struct ref *next;
    char *filename;
    int flags;
    int lineno;
  };

  /* 使用一个数组实现一个hash表，使用线性探测的哈希算法*/
  #define NHASH 9997
  struct symbol symtab[NHASH];

  struct symbol *lookup(char*);
  void addref(int, char*, char*, int);

  /* 当前处理的文件名 */
  char *curfilename;

%}
%%

 /* 要忽略检索的单词，仅包含竖线的语义动作告知它与下一条规则的语义动作一致*/
a |
an |
and |
are |
as |
at |
be |
but |
for |
in |
is |
it |
of |
on |
or |
that |
the |
this |
to                     /* 没有动作，忽略相应的单词*/

[a-z]+(\'(s|t))?   { addref(yylineno, curfilename, yytext, 0); }
.|\n                   /* 其他的字符都忽略 */
%%

/* 对字符串做hash */
static unsigned symhash(char *sym)
{
  unsigned int hash = 0;
  unsigned c;

  while(c = *sym++) hash = hash*9 ^ c;

  return hash;
}

int nnew, nold;
int nprobe;

/* 查找字符串在Hash表对应的结构体 */
struct symbol * lookup(char* sym)
{
  struct symbol *sp = &symtab[symhash(sym)%NHASH];
  int scount = NHASH;		/* 最多查找的元素个数，即Hash表最大的大小 */

  while(--scount >= 0)
  {
    nprobe++;

    /* 已经在Hash表中了，并且找到了 */
    if(sp->name && !strcmp(sp->name, sym)) { nold++; return sp; }

    /* 还没有在Hash表中，则插入 */
    if(!sp->name)
	{
      nnew++;
      sp->name = strdup(sym); /* 复制yytext中的信息到Hash表中 */
      sp->reflist = 0;
      return sp;
    }

    /* 还没有找到，继续查找，检查查找位置是否到达数组末尾 */
    if(++sp >= symtab+NHASH) sp = symtab;
  }

  fputs("symbol table overflow\n", stderr);
  abort(); /* Hash表已经满了 */
}

/* 把相应的word引用信息插入到Hash表中 */
void addref(int lineno, char *filename, char *word, int flags)
{
  struct ref *r;
  struct symbol *sp = lookup(word);

  /* 在同一个文件和同一个行的word已经插入了，则直接返回 */
  if(sp->reflist &&
     sp->reflist->lineno == lineno && sp->reflist->filename == filename) return;

  /* 用链表组织所有相关的信息，并把新的引用信息插入到表头 */
  r = malloc(sizeof(struct ref));
  if(!r) {fputs("out of space\n", stderr); abort(); }
  r->next = sp->reflist;
  r->filename = filename;
  r->lineno = lineno;
  r->flags = flags;
  sp->reflist = r;
}

/* 打印引用信息
 * 按字母顺序排列符号表
 * 然后翻转每个条目的reflist使它变成正向排序，然后打印
 */

static int symcompare(const void *xa, const void *xb)
{
  const struct symbol *a = xa;
  const struct symbol *b = xb;

  if(!a->name)
  {
    if(!b->name) return 0;	/* 两个符号都为空 */
    return 1;			/* 把空符号放到末尾 */
  }

  if(!b->name) return -1;

  return strcmp(a->name, b->name);
}

void printrefs()
{
  struct symbol *sp;

  /* 对Hash表进行排序 */
  qsort(symtab, NHASH, sizeof(struct symbol), symcompare);

  for(sp = symtab; sp->name && sp < symtab+NHASH; sp++)
  {
    char *prevfn = NULL;	/* 最近打印的文件名，防止重复打印 */

    /* 翻转引用表 */
    struct ref *rp = sp->reflist;
    struct ref *rpp = 0;	/* 上一个 ref */
    struct ref *rpn;	/* 下一个 ref */

    do {
      rpn = rp->next;
      rp->next = rpp;
      rpp = rp;
      rp = rpn;
    } while(rp);

    /* 打印word和其引用的信息 */
    printf("%10s", sp->name);
    for(rp = rpp; rp; rp = rp->next)
	{
      if(rp->filename == prevfn)
	  {
		  /* 相同文件名只打印行号 */
		  printf(" %d", rp->lineno);
      }
	  else
	  {
		  /* 新的文件，打印相应的文件名和行号 */
		  printf(" %s:%d", rp->filename, rp->lineno);
		  prevfn = rp->filename;
      }
    }
    printf("\n");
  }
}

int main(int argc, char **argv)
{
  int i;

  if(argc < 2)
  { /* 从 stdin 读取数据 */
    curfilename = "(stdin)";
    yylineno = 1;
    yylex();
  }
  else
  {
	for(i = 1; i < argc; i++)
	{
	  FILE *f = fopen(argv[i], "r");

	  if(!f)
	  {
		perror(argv[1]);
		return (1);
	  }
	  
	  curfilename = argv[i];
	  yyrestart(f);
	  yylineno = 1; /* 新的文件，重置yylineno为1 */
	  yylex();
	  fclose(f);
	}
  }

  printf("old = %d, new = %d, total = %d, probes = %d, avg = %1.2f\n",
	 nold, nnew, nold+nnew, nprobe, (float)nprobe / (nold+nnew));

  printrefs();

  return 0;
}
