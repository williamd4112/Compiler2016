Digit	[0-9]
Letter [A-Za-z]


%{
#include <stdio.h>
#include <stdlib.h>
	int yylineno;

#define PrintModifier() printf("#%d\tModifier: %s\n",yylineno + 1, yytext)
#define PrintDataType() printf("#%d\tDataType: %s\n",yylineno + 1, yytext)
#define PrintVariable() printf("#%d\tVariableID: %s\n",yylineno + 1, yytext)
#define PrintFunction() printf("#%d\tFunctionID: %s\n",yylineno + 1, yytext)
#define PrintLiteral() printf("#%d\tLiteral: %s\n",yylineno + 1, yytext)
#define PrintIdentifier() printf("#%d\tIdentifier: %s\n",yylineno + 1, yytext);
#define PrintKeyword() printf("#%d\tKeyword: %s\n",yylineno + 1, yytext)
#define PrintPreprocessorSymbol() printf("#%d\tPreprocessor: %s\n",yylineno + 1, yytext)
#define PrintOperator() printf("#%d\tOperator: %s\n",yylineno + 1, yytext)
#define PrintComment() printf("#%d\tComment: %s\n",yylineno + 1, yytext)

%}

%x COMMENT
%x VARIABLE
%%

<*>\n 		{
			yylineno++;
		}
"/*"		{
			PrintComment();
			BEGIN(COMMENT);
		}
"//[.]*"	{
			PrintComment();
		}
[\(\[\{]	{
			PrintKeyword();
		}
[\)\]\}]	{
			PrintKeyword();
		}
"<:"		{
			PrintKeyword();
		}
":>"		{
			PrintKeyword();
		}
"++"		{
			PrintOperator();
		}
"+="		{
			PrintOperator();
		}
"+"		{
			PrintOperator();
		}
"--"		{
			PrintOperator();
		}
"-="		{
			PrintOperator();
		}
"->"		{
			PrintOperator();
		}
"-"		{
			PrintOperator();
		}
"*="		{
			PrintOperator();
		}
"*"		{
			PrintOperator();
		}
"/="		{
			PrintOperator();
		}
"/"		{
			PrintOperator();
		}
"%"		{
			PrintOperator();
		}
"%="		{
			PrintOperator();
		}
"<<="		{
			PrintOperator();
		}
"<<"		{
			PrintOperator();
		}
"<"		{
			PrintOperator();
		}
">>="		{
			PrintOperator();
		}
">>"		{
			PrintOperator();
		}
">"		{
			PrintOperator();
		}
"=="		{
			PrintOperator();
		}
"="		{
			PrintOperator();
		}
"!="		{
			PrintOperator();
		}
"!"		{
			PrintOperator();
		}
"&&"		{
			PrintOperator();
		}
"&="		{
			PrintOperator();
		}
"&"		{
			PrintOperator();
		}
"||"		{
			PrintOperator();
		}
"|="		{
			PrintOperator();
		}
"|"		{
			PrintOperator();
		}
"~"		{
			PrintOperator();
		}
"~="		{
			PrintOperator();
		}
";"		{
			PrintKeyword();
			BEGIN(INITIAL);
		}
":"		{
			PrintKeyword();
		}
","		{
			PrintKeyword();
		}
"const"		{
			PrintModifier();
		}
"static"	{
			PrintModifier();
		}
"inline"	{
			PrintModifier();
		}
"register"	{
			PrintModifier();
		}
"volatile"	{
			PrintModifier();
		}
"extern"	{
			PrintModifier();
		}
"unsigned"	{
			PrintModifier();
		}
"signed"	{
			PrintModifier();
		}
"short" 	{
			PrintDataType();
			//BEGIN(VARIABLE);
		}
"int" 		{
			PrintDataType();
			//BEGIN(VARIABLE);
		}
"long" 		{
			PrintDataType();
			//BEGIN(VARIABLE);
		}
"float"		{
			PrintDataType();
			//BEGIN(VARIABLE);
		}
"double"	{
			PrintDataType();
			//BEGIN(VARIABLE);
		}
"char"		{
			PrintDataType();
			//BEGIN(VARIABLE);
		}
"void" 		{
			PrintDataType();
			//BEGIN(VARIABLE);
		}
"struct"	{
			PrintDataType();
		}
"union"		{
			PrintDataType();
		}
"enum"		{
			PrintDataType();
		}
"typedef"	{
			PrintKeyword();
		}
"sizeof"	{
			PrintKeyword();
		}
"for"		{
			PrintKeyword();
		}
"do"		{
			PrintKeyword();
		}
"while"		{
			PrintKeyword();
		}
"if"		{
			PrintKeyword();
		}
"else"		{
			PrintKeyword();
		}
"switch"	{
			PrintKeyword();
		}
"case"		{
			PrintKeyword();
		}
"default"	{
			PrintKeyword();
		}
"break"		{
			PrintKeyword();
		}
"continue"	{
			PrintKeyword();
		}
"goto"		{
			PrintKeyword();
		}
"return"	{
			PrintKeyword();
		}
[a-zA-Z_][a-zA-Z0-9_]*		{
					PrintIdentifier();
				}
[-+]*[0-9]+e[-+]*[0-9]+		{
					PrintLiteral(); // 1e9
				}
[-+*]*[0]+(x|X)[A-Fa-f0-9]*	{
					PrintLiteral(); //0xfff
				}
[-+]*[0-9]*\.[0-9]+[f]?		{
					PrintLiteral(); //0.2f
				}
[-+]*[0-9]*[L]?			{
					PrintLiteral(); // 100L
				}
[L]?[\"\'].*[\"\']		{

					if(yytext[yyleng - 1] == '\\')
					{
						yymore();
					}
					else
						PrintLiteral();
				}					
<VARIABLE>[a-zA-Z_][a-zA-Z0-9_]*	{
						PrintVariable();
						BEGIN(INITIAL);
					}
<COMMENT>"*/"	{
			PrintComment();
			BEGIN(INITIAL);
		}
<*>.		{}
 
%%

int yywrap(void)
{
	return 1;
}

int main(int argc, char *argv[])
{
	yylineno = 0;
	yyin = fopen(argv[1], "r");
	yylex();
	printf("# Line: %d\n",yylineno);
	fclose(yyin);
}

