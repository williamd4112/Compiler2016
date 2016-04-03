%{
#include <string.h>
#include <ctype.h>

#include "hashtable.h"

#define STACK_SIZE 1024

enum scope_mode_t
{
	GLOBAL, LOCAL
};

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
static int process_struct();
static int process_enum();
static int process_union();
static int process_constant();
static int process_literal();
static int process_function();
static int process_identifier();
static int process_macro();

int yywrap(void);
static void skip_comment(void);

scope *scope_stack[STACK_SIZE];

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
%%

"\n"				{ ++yylineno; BEGIN(INITIAL); }
[\t\f\v\r ]+		{}

"/*".*				{ process_comment(); BEGIN(COMMENT); }
<COMMENT>"\n"		{ ++yylineno; }
<COMMENT>.*"*/"		{ process_comment(); BEGIN(INITIAL); }
<COMMENT>.*			{ process_comment();  }
"//".*				{ process_comment();  }

"#"					{ process_keyword(); BEGIN(MACRO); }
<MACRO>"include"	{ process_macro();  }
<MACRO>"<".*">" 	{ process_literal();}
<MACRO>"define" 	{ process_macro();  }
<MACRO>"ifdef"		{ process_macro();  }
<MACRO>"ifndef"		{ process_macro();  }
<MACRO>"else"		{ process_macro();  }
<MACRO>"endif"		{ process_macro();  }
<MACRO>"error"		{ process_macro();  }
<MACRO>"pragma"		{ process_macro();  }

"{"					{ process_keyword();  }
"<%"				{ process_keyword();  }
"}"					{ process_keyword();  }
"%>"				{ process_keyword();  }
"["					{ process_keyword();  }
"<:"				{ process_keyword();  }
"]"					{ process_keyword();  }
":>"				{ process_keyword();  }
"("					{ process_keyword();  }
")"					{ process_keyword();  }
";"					{ process_keyword();  if(YY_START == DATATYPE) BEGIN(INITIAL); }
":"					{ process_keyword();  }
"..."				{ process_keyword();  }
","					{ process_keyword();  }
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
"typedef"			{ process_keyword();  }
"sizeof"			{ process_keyword();  }
"while"				{ process_keyword();  }
"enum"				{ process_keyword();  }
"struct"			{ process_keyword();  }
"union"				{ process_keyword();  }

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
"="					{ process_operator(); }
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

"float"{skip}*\**	{ process_datatype(); BEGIN(DATATYPE); }
"double"{skip}*\**	{ process_datatype(); BEGIN(DATATYPE); }
"char"{skip}*\**	{ process_datatype(); BEGIN(DATATYPE); }
"int"{skip}*\**		{ process_datatype(); BEGIN(DATATYPE); }
"long"{skip}*\**	{ process_datatype(); BEGIN(DATATYPE); }
"short"{skip}*\**	{ process_datatype(); BEGIN(DATATYPE); }
"void"{skip}*\**	{ process_datatype(); BEGIN(DATATYPE); }

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
	init_hashtable(&symbol_table);
	yylex();
	printf("# Line: %d\n",yylineno);

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
	printf("#%d\tKeyword:\t%s\n",yylineno,yytext);

	return 1;
}

static int process_comment()
{
	printf("#%d\tComment:\t%s\n",yylineno, yytext);

	return 1;
}

static int process_operator() 
{
	printf("#%d\tOperator:\t%s\n",yylineno,yytext);

	return 1;
}

static int process_modifier() 
{
	printf("#%d\tModifier:\t%s\n",yylineno,yytext);

	return 1;
}

static int process_datatype() 
{
	printf("#%d\tDataType:\t%s\n",yylineno,yytext);

	return 1;
}

static int process_literal() 
{
	printf("#%d\tLiteral:\t%s\n",yylineno,yytext);

	return 1;
}

static int process_constant()
{
	printf("#%d\tConstant:\t%s\n",yylineno,yytext);

	return 1;
}

static int process_function()
{
	printf("#%d\tFunction:\t%s\n",yylineno,yytext);

	return 1;
}

static int process_identifier() 
{
	switch(YY_START)
	{
		case DATATYPE:
			printf("#%d\tVariable:\t%s\n",yylineno,yytext);
			break;
		default:
			printf("#%d\tIdentifier:\t%s\n",yylineno,yytext);
			break;
	}

	return 1;
}

static int process_macro()
{
	printf("#%d\tMacro:\t%s\n",yylineno,yytext);

	return 1;
}

static int process_struct()
{

	return 1;
}

static int process_enum()
{

	return 1;
}

static int process_union()
{

	return 1;
}
