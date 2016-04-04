#ifndef _HASHTABLE_
#define _HASHTABLE_

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

#endif