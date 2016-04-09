/*
	Implementation:
		. Low Level explanation
			. Preprocessor
				. include
				. define
				. undef
				. ifdef
				. ifndef
				. else
				. error
				. pragma
			. Keyword
				. Branch
					. if
					. else
					. switch
					. goto
					. break
					. case
					. default
					. continue
					. return
				. Loop
					. for
					. while
					. do
				. Typedef
					. typedef
					. struct
					. enum
					. union
					. auto
				. Sizeof
					. sizeof
				. Modifier
					. signed
					. unsigned
					. static
					. const
					. volatile
					. register
				. Type
					. void
					. char
					. short
					. int
					. long
					. float
					. double
			. Operator
				. +
				. ++
				. +=
				. -
				. --
				. -=
				. *
				. *=
				. /
				. /=
				. <<
				. <<=
				. >>
				. >>=
				. &
				. &&
				. &=
				. |
				. ||
				. |=
				. ~
				. ~=
				. =
				. !=
				. ==
		. High Level explanation
			. Variable declaration / initialization
			. void, char, int, long, float, double
			. Branch (if, else, loop)
			. Comment
			. Switch
			. Function
				. e.g.
					.	int main(int argc){}
						. int - Datatype
						. main - function name
						. int - Datatype
						. argc - variable::local::argc
			. Pointer
				. int *ptr;
					. int - Datatype
					. * - Operator
					. ptr - Variable Name
			(NOTE: I CAN PARSE POINTER TO "int *" or "*ptr"
				BUT I DON'T, I THINK THAT IS NOT TOKENIZING)

			. Simple Statement
			. Array
				. char *argv[]
					. char - Datatype
					. * - Operator
					. argv - variable
					. [ - Keyword
					. ] - Keyword
			. Variable Scope
				static int N = 100;
				int main()
				{
					int a = N;
				}
					. int - Datatype
					. a - variable::local::a
					. = - Operator
					. N - Identifier::global::N
			. Struct
			. Enum
			. Union

*/


%{
#include <string.h>
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>

#define NUM_SLOTS 4096

typedef struct node_t
{
	char *value;
	struct node_t *next;
} node;

typedef struct hashtable_t
{
	int count;
	node *slots[NUM_SLOTS];

} hashtable;

/*
	Generate hash key

	return hash key
*/
int hash(const char *s, size_t len);

/*
	Return 1 if found
	type: 
		0: no insert when fail
		1: insert when fail	
*/
int find(hashtable *dst, const char *s, size_t len, int type);

/*
	
*/
void insert(hashtable *dst, const char *s, size_t len);

int init_hashtable(hashtable *table_src);

void clear_hashtable(hashtable *table_src);

void clear_node(node *);

#define STACK_SIZE 1024

typedef enum scope_mode_t
{	
	GLOBAL = 0, 
	LOCAL = 1, 
	UNRESOLVED = 2,
} scope_mode_t;

typedef struct scope_t
{
	scope_mode_t mode;
	hashtable symbol_table;
} scope;

static int process_keyword();
static int process_comment();
static int process_operator();
static int process_modifier();
static int process_datatype();
static int process_constant();
static int process_literal();
static int process_function();
static int process_identifier();
static int process_macro();

int yywrap(void);
static void skip_comment(void);

const char *scope_str[3] = {
	"_global",
	"_local",
	" "
};

scope *scope_stack[STACK_SIZE];

static int scope_stack_index = -1;
static void push_scope(scope_mode_t);
static void pop_scope();
static scope_mode_t find_symbol(const char *);
static void put_symbol(const char *);
static scope_mode_t get_current_scope();

%}

