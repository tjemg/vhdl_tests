int main( void ){
    int dummy;
    volatile int *pnt = (volatile int *)0x1000;

    *pnt = 12;
}
