
struct node_t;

struct leaf_t 
{
	int id;
	char *name;
} leaf;

enum mode {LEAF, ROOT, INNER};
enum level_t {HARD, NORMAL, EASY} level;
enum {KERKER} kk;

union reocrd_t
{
	unsigned int num;
	signed char *text;
};

union 
{
	int a;
	int b;
} uu;


int
main 
(int argc, char *argv[])
{
	int m = mode;

	uu.a = 0;
	uu.b = 1;

	return 0;
}

