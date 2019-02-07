/* 
* C 交叉引用程序
* $flex fb2-5.l
* $cc -o fb2-5 lex.yy.c
* $./fb2-5  test_include.c
*/

%option noyywrap nodefault yylineno

%x COMMENT
%x IFILE

/* 一些复杂的命名模式 */
/* 通用的字符名(Universal Character Name)，一种在字符串和标识符中放置非ASCII码字符的比较笨拙的方法
*  通用字符名由跟在\u后的4个十六进制数或跟在\U后的8个十六进制数表示*/
UCN	(\\u[0-9a-fA-F]{4}|\\U[0-9a-fA-F]{8})
/* 浮点数的指数部分 */
EXP	([Ee][-+]?[0-9]+)
/* 匹配整型常量的长度和类型后缀，可选的U代表无符号数，
*  可选的L或者LL代表常量长度，这两者都是大小写无关的，顺序也可以颠倒的 */
ILEN    ([Uu](L|l|LL|ll)?|(L|l|LL|ll)[Uu]?)

/* 符号表 */
%{
  struct symbol {		/* 变量名 */
    struct ref *reflist;
    char *name;
  };

  struct ref {
    struct ref *next;
    char *filename;
    int flags;
    int lineno;
  };

  /* 简单的固定大小的符号表 */
  #define NHASH 9997
  struct symbol symtab[NHASH];

  struct symbol *lookup(char*);
  void addref(int, char*, char*, int);

  char *curfilename;		/* 当前输入文件的名称 */

  int defining;			/* 名称是否作为定义而不是引用出现时被设置 */

/* include 文件堆栈 */  
  struct bufstack {
    struct bufstack *prev;	/* 上一个条目 */
    YY_BUFFER_STATE bs;		/* 用于当前文件做词法分析器的缓存区 */
    int lineno;			/* 保存当前分析到的文件行数 */
    char *filename;		/* 当前分析的文件名 */
    FILE *f;			/* 当前文件 */
  } *curbs;

  int newfile(char *fn);
  int popfile(void);
%}
%%

 /* 注释模式，注意这里使用的是多个模式和起始状态，虽然可以单一模式也可以做完，
    但是建议还是使用起始模式和起始状态，有两个原因：一个是原因注释可能很长，flex的token的输入缓存区
	有长度限制，通常是16K，另外一个原因多个模式更加容易调试*/
"/*"           { BEGIN(COMMENT) ; }
<COMMENT>"*/"  { BEGIN(INITIAL); }
 /* 这个规则可以是.|\n，不过([^*]|\n)+却能够一次就匹配一长串文本。
    注意这个规则把*排除在外，因此第二个规则才能匹配注释的结尾 */
<COMMENT>([^*]|\n)+|.
<COMMENT><<EOF>> {printf("%s:%d: Unterminated comment\n", curfilename, yylineno); return 0;}

 /* C++风格的注释 */
"//".*\n

 /* 声明关键字 */
_Bool |
_Complex |
_Imaginary |
auto |
char |
const |
double |
enum |
extern |
float |
inline |
int |
long |
register |
restrict |
short |
signed |
static |
struct |
typedef |
union |
unsigned |
void |
volatile { defining = 1; }


 /* 关键字 */
break
case
continue
default
do
else
for
goto
if
return
sizeof
switch
while

 /* 常量 */

 /* 整数 */
0[0-7]*{ILEN}?
[1-9][0-9]*{ILEN}?
0[Xx][0-9a-fA-F]+{ILEN}?

 /* 十进制浮点数 */
([0-9]*\.[0-9]+|[0-9]+\.){EXP}?[flFL]?
[0-9]+{EXP}[flFL]?

 /* 十六进制浮点数 */
0[Xx]([0-9a-fA-F]*\.[0-9a-fA-F]+|[0-9a-fA-F]+\.?)[Pp][-+]?[0-9]+[flFL]?

 /* 单个字符常量 */
\'([^'\\]|\\['"?\\abfnrtv]|\\[0-7]{1,3}|\\[Xx][0-9a-fA-F]+|{UCN})+\'

 /* 字符串字面量 */
L?\"([^\"\\]|\\['"?\\abfnrtv]|\\[0-7]{1,3}|\\[Xx][0-9a-fA-F]+|{UCN})+\"

 /* 标点符号(puncatuator)，C语言把操作符和标点都称为标点符号 */
"{"|"<%"|";"         { defining = 0; }


"["|"]"|"("|")"|"{"|"}"|"."|"->"
"++"|"--"|"&"|"*"|"+"|"-"|"~"|"!"
"/"|"%"|"<<"|">>"|"<"|">"|"<="|">="|"=="|"!="|"^"|"|"|"&&"|"||"
"?"|":"|";"|"..."
"="|"*="|"/="|"%="|"+="|"-="|"<<="|">>="|"&="|"^=""|="
","|"#"|"##"
"<:"|":>"|"%>"|"%:"|"%:%:"

 /* 标识符，C语言的标识符是由字母、下划线和通用字符名开头，
    后面可选是更多的字母、下划线、通用字符名以及数字 */
