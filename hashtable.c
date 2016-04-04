#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "hashtable.h"

/*
	Generate hash key

	return hash key
*/
int hash(const char *s, size_t len)
{
	unsigned long hash = 5381;
	int c;
	
	for(int i = 0; i < len; i++)
	{
		c = s[i];
		hash = ((hash << 5) + hash) + c; /* hash * 33 + c */
	}
	
	return hash % NUM_SLOTS;
}

/*
	Return 1 if found
	type: 
		0: no insert when fail
		1: insert when fail	
*/
int find(hashtable *dst, const char *s, size_t len, int type)
{
	int key = hash(s, len);

	node *cur = dst->slots[key];
	while(cur != NULL)
	{
		if(strcmp(cur->value, s) == 0)
			return 1;
		cur = cur->next;
	}
	return 0;
}

void insert(hashtable *dst, const char *s, size_t len)
{
	int key = hash(s, len);
	node *cur = dst->slots[key];
	if(cur == NULL)
	{
		cur = malloc(sizeof(node));
		cur->value = strdup(s);
		cur->next = NULL;
		dst->slots[key] = cur;
		dst->count++;
	}
	else
	{
		while(cur->next != NULL)
			cur = cur->next;
		cur->next = malloc(sizeof(node));
		cur->next->value = strdup(s);
		cur->next->next = NULL;  
		dst->count++;
	}

}

int init_hashtable(hashtable *src)
{
	memset(src->slots, 0, sizeof(src->slots));
	src->count = 0;
}

void clear_hashtable(hashtable *table_src)
{
	int i;
	for(i = 0; i < NUM_SLOTS; i++)
	{
		if(table_src->slots[i] != NULL)
			clear_node(table_src->slots[i]);
	}
}

void clear_node(node *node)
{
	if(node->next != NULL)
		clear_node(node->next);
	free(node);
}

void print_node(node *n)
{
	printf("%s\n",n->value);
	if(n->next != NULL)
		print_node(n->next);
}

// int main(int argc, char *argv[])
// {
// 	hashtable table;
// 	init_hashtable(&table);


// 	int i;
// 	for(i = 0; i < argc; i++)
// 		insert(&table, argv[i], strlen(argv[i]));
// 	for(i = 0; i < NUM_SLOTS; i++)
// 	{
// 		if(table.slots[i] != NULL)
// 			print_node(table.slots[i]);
// 	}

// 	return 0;
// }