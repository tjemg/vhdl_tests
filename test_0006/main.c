void _premain(void) {
    volatile int *pnt = (volatile int *)0x1000;

    *pnt = 4;
    while (1) {
        (*pnt)++;
    }
}