int_suffix				([uU][lL]?)|([lL][uU]?)
fraction_literal		([0-9]*\.[0-9]+)|([0-9]+\.)
exp						[eE][-+]?[0-9]+
float_suffix			[fFlL]
chartext				([^'])|(\\.)
stringtext				([^"])|(\\.)
id_letters	            ([a-zA-Z_][a-zA-Z_0-9]*)
inc_letters	            (.*)
space					([\t\f\v\r ])
skip                    ([\t\f\v\n\r ])

%x COMMENT
%s MACRO
%s DATATYPE
%s DATATYPE_ASSIGN
%s FUNCTION_DECLARATION
%s ENUM_DECLARATION
%s ENUM
%s STRUCT_DECLARATION
%s STRUCT
%s UNION_DECLARATION
%s UNION

%%

"\n"				{ ++yylineno; if(YY_START == MACRO) BEGIN(INITIAL); }
[\t\f\v\r ]+		{}

"/*".*				{ process_comment(); BEGIN(COMMENT); }
<COMMENT>"\n"		{ ++yylineno; }
<COMMENT>.*"*/"		{ process_comment(); BEGIN(INITIAL); }
<COMMENT>.*			{ process_comment();  }
"//".*				{ process_comment();  }

"#"					{ process_keyword(); BEGIN(MACRO); }
<MACRO>
{
	"include"/({skip}*\(.*\)|"")	{ process_macro();  }
	"<".*">"						{ process_literal();}
	"define"/({skip}*\(.*\)|"") 	{ process_macro();  }
	"undef"/({skip}*\(.*\)|"") 		{ process_macro();  }
	"ifdef"/({skip}*\(.*\)|"")		{ process_macro();  }
	"ifndef"/({skip}*\(.*\)|"")		{ process_macro();  }
	"else"/({skip}*\(.*\)|"")		{ process_macro();  }
	"endif"/({skip}*\(.*\)|"")		{ process_macro();  }
	"error"/({skip}*\(.*\)|"")		{ process_macro();  }
	"pragma"/({skip}*\(.*\)|"") 	{ process_macro();  }
	"line"/({skip}*\(.*\)|"")		{ process_macro();  }
}


"{"					{ 
						process_keyword(); 
						if(YY_START != FUNCTION_DECLARATION) 
							push_scope(LOCAL); 

						switch(YY_START)
						{
							case ENUM_DECLARATION:
								BEGIN(ENUM);
								break;
							case STRUCT_DECLARATION:
								BEGIN(STRUCT);
								break;
							case UNION_DECLARATION:
								BEGIN(UNION);
								break;
							default:
								break;
						}
					}
"<%"				{ process_keyword();  }
"}"					{ 
						process_keyword(); 
						pop_scope(); 

						if(YY_START == ENUM ||
							YY_START == STRUCT ||
							YY_START == UNION)
							BEGIN(INITIAL);
					}
"%>"				{ process_keyword();  }
"["					{ process_keyword();  }
"<:"				{ process_keyword();  }
"]"					{ process_keyword();  }
":>"				{ process_keyword();  }
"("					{ process_keyword();  }
")"					{ process_keyword();  if(YY_START == FUNCTION_DECLARATION) BEGIN(INITIAL); }
";"					{ 
						process_keyword();  
						if(YY_START == DATATYPE || YY_START == DATATYPE_ASSIGN) 
							BEGIN(INITIAL); 
					}
":"					{ process_keyword();  }
"..."				{ process_keyword();  }
","					{ process_keyword();  }
"auto"				{ process_keyword();  }
"break"				{ process_keyword();  }
"case"/({skip}*\(.*\)|"")				{ process_keyword();  }
"continue"			{ process_keyword();  }
"default"			{ process_keyword();  }
"do"				{ process_keyword();  }
"else"/({skip}*\(.*\)|"")				{ process_keyword();  }
"extern"			{ process_keyword();  }
"for"/({skip}*\(.*\)|"")				{ process_keyword();  }
"goto"				{ process_keyword();  }
"if"/({skip}*\(.*\)|"")				{ process_keyword();  }
"return"/({skip}*\(.*\)|"")			{ process_keyword();  }
"switch"/({skip}*\(.*\)|"")			{ process_keyword();  }
"typedef"/({skip}*\(.*\)|"")			{ process_keyword();  }
"sizeof"/({skip}*\(.*\)|"")			{ process_keyword();  }
"while"/({skip}*\(.*\)|"")				{ process_keyword();  }
"enum"				{ process_keyword(); BEGIN(ENUM_DECLARATION); }
"struct"			{ process_keyword(); BEGIN(STRUCT_DECLARATION); }
"union"				{ process_keyword(); BEGIN(UNION_DECLARATION); }

"?"					{ process_operator(); }
"."					{ process_operator(); }
"+"					{ process_operator(); }
"-"					{ process_operator(); }
"*"					{ process_operator(); }
"/"					{ process_operator(); }
"%"					{ process_operator(); }
"^"					{ process_operator(); }
"&"					{ process_operator(); }
"|"					{ process_operator(); }
"~"					{ process_operator(); }
"!"					{ process_operator(); }
"="					{ 
						process_operator(); 
						if(YY_START == DATATYPE)
							BEGIN(DATATYPE_ASSIGN);
					}
"<"					{ process_operator(); }
">"					{ process_operator(); }
"+="				{ process_operator(); }
"-="				{ process_operator(); }
"*="				{ process_operator(); }
"/="				{ process_operator(); }
"%="				{ process_operator(); }
"^="				{ process_operator(); }
"&="				{ process_operator(); }
"|="				{ process_operator(); }
"<<"				{ process_operator(); }
">>"				{ process_operator(); }
"<<="				{ process_operator(); }
">>="				{ process_operator(); }
"=="				{ process_operator(); }
"!="				{ process_operator(); }
"<="				{ process_operator(); }
">="				{ process_operator(); }
"&&"				{ process_operator(); }
"||"				{ process_operator(); }
"++"				{ process_operator(); }
"--"				{ process_operator(); }
"->"				{ process_operator(); }

"signed"			{ process_modifier(); }
"register"			{ process_modifier(); }
"const"				{ process_modifier(); }
"static"			{ process_modifier(); }
"unsigned"			{ process_modifier(); }
"volatile"			{ process_modifier(); }

"float"				{ process_datatype(); BEGIN(DATATYPE); }
"double"			{ process_datatype(); BEGIN(DATATYPE); }
"char"				{ process_datatype(); BEGIN(DATATYPE); }
"int"				{ process_datatype(); BEGIN(DATATYPE); }
"long"				{ process_datatype(); BEGIN(DATATYPE); }
"short"				{ process_datatype(); BEGIN(DATATYPE); }
"void"				{ process_datatype(); BEGIN(DATATYPE); }
		
{id_letters}/{skip}*\(.*\)				{ process_function();   } 
{id_letters}							{ process_identifier(); } 

"0"[xX][0-9a-fA-F]+{int_suffix}?		{ process_literal(); }
"0"[0-7]+{int_suffix}?					{ process_literal(); }
[0-9]+{int_suffix}?						{ process_literal(); }

{fraction_literal}{exp}?{float_suffix}?	{ process_literal(); }
[0-9]+{exp}{float_suffix}?				{ process_literal(); }

"'"{chartext}*"'"						{ process_literal(); }
"L'"{chartext}*"'"						{ process_literal(); }

"\""{stringtext}*"\""					{ process_literal(); } 
"L\""{stringtext}*"\""					{ process_literal(); }

.										{ fprintf(stderr, "%d: unexpected character `%c'\n", yylineno, yytext[0]); }

%%

int main(int argc, char *argv[])
{	
	scope_stack_index = -1;
	push_scope(GLOBAL);
	yylex();
	pop_scope();
	return 0;
}

int yywrap()
{
	return 1;
}


static void skip_comment()
{
	int c1, c2;

	c1 = input();
	c2 = input();

	while (c2 != EOF && !(c1 == '*' && c2 == '/')) {
		if (c1 == '\n')
			++yylineno;
		c1 = c2;
		c2 = input();
	}
}

static int process_keyword() 
{
	printf("#%d\t%-15s: %s\n",yylineno, "Keyword", yytext);

	return 1;
}

static int process_comment()
{
	printf("#%d\t%-15s: %s\n",yylineno, "Comment", yytext);

	return 1;
}

static int process_operator() 
{
	printf("#%d\t%-15s: %s\n",yylineno, "Operator", yytext);

	return 1;
}

static int process_modifier() 
{
	printf("#%d\t%-15s: %s\n",yylineno, "Modifier", yytext);

	return 1;
}

static int process_datatype() 
{
	printf("#%d\t%-15s: %s\n",yylineno, "Datatype", yytext);

	return 1;
}

static int process_literal() 
{
	printf("#%d\t%-15s: %s\n",yylineno, "Literal", yytext);
	if(YY_START == DATATYPE_ASSIGN)
		BEGIN(DATATYPE);
	return 1;
}

static int process_constant()
{
	printf("#%d\t%-15s: %s\n",yylineno, "Constant", yytext);
	if(YY_START == DATATYPE_ASSIGN)
		BEGIN(DATATYPE);

	return 1;
}

static int process_function()
{
	switch(YY_START)
	{
		case DATATYPE:
			push_scope(LOCAL);
			BEGIN(FUNCTION_DECLARATION);
		default:
			printf("#%d\t%-15s: %s\n",yylineno, "Function", yytext);
			if(YY_START == DATATYPE_ASSIGN)
				BEGIN(DATATYPE);
			
			break;
	}

	return 1;
}

static int process_identifier() 
{
	scope_mode_t mode;
	switch(YY_START)
	{
		case MACRO:
			printf("#%d\t%-15s: %s\n",yylineno, 
				"MacroSymbol", yytext);
			break;
		case FUNCTION_DECLARATION:
		case DATATYPE:
			mode = get_current_scope();
			printf("#%d\t%-15s: (%-10s)::%s\n",yylineno, 
				"Variable", scope_str[mode], yytext);
			put_symbol(yytext);
			break;
		case ENUM:
			printf("#%d\t%-15s: %s\n",yylineno, 
				"Constant", yytext);
			break;
		case ENUM_DECLARATION:
			printf("#%d\t%-15s: %s\n",yylineno, 
				"Enum", yytext);
			break;
		case STRUCT_DECLARATION:
			printf("#%d\t%-15s: %s\n",yylineno, 
				"Struct", yytext);
			break;
		case UNION_DECLARATION:
			printf("#%d\t%-15s: %s\n",yylineno, 
				"Union", yytext);
			break;
		case DATATYPE_ASSIGN:
		default:
			mode = find_symbol(yytext);
			printf("#%d\t%-15s: (%-10s)::%s\n",yylineno, 
				"Identifier", scope_str[mode], yytext);
			
			if(YY_START == DATATYPE_ASSIGN)
				BEGIN(DATATYPE);
			break;
	}

	return 1;
}

static int process_macro()
{
	printf("#%d\t%-15s: %s\n",yylineno, "Macro", yytext);

	return 1;
}

static void push_scope(scope_mode_t mode)
{
	++scope_stack_index;

	scope *s = malloc(sizeof(scope));
	s->mode = mode;
	init_hashtable(&s->symbol_table);

	scope_stack[scope_stack_index] = s;
}

static void pop_scope()
{
	scope *s = scope_stack[scope_stack_index];
	clear_hashtable(&s->symbol_table);
	free(scope_stack[scope_stack_index]);
	scope_stack[scope_stack_index] = NULL;

	--scope_stack_index;
}

static scope_mode_t find_symbol(const char *symbol)
{
	int i;
	for(i = scope_stack_index; i >= 0; i--)
	{
		if(find(&scope_stack[i]->symbol_table, symbol, strlen(symbol), 0))
		{
			return scope_stack[i]->mode;
		}
	}
	return UNRESOLVED;
}

static void put_symbol(const char *symbol)
{
	insert(&scope_stack[scope_stack_index]->symbol_table,
		symbol, strlen(symbol));
}

static scope_mode_t get_current_scope()
{
	return (scope_stack_index < 0) ? 
		UNRESOLVED : scope_stack[scope_stack_index]->mode;
}

int hash(const char *s, size_t len)
{
	unsigned long hash = 5381;
	int c;
	
	int i;
	for(i = 0; i < len; i++)
	{
		c = s[i];
		hash = ((hash << 5) + hash) + c; /* hash * 33 + c */
	}
	
	return hash % NUM_SLOTS;
}

/*
	Return 1 if found
	type: 
		0: no insert when fail
		1: insert when fail	
*/
int find(hashtable *dst, const char *s, size_t len, int type)
{
	int key = hash(s, len);

	node *cur = dst->slots[key];
	while(cur != NULL)
	{
		if(strcmp(cur->value, s) == 0)
			return 1;
		cur = cur->next;
	}
	return 0;
}

void insert(hashtable *dst, const char *s, size_t len)
{
	int key = hash(s, len);
	node *cur = dst->slots[key];
	if(cur == NULL)
	{
		cur = malloc(sizeof(node));
		cur->value = strdup(s);
		cur->next = NULL;
		dst->slots[key] = cur;
		dst->count++;
	}
	else
	{
		while(cur->next != NULL)
			cur = cur->next;
		cur->next = malloc(sizeof(node));
		cur->next->value = strdup(s);
		cur->next->next = NULL;  
		dst->count++;
	}

}

int init_hashtable(hashtable *src)
{
	memset(src->slots, 0, sizeof(src->slots));
	src->count = 0;
}

void clear_hashtable(hashtable *table_src)
{
	int i;
	for(i = 0; i < NUM_SLOTS; i++)
	{
		if(table_src->slots[i] != NULL)
			clear_node(table_src->slots[i]);
	}
}

void clear_node(node *node)
{
	if(node->next != NULL)
		clear_node(node->next);
	free(node);
}

void print_node(node *n)
{
	printf("%s\n",n->value);
	if(n->next != NULL)
		print_node(n->next);
}
