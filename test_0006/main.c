void _premain(void) {
    volatile int *pnt = (volatile int *)0x4444;
    
    while (1) {
        *pnt++;
    }
}
