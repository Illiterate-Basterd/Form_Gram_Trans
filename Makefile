SRC_DIR  = src
GEN_DIR  = gen
CC       = gcc
LEX      = flex
BISON    = bison
OBJS     = main

BIN_DIR  = bin
BIN_NAME = compiler
OBJ_DIR  = obj
CFLAGS   = -Wall -Werror -std=c18
LDFLAGS  =

# Запуск сборки всех исходников
build: $(BIN_DIR)/$(BIN_NAME)


$(BIN_DIR)/$(BIN_NAME):
	$(MAKE) mk_dir
	$(MAKE) grammar.o
	$(MAKE) lexer.o
	$(MAKE) $(OBJS)
	$(CC) $(LDFLAGS) $(OBJ_DIR)/*.o -o $(BIN_DIR)/$(BIN_NAME)

clean:
	rm -r bin obj gen

test:
	./bin/compiler tests/${TEST}

# Создаём каталоги для временных файлов
mk_dir:
	mkdir -v $(BIN_DIR) $(OBJ_DIR)

# Здесь создаются объектные файлы
$(OBJS) :
	$(CC) $(CFLAGS) $(SRC_DIR)/$@.c -I$(GEN_DIR) -c -o $(OBJ_DIR)/$@.o

grammar.c: lexer.c
	$(BISON) $(SRC_DIR)/grammar.y --defines=$(GEN_DIR)/grammar.h -o $(GEN_DIR)/grammar.c

grammar.o: grammar.c
	$(CC) $(CFLAGS) $(GEN_DIR)/grammar.c -I$(GEN_DIR) -o $(OBJ_DIR)/grammar.o -c

lexer.c:
	mkdir -p -v $(GEN_DIR)
	$(LEX) --header-file=$(GEN_DIR)/lexer.h -o $(GEN_DIR)/lexer.c $(SRC_DIR)/lexer.l

lexer.o: lexer.c
	$(CC) $(CFLAGS) $(GEN_DIR)/lexer.c -I$(GEN_DIR) -o $(OBJ_DIR)/lexer.o -c -std=gnu18
