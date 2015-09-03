all: asm

asm: asm.o
	gcc -o asm asm.o

%.o: %.c
	gcc -c $<
