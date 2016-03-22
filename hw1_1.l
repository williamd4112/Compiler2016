Digit	[0-9]
Letter [A-Za-z]


%{
#include <stdio.h>
#include <stdlib.h>
	int yylineno;

#define PrintModifier() printf("#%d\tModifier: %s\n",yylineno + 1, yytext)
#define PrintDataType() printf("#%d\tDataType: %s\n",yylineno + 1, yytext)
#define PrintVariable() printf("#%d\tVariableID: %s\n", yylineno + 1, yytext)
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

[#].*(include).*[<].*[>]	{
					PrintPreprocessorSymbol();		
		}

<*>. 		{}
 

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

