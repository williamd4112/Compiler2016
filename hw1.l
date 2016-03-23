
%{

#include <string.h>
#include <ctype.h>

#include "hashtable.h"

#define MAX_STACK_DEPTH (1 << 10)

typedef struct scope_t
{
	char *name;
	hashtable symbol_table;
}scope;

static int process_keyword();
static int process_operator();
static int process_modifier();
static int process_datatype();
static int process_struct();
static int process_enum();
static int process_union();
static int process_constant();
static int process_literal();
static int process_function();
static int process_identifier();

static void push_stack(const char *);
static void pop_stack();
static scope *top_stack();

int lineno;
hashtable type_table;

int stack_pointer = 0;
scope scope_stack[MAX_STACK_DEPTH];

int yywrap(void);
static void skip_comment(void);

%}

int_suffix			([uU][lL]?)|([lL][uU]?)
fraction_literal		([0-9]*\.[0-9]+)|([0-9]+\.)
exp				[eE][-+]?[0-9]+
float_suffix			[fFlL]
chartext			([^'])|(\\.)
stringtext			([^"])|(\\.)
id_letters	            	([a-zA-Z_][a-zA-Z_0-9]*)
space				([\t\f\v\r ])
skip                    	([\t\f\v\n\r ])
primitive_type			(char|short|int|float|double)

%s TYPEDEF
%s FUNCTION_DECLARATION
%s FUNCTION_DEFINITION
%s FUNCTION_CALL
%s DATATYPE
%s VARIABLE_DECLARATION
%s VARIABLE_INITIALIZATION
%s ENUM
%s STRUCT
%s UNION
%%

"\n"				{ ++lineno; }
[\t\f\v\r ]+			{}

"/*"				{ skip_comment();     }
"//".*				{}
<FUNCTION_DECLARATION>"{"	{
					process_keyword();
					BEGIN(FUNCTION_DEFINITION);
				}
"{"				{ 
					process_keyword();  
					push_stack("_local");
				}
"<%"				{ process_keyword();  }
"}"				{ 
					process_keyword();  
					pop_stack();
				}
"%>"				{ process_keyword();  }
"["				{ process_keyword();  }
"<:"				{ process_keyword();  }
"]"				{ process_keyword();  }
":>"				{ process_keyword();  }
"("				{ 
					process_keyword(); 
				}
")"				{
					process_keyword();  
				}
<FUNCTION_DECLARATION>";"	{ 
					process_keyword();
					pop_stack();
					BEGIN(INITIAL);
				}
";"				{ 
					process_keyword();
					BEGIN(INITIAL);
				}
":"				{ process_keyword();  }
"..."				{ process_keyword();  }

"auto"				{ process_keyword();  }
"break"				{ process_keyword();  }
"case"				{ process_keyword();  }
"continue"			{ process_keyword();  }
"default"			{ process_keyword();  }
"do"				{ process_keyword();  }
"else"				{ process_keyword();  }
"extern"			{ process_keyword();  }
"for"				{ process_keyword();  }
"goto"				{ process_keyword();  }
"if"				{ process_keyword();  }
"return"			{ process_keyword();  }
"switch"			{ process_keyword();  }
"typedef"			{ process_keyword(); BEGIN(TYPEDEF); }
"sizeof"			{ process_keyword();  }
"while"				{ process_keyword();  }

"?"				{ process_operator(); }
"."				{ process_operator(); }
"+"				{ process_operator(); }
"-"				{ process_operator(); }
"*"				{ process_operator(); }
"/"				{ process_operator(); }
"%"				{ process_operator(); }
"^"				{ process_operator(); }
"&"				{ process_operator(); }
"|"				{ process_operator(); }
"~"				{ process_operator(); }
"!"				{ process_operator(); }
<VARIABLE_DECLARATION>"="	{	
					BEGIN(VARIABLE_INITIALIZATION);
					process_operator(); 
				}
"="				{ 
					process_operator(); 
				}
"<"				{ process_operator(); }
">"				{ process_operator(); }
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
","				{ process_operator(); }
"->"				{ process_operator(); }

"signed"			{ process_modifier(); }
"register"			{ process_modifier(); }
"const"				{ process_modifier(); }
"static"			{ process_modifier(); }
"unsigned"			{ process_modifier(); }
"volatile"			{ process_modifier(); }

<FUNCTION_DECLARATION>"float"{skip}*\**		{ process_datatype(); } // float 
<FUNCTION_DECLARATION>"double"{skip}*\**	{ process_datatype(); } // double
<FUNCTION_DECLARATION>"char"{skip}*\**		{ process_datatype(); } // char
<FUNCTION_DECLARATION>"int"{skip}*\**		{ process_datatype(); } // int
<FUNCTION_DECLARATION>"long"{skip}*\**		{ process_datatype(); } // long
<FUNCTION_DECLARATION>"short"{skip}*\**		{ process_datatype(); } // short
<FUNCTION_DECLARATION>"void"{skip}*\**		{ process_datatype(); } // void

"float"{skip}*\**		{ process_datatype(); BEGIN(DATATYPE); } // float 
"double"{skip}*\**		{ process_datatype(); BEGIN(DATATYPE); } // double
"char"{skip}*\**		{ process_datatype(); BEGIN(DATATYPE); } // char
"int"{skip}*\**			{ process_datatype(); BEGIN(DATATYPE); } // int
"long"{skip}*\**		{ process_datatype(); BEGIN(DATATYPE); } // long
"short"{skip}*\**		{ process_datatype(); BEGIN(DATATYPE); } // short
"void"{skip}*\**		{ process_datatype(); BEGIN(DATATYPE); } // void

"enum"{skip}+{id_letters}*/{skip}*\{(.|\n)*\}	{ 
							// Declartion with definition
							process_datatype(); 
							process_enum();
							BEGIN(ENUM);
						}
"enum"{skip}+{id_letters}+			{ 
							// Only declaration
							process_datatype(); 
							process_enum();
						}
"enum"/{skip}*\{(.|\n)*\}			{
							// No name enum 
							process_datatype(); 
						}

"struct"{skip}+{id_letters}+			{ 
							// Only declaration (struct node_t)
							process_datatype();
							process_struct();  
						}	 
"struct"/{skip}*\{(.|\n)*\}			{ 	
							// strcut {} variable_name
							process_datatype(); 
						} 

"union"{skip}+{id_letters}+			{ 
							process_datatype(); 
							process_union();
						}
"union"/{skip}*\{(.|\n)*\}			{ 
							process_datatype(); 
						}

<ENUM>{id_letters}				{ 	
							// Enum constant
							process_constant(); 
						}
<DATATYPE>{id_letters}/{skip}*\((.|\n)*\)	{ 
							BEGIN(FUNCTION_DECLARATION);
							process_function(); 
							push_stack("_local");
						}
{id_letters}/{skip}*\((.|\n)*\)			{ 
							BEGIN(FUNCTION_CALL);
							process_function(); 
						}  


<FUNCTION_DECLARATION>{id_letters}		{
							process_identifier();
						}
<DATATYPE>{id_letters}				{	
							BEGIN(VARIABLE_DECLARATION);
							process_identifier(); 
						} 
<VARIABLE_INITIALIZATION>{id_letters}		{
							process_identifier(); 
							BEGIN(VARIABLE_DECLARATION);
						}
{id_letters}					{ process_identifier(); } 

"0"[xX][0-9a-fA-F]+{int_suffix}?		{ process_literal(); }
"0"[0-7]+{int_suffix}?				{ process_literal(); }
[0-9]+{int_suffix}?				{ process_literal(); }

{fraction_literal}{exp}?{float_suffix}?		{ process_literal(); }
[0-9]+{exp}{float_suffix}?			{ process_literal(); }

"'"{chartext}*"'"				{ process_literal(); }
"L'"{chartext}*"'"				{ process_literal(); }

"\""{stringtext}*"\""				{ process_literal(); } 
"L\""{stringtext}*"\""				{ process_literal(); }

.						{ fprintf(stderr, "%d: unexpected character `%c'\n", lineno, yytext[0]); }

%%

int main(int argc, char *argv[])
{
	lineno = 0;
	
	init_hashtable(&type_table);
	
	int i;
	for(i = 0; i < MAX_STACK_DEPTH; i++)
		init_hashtable(&scope_stack[i].symbol_table);

	push_stack("_global");
	
	yyin = fopen(argv[1], "r");
	yylex();
	
	printf("# Line: %d\n",lineno);
	
	fclose(yyin);

	return 0;
}

void push_stack(const char *s)
{
	if(stack_pointer >= MAX_STACK_DEPTH)
	{
		fprintf(stderr, "Stack Overflow: too many scopes.\n");
		exit(-1);
	}

#ifdef _DEBUG
	printf("Push %s at %d\n",s,stack_pointer);
#endif

	clear(&scope_stack[stack_pointer].symbol_table);
	init_hashtable(&scope_stack[stack_pointer].symbol_table);
	scope_stack[stack_pointer++].name = strdup(s);
}

void pop_stack()
{
	if(stack_pointer <= 0)
	{
		fprintf(stderr, "Stack Overflow: unbalanced paranthess. (Pop global scope)\n");
		exit(-1);
	}
	stack_pointer--;

#ifdef _DEBUG
	printf("Pop %s at %d\n",scope_stack[stack_pointer].name, stack_pointer);
#endif
	clear(&scope_stack[stack_pointer].symbol_table);
	free(scope_stack[stack_pointer].name);
}

scope *top_stack()
{
	if(stack_pointer < 0)
	{
		fprintf(stderr, "Stack Overflow: no stack pointer is negative.\n");
		exit(-1);
	}

	return (stack_pointer == 0) ? &scope_stack[stack_pointer] : &scope_stack[stack_pointer - 1];
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
			++lineno;
		c1 = c2;
		c2 = input();
	}
}

static int process_keyword() 
{
	printf("#%d\tKeyword:\t%s\n",lineno + 1,yytext);

	return 1;
}

static int process_operator() 
{
	printf("#%d\tOperator:\t%s\n",lineno + 1,yytext);

	return 1;
}

static int process_modifier() 
{
	printf("#%d\tModifier:\t%s\n",lineno + 1,yytext);

	return 1;
}

static int process_datatype() 
{
	int begin_lineno = lineno;
	char *datatype_buff = malloc(yyleng * sizeof(char));
	char *dit = datatype_buff, *yit, *yend = yytext + yyleng;
	int has_space = 0;

	for(yit = yytext; yit != yend; yit++)
	{
		if(*yit == '\n')
			lineno++;
		else if(!isspace(*yit))
		{
			*dit = *yit;
			dit++;
		}
		else if(!has_space)
		{
			*dit = ' ';
			dit++;
			has_space = 1;
		}
	}
	*dit = '\0';
	
	printf("#%d\tDataType:\t%s\n",begin_lineno + 1, datatype_buff);
	
	free(datatype_buff);
	
	return 1;
}

static int process_literal() 
{
	printf("#%d\tLiteral:\t%s\n",lineno + 1,yytext);

	return 1;
}

static int process_constant()
{
	printf("#%d\tConstant:\t%s\n",lineno + 1,yytext);

	return 1;
}

static int process_function()
{
	printf("#%d\tFunction:\t%s\n",lineno + 1,yytext);

	return 1;
}

static int process_identifier() 
{
	scope *s;
	int i;
	const char *id_type;
	switch(YYSTATE)
	{
		case VARIABLE_DECLARATION: case FUNCTION_DECLARATION:
			id_type = "Declaration";
			s = top_stack();
			if(s)
			{	
#ifdef _DEBUG
				printf("Put %s at %s\n",yytext,s->name);	
#endif
				insert(&s->symbol_table, yytext, yyleng);
			}
			break;
		default:
			id_type = "Variable";
			for(i = stack_pointer - 1; i >= 0; i--)
			{
				s = &scope_stack[i];
				if(find(&(s->symbol_table), yytext, yyleng, 0))
				{
					break;
				}
			}
			
			if(i < 0){
				fprintf(stderr, "Undefined symbol: %s\n",yytext);
				exit(-1);
			}
			break;
	}	


	if(s == NULL)
	{
		fprintf(stderr, "Stack error\n");
		exit(-1);
	}
	printf("#%d\t%s::Identifier(%s)\t%s\n",lineno + 1 ,s->name, id_type, yytext);

	return 1;
}

static int process_struct()
{
	insert(&type_table, yytext, yyleng);
	return 1;
}

static int process_enum()
{
	insert(&type_table, yytext, yyleng);
	return 1;
}

static int process_union()
{
	insert(&type_table, yytext, yyleng);
	return 1;
}
