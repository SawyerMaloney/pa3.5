#include <stdio.h>
#include <stdlib.h>

#include "errormsg.h"
#include "util.h"

extern int yyparse();

void parse(string fname) {
    EM_reset(fname);
    if (yyparse() == 0) {
        printf("Parsing successful!\n");
    } else {
        fprintf(stderr,"Parsing failed\n");
    }
}


int main(int argc, char ** argv) {
    if (argc != 2) {
        fprintf(stderr,"usage: a.out filename\n");
        exit(EXIT_FAILURE);
    }
    parse(argv[1]);
    return EXIT_SUCCESS;
}
