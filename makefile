CC = gcc
FLAGS = -Wall -Werror -std=c99 -D_XOPEN_SOURCE=700 -g
COMMON_HEADERS =  errormsg.h util.h

parsetest: parsetest.o y.tab.o lex.yy.o errormsg.o util.o
	$(CC) $(FLAGS) $^ -o $@

parsetest.o: parsetest.c $(COMMON_HEADERS)
	$(CC) $(FLAGS) -c parsetest.c

y.tab.o: y.tab.c
	$(CC) $(FLAGS) -c $<

y.tab.c: tiger.grm
	bison -dv $< -o $@

y.tab.h: y.tab.c
	echo "y.tab.h was created at the same time as y.tab.c"

errormsg.o: errormsg.c $(COMMON_HEADERS)
	$(CC) $(FLAGS) -c $<

lex.yy.o: lex.yy.c y.tab.h $(COMMON_HEADERS)
	$(CC) $(FLAGS) -c $<

lex.yy.c: tiger.lex
	lex tiger.lex

util.o: util.c util.h
	$(CC) $(FLAGS) -c $<

clean: 
	rm -f parsetest *.o lex.yy.c y.tab.* y.output

