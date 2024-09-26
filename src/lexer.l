%option nounput
%option noinput
%option noyywrap

%{

#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <assert.h>

#include "grammar.h"

/* Контейнер для положения символа в тексте */
typedef struct
{
    int line;  
    int colomn;
} Position_t;

/* Переменная, в которой храним текущую позицию */
static Position_t Position = {1, 1};

/* Количество строк, на которое сдвигаемся */
static void incrLine(int num) {Position.line += num;}

/* Текущая строка в читаемом файле */
static int line(void) {return Position.line;}

/* Количество столбцов, на которое сдвигаемся */
static void incrColomn(int num) {Position.colomn += num;}

/* Текущий столбец в читаемом файле */
static int colomn(void) {return Position.colomn;}

/* Сбрасываем текущий столбец в читаемом файле в начало строки */
static void dropColomn(void) {Position.colomn = 1;}

/* Автоматическое действие при чтении лексемы */
#define YY_USER_ACTION { \
    yylloc.first_line   = line(); \
    yylloc.last_line    = line(); \
    yylloc.first_column = colomn(); \
    yylloc.last_column  = colomn() + yyleng - 1; \
    incrColomn(yyleng); }

%}

/* Здесь описываем состояния, в которые попадает лексический анализатор */

/* Состояние многострочного коментария */
%x COMMENT

NUMBER [0-9]+
SPACE [ \t]*
IDENTIFIER [a-zA-Z_][a-zA-Z_0-9]*
NOT_AVIABLE [^a-zA-Z_0-9+\-*/><!;,=(){}\[\]&|'" \n\t]

%%

"/*"                    { BEGIN(COMMENT); }
<COMMENT>.
<COMMENT>"*/"           { BEGIN(INITIAL); }

if                      { return TOK_IF; }
"else if"               { return TOK_ELIF; }
else                    { return TOK_ELSE; }
while					{ return TOK_WHILE; }
print					{ return TOK_PRINT; }
return                  { return TOK_RET; }

[+\-*/><!;,=(){}\[\]&]  { return yytext[0]; }

"&&"                    { return TOK_LOGIC_AND; }
"||"                    { return TOK_LOGIC_OR; }
"=="                    { return TOK_IS_EQ; }
"!="                    { return TOK_IS_NOT_EQ; }
">="                    { return TOK_IS_GEQ; }
"<="                    { return TOK_IS_LEQ; }

{NUMBER}                { yylval.value = atoi(yytext); return TOK_NUMBER; }
{IDENTIFIER}            { yylval.name = strdup(yytext); return TOK_IDENT; }
{SPACE}                 { /* */ }

<*>\n                   { dropColomn(); incrLine(1);yylloc.first_line++;}

.                       {;}

%%
