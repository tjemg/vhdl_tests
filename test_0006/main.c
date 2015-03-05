void _premain(void) {
    volatile int *pnt = (volatile int *)0x1000;
    int i   = 44;

    *pnt = 0;
    while (1) {
        for (i=0; i<20; i++) {
            (*pnt)++;
	}
        for (i=0; i<20; i++) {
            (*pnt)--;
	}
    }
}
