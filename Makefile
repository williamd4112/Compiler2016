CC=gcc
EXECUTABLE=hw1
SRC=lex.yy.c
LEX=flex
LEXER=hw1.l
GCC_OPTION=-o

all:
	$(LEX) $(LEXER)
	$(CC) $(SRC) $(GCC_OPTION) $(EXECUTABLE)

