myFunc:
	NOP

_main:
	IM -2
	PUSHSPADD
	POPSP

lbl1:
	IM 32
	IM 0  ;  4096  (0x00001000)
	STORESP 4

	IM 12  ;  12  (0x0000000c)
	NOP
	IM 4  ;  4  (0x00000004)
	PUSHSP
	ADD
	STORE

	JMP LBL1
	CALL myFunc

