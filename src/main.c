#include <stdio.h>

#include "lexer.h"
#include "grammar.h"

FILE* output;

int main(int argc, char *argv[])
{
    if( argc != 2 )
    {
        fprintf(stderr, "x: NO OUTPUT\n");
        return 1;
    }

    int     res;
    FILE    * f;

    f = fopen(argv[1], "r");

    if( f == NULL )
    {
        fprintf(stderr, "x: ERROR OPENING `%s'\n",
                argv[1]);
        return 2;
    }
    
    output = fopen("test.ms", "w");
    
    if( output == NULL )
    {
        fprintf(stderr, "x: ERROR OPENING `test.masm' \n");
        return 3;
    }

    yyin    = f;
    res     = yyparse();
    fclose(f);
    
    fclose(output);

    return res;
}


