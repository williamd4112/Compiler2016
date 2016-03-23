#include <stdio.h>

struct Type1
{
	int id;
	char *name;
};

struct Type2
{
	int id;
	char *name;
} type2;

struct 
{
	int id;
	char *name;
} structure;


enum {LEAF, INNER} e;


static int a = 40;

void add(int a, int b =10)
{
	printf("%d\n",b);
}

int main(int argc, char *argv[])
{
	//int i = e;
	//type2.id = 1;
	//printf("%d\n",e);
	int a = a;
	{
		int a;
		a = 10;
	}	
	printf("%d\n",a);	
	
	return 0;
}
