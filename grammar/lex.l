%{
	#include <stdio.h>
	#include <stdlib.h>
	int lineno;

%}

%%

\n	{lineno++;}
.	{}

%%

int yywrap()
{
	return 1;
}

int main(int argc, char *argv[])
{
	lineno = 0;
	yyin = fopen(argv[1], "r");
	yylex();
	fclose(yyin);
	
	printf("# Line = %d\n",lineno);
	return 0;
}

