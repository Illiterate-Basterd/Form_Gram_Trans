%locations

%{
  /* Это первая секция файла для bison */

  #include <stdio.h>
  #include <string.h>
  #include <stdlib.h>
  #include <assert.h>
  #include "lexer.h"
  
  #define SZ 50
  
  /* Глобальные переменные */ 
  extern FILE* output;
   
  int inner 		= 0;
  int end_if 		= 0;
  int start_while 	= 0;
  
  int temp 		= 0;
  int flag		= 0;
  
  typedef struct Stack {
	int data[SZ];
	int size;
  } stack;
  
  stack stack_inner;
  stack stack_end_if;
  stack stack_start_while; 

  int yylex (void);
  void yyerror (char const * s);

  int pop(stack*);
  void push(int, stack*);
%}


%token TOK_IF TOK_ELIF TOK_ELSE TOK_WHILE TOK_PRINT TOK_RET
%token TOK_LOGIC_AND TOK_LOGIC_OR TOK_IS_EQ TOK_IS_NOT_EQ
%token TOK_IS_GEQ TOK_IS_LEQ

%union
{
 int value;
 char *name;
}

%token <name> TOK_IDENT 
%token <value> TOK_NUMBER

%left TOK_LOGIC_AND TOK_LOGIC_OR
%left '<' '>' TOK_IS_EQ TOK_IS_NOT_EQ TOK_IS_GEQ TOK_IS_LEQ
%left '-' '+'
%left '*' '/'
%left TOK_UMIN TOK_NOT 
%left '(' ')'

%start program

%%

program:
  start_label OK { fprintf(stdout, "Translation complete\n"); }
;

start_label:
  %empty { fprintf(output, "asm: \n");   }

OK:
  some_body          
;

some_body:
  some_body statement          
| %empty                       
;

statement:
  single_statement ';'  
| if_statement          
| while_statement       
;

single_statement:
  assign_statement    
| print_expr	      
| return_expr         
;

assign_statement:
  TOK_IDENT '=' expr     { fprintf (output, "\tPOP %s\n", $1); }
;

print_expr:
  TOK_PRINT expr 	{ fprintf (output, "\tCALL print \n"); fprintf (output, "\tPOP \n"); }
;

return_expr:
  TOK_RET return_expr_tail 	{ fprintf (output, "\tRET \n"); }
;

return_expr_tail:
  expr      
| %empty    
;

if_statement:
  if_statement_head                             { temp = pop(&stack_inner); fprintf(output, "label_%d: \n", temp);  temp = pop(&stack_end_if); if (flag) { fprintf(output, "end_%d: \n", temp); flag = 0;} }
| if_statement_head pre_else '{' some_body '}'  { temp = pop(&stack_end_if); fprintf(output, "if_end_%d: \n", temp); }
;

pre_else:
  TOK_ELSE 	{ flag = 1; temp = pop(&stack_end_if); push(temp, &stack_end_if); fprintf(output, "\tJMP end_%d \n", temp);  temp = pop(&stack_inner); fprintf(output, "label_%d: \n", temp);}
; 

if_statement_head:
  pre_if '(' expr ')' '{' some_body '}' elif_statement  
;

pre_if:
  TOK_IF 	{ flag = 0; push(end_if, &stack_end_if); end_if++; }
;

elif_statement:
  pre_elif '(' expr ')' '{' some_body '}' elif_statement    
| %empty                                                    
;

pre_elif:
  TOK_ELIF 	{ flag = 1; temp = pop(&stack_end_if); push(temp, &stack_end_if); fprintf(output, "\tJMP end_%d \n", temp);  temp = pop(&stack_inner); fprintf(output, "label_%d: \n", temp);} 
;  

while_statement:
  pre_while '(' expr ')' '{' some_body '}' 	{ temp = pop(&stack_start_while); fprintf(output, "\tJMP start_%d \n", temp); temp = pop(&stack_inner); fprintf(output, "label_%d: \n", temp); }
;

pre_while:
  TOK_WHILE 	{ push(start_while, &stack_start_while); fprintf(output, "start_%d: \n", start_while); start_while++; }
;

expr:
  TOK_NUMBER                    { fprintf (output, "\tPUSH %d\n", $1); }
| TOK_IDENT              	      { fprintf (output, "\tPUSH %s\n", $1); }
| '(' expr ')'                  { /* */ }
| expr '+' expr                 { fprintf (output, "\tADD \n"); }
| expr '-' expr                 { fprintf (output, "\tSUB \n"); }
| expr '*' expr                 { fprintf (output, "\tMUL \n"); }
| expr '/' expr                 { fprintf (output, "\tDIV \n"); }
| expr '<' expr                 { fprintf (output, "\tCMP \n"); fprintf(output, "\tJGE label_%d \n", inner); push(inner, &stack_inner); inner++; }
| expr '>' expr                 { fprintf (output, "\tCMP \n"); fprintf(output, "\tJLE label_%d \n", inner); push(inner, &stack_inner); inner++; }
| expr TOK_LOGIC_AND expr       { fprintf (output, "\tAND \n"); }
| expr TOK_LOGIC_OR expr        { fprintf (output, "\tOR  \n"); }
| expr TOK_IS_EQ expr           { fprintf (output, "\tCMP \n"); fprintf(output, "\tJNE label_%d \n", inner); push(inner, &stack_inner); inner++; }
| expr TOK_IS_NOT_EQ expr       { fprintf (output, "\tCMP \n"); fprintf(output, "\tJE label_%d \n", inner); push(inner, &stack_inner); inner++; }
| expr TOK_IS_GEQ expr          { fprintf (output, "\tCMP \n"); fprintf(output, "\tJL label_%d \n", inner); push(inner, &stack_inner); inner++; }
| expr TOK_IS_LEQ expr          { fprintf (output, "\tCMP \n"); fprintf(output, "\tJG label_%d \n", inner); push(inner, &stack_inner); inner++;}
| '-' expr  %prec TOK_UMIN      { fprintf (output, "\tNEG \n"); }
| '!' expr  %prec TOK_NOT       { fprintf (output, "\tNEG \n"); }
;

%%

int pop(stack* stack_labels)
{
    stack_labels->size--;
    return stack_labels->data[stack_labels->size];
}

void push(int number, stack* stack_labels)
{
    stack_labels->data[stack_labels->size] = number;
    stack_labels->size++;
}

void yyerror(char const * msg)
{
    fprintf (stderr,
             "ERROR: %d:%d: %s\n",
             yylloc.first_line,
             yylloc.first_column,
             msg);
    fprintf (stderr, 
	     "Translation error\n");
    exit(1);
}