([_a-zA-Z]|{UCN})([_a-zA-Z0-9]|{UCN})* {
                         addref(yylineno, curfilename, yytext, defining); }

 /* 空白字符 */
[ \t\n]+
 /* 续行符号，即行尾的反斜线 */
\\$

 /* 预处理器 */
"#"" "*if.*\n
"#"" "*else.*\n
"#"" "*endif.*\n
"#"" "*define.*\n
"#"" "*line.*\n

 /* 识别include包含文件 */
^"#"[ \t]*include[ \t]*[\"<] { BEGIN IFILE; }

<IFILE>[^>\"]+  {
                  { int c;
				    while((c = input()) && c != '\n') ;
				  }
				  newfile(strdup(yytext));
				  BEGIN INITIAL;
                }

<IFILE>.|\n     { fprintf(stderr, "%s:%d bad include line\n", 
                                   curfilename, yylineno);
                  BEGIN INITIAL;
                }

<<EOF>>         { if(!popfile()) yyterminate(); }

 /* 无效的字符 */
.               { printf("%s:%d: Mystery character '%s'\n",
                          curfilename, yylineno, yytext);
                }
%%

/* 计算符号的hash值 */
static unsigned symhash(char *sym)
{
  unsigned int hash = 0;
  unsigned c;

  while(c = *sym++) hash = hash*9 ^ c;

  return hash;
}

struct symbol * lookup(char* sym)
{
  struct symbol *sp = &symtab[symhash(sym)%NHASH];
  int scount = NHASH;		/* 最多查找的个数 */

  while(--scount >= 0)
  {
    if(sp->name && !strcmp(sp->name, sym)) { return sp; }

    if(!sp->name)
	{/* 插入到Hash表中 */
      sp->name = strdup(sym);
      sp->reflist = 0;
      return sp;
    }

    /* 尝试检查下一个位置 */
    if(++sp >= symtab+NHASH) sp = symtab;
  }
  fputs("symbol table overflow\n", stderr);
  abort(); /* Hash表已经满了 */
}

void addref(int lineno, char *filename, char *word, int flags)
{
  struct ref *r;
  struct symbol *sp = lookup(word);

  /* 同一个文件的同一行，只处理一个 */
  if(sp->reflist &&
     sp->reflist->lineno == lineno && sp->reflist->filename == filename) return;

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
    return 1;              /* 把空符号放到末尾 */
  }

  if(!b->name) return -1;

  return strcmp(a->name, b->name);
}

void printrefs()
{
  struct symbol *sp;

  /* 对Hash表进行排序 */
  qsort(symtab, NHASH, sizeof(struct symbol), symcompare);

  for(sp = symtab; sp->name && sp < symtab+NHASH; sp++) {
    char *prevfn = NULL;	/* 最近打印的文件名，防止重复打印文件名 */

    /* 翻转引用表，这种错误顺序来建立的列表，然后再翻转的技巧是非常有用，并且经常使用 */
    struct ref *rp = sp->reflist;
    struct ref *rpp = 0;
    struct ref *rpn;

    do
	{
      rpn = rp->next;
      rp->next = rpp;
      rpp = rp;
      rp = rpn;
    } while(rp);

    printf("%10s", sp->name);
    for(rp = rpp; rp; rp = rp->next)
	{
      if(rp->filename == prevfn)
	  {
		  printf(" %d", rp->lineno);
      }
	  else
	  {
		  printf(" %s:%d", rp->filename, rp->lineno);
		  prevfn = rp->filename;
      }

      if(rp->flags & 01) printf("*");
    }

    printf("\n");
  }
}

int main(int argc, char **argv)
{
  int i;

  if(argc < 2)
  {
    fprintf(stderr, "need filename\n");
    return 1;
  }

  for(i = 1; i < argc; i++)
  {
    if(newfile(argv[i])) yylex();
  }

  printrefs();
  return 0;
}

/* 嵌套输入的文件 */
int newfile(char *fn)
{
  FILE *f = fopen(fn, "r");
  struct bufstack *bs;

  if(!f)
  {
    perror(fn);
    return 0;
  }

  bs = malloc(sizeof(struct bufstack));
  if(!bs) { perror("malloc"); exit(1); }

  /* 保存当前文件已经分析的信息 */
  if(curbs) curbs->lineno = yylineno;

  bs->prev = curbs;
  bs->f = f;
  bs->filename = fn;

  /* 设置分析新的文件相关的信息 */
  bs->bs = yy_create_buffer(f, YY_BUF_SIZE);
  yy_switch_to_buffer(bs->bs);
  curbs = bs;
  yylineno = 1;
  curfilename = fn;

  return 1;
}

int popfile(void)
{
  struct bufstack *bs = curbs;
  struct bufstack *prevbs;

  if(!bs) return 0;

  /* 释放相关的词法分析buff和close文件 */
  fclose(bs->f);
  yy_delete_buffer(bs->bs);

  /* 切换到上一个文件的分析状态 */
  prevbs = bs->prev;
  free(bs);

  if(!prevbs) return 0;

  yy_switch_to_buffer(prevbs->bs);
  curbs = prevbs;
  yylineno = curbs->lineno;
  curfilename = curbs->filename;

  return 1; 
}
