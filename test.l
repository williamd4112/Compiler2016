%{

#include <stdio.h>
#include <stdlib.h>
	
%}

%%

\n	{}
.*[:space:]*[A-Za-z_][A-Za-z_0-9]*[:spcae:]*\( 	{
							yyless(yyleng - 1);
							printf("Func: %s\n",yytext);
						}
.	{}

%%

int main(int argc, char *argv[])
{
	yylineno = 0;
	yyin = fopen(argv[1], "r");
	yylex();
	fclose(yyin);
	return 0;
}

int yywrap()
{
	return 1;	
}
