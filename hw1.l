%{
#include <string.h>
#include <ctype.h>

#include "hashtable.h"

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

int lineno;
hashtable symbol_table;

int yywrap(void);
static void skip_comment(void);

%}

int_suffix				([uU][lL]?)|([lL][uU]?)
fraction_literal		([0-9]*\.[0-9]+)|([0-9]+\.)
exp						[eE][-+]?[0-9]+
float_suffix			[fFlL]
chartext				([^'])|(\\.)
stringtext				([^"])|(\\.)
id_letters	            ([a-zA-Z_][a-zA-Z_0-9]*)
space					([\t\f\v\r ])
skip                    ([\t\f\v\n\r ])

%s TYPEDEF
%s ENUM
%%

"\n"				{ ++lineno; }
[\t\f\v\r ]+		{}
"/*"				{ skip_comment();     }
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
";"					{ process_keyword(); BEGIN(INITIAL);}
":"					{ process_keyword();  }
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
","					{ process_operator(); }
"->"				{ process_operator(); }
"signed"			{ process_modifier(); }
"register"			{ process_modifier(); }
"const"				{ process_modifier(); }
"static"			{ process_modifier(); }
"unsigned"			{ process_modifier(); }
"volatile"			{ process_modifier(); }
"float"				{ process_datatype(); }
"double"			{ process_datatype(); }
"char"				{ process_datatype(); }
"int"				{ process_datatype(); }
"long"				{ process_datatype(); }
"short"				{ process_datatype(); }
"void"				{ process_datatype(); }
"float"				{ process_datatype(); }

"double"{skip}*\*+	{ process_datatype(); }
"char"{skip}*\*+	{ process_datatype(); }
"int"{skip}*\*+		{ process_datatype(); }
"long"{skip}*\*+	{ process_datatype(); }
"short"{skip}*\*+	{ process_datatype(); }
"void"{skip}*\*+	{ process_datatype(); }

"enum"{skip}+{id_letters}*/{skip}*\{(.|\n)*\}	{ 
													// Declartion with definition
													process_datatype(); 
													process_enum();
													BEGIN(ENUM);
												}
"enum"{skip}+{id_letters}+						{ 
													// Only declaration
													process_datatype(); 
													process_enum();
												}
"enum"/{skip}*\{(.|\n)*\}						{
													// No name enum 
													process_datatype(); 
												}
"struct"{skip}+{id_letters}+			{ 
											process_datatype();
								  			process_struct();  
										}	 
"struct"/{skip}*\{(.|\n)*\}				{ process_datatype(); } // strcut {} variable_name
"union"{skip}+{id_letters}+				{ 
											process_datatype(); 
											process_union();
										}
"union"/{skip}*\{(.|\n)*\}				{ process_datatype(); }

{id_letters}/{skip}*\((.|\n)*\)			{ process_function(); } // main(int argc, char *argv[]) 
<ENUM>{id_letters}						{ process_constant(); }
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

.										{ fprintf(stderr, "%d: unexpected character `%c'\n", lineno, yytext[0]); }

%%

int main(int argc, char *argv[])
{
	lineno = 0;
	init_hashtable(&symbol_table);
	yyin = fopen(argv[1], "r");
	yylex();
	printf("# Line: %d\n",lineno);
	fclose(yyin);

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
	printf("#%d\tDataType:\t%s\n",lineno + 1,yytext);

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
	printf("#%d\tIdentifier\t%s\n",lineno + 1,yytext);

	return 1;
}

static int process_struct()
{
	insert(&symbol_table, yytext, yyleng);
	return 1;
}

static int process_enum()
{
	insert(&symbol_table, yytext, yyleng);
	return 1;
}

static int process_union()
{
	insert(&symbol_table, yytext, yyleng);
	return 1;
}
