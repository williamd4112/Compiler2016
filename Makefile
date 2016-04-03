CC=gcc
EXECUTABLE=hw1
SRC=hashtable.c lex.yy.c
INC=hashtable.h
LEX=flex
LEXER=hw1.l
GCC_OPTION=-o

all:
	$(LEX) $(LEXER)
	$(CC) $(SRC) $(GCC_OPTION) $(EXECUTABLE) -L$(INC)
	./$(EXECUTABLE) < testcase/testcase3.c
