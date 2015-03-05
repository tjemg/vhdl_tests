void _premain(void) {
    volatile int *pnt = (volatile int *)0x1000;
    int i   = 44;

    *pnt = i;
    while (1) {
        *pnt = i;
	i++;
    }
}
