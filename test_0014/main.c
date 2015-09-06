/*
 * (C) 2015, Tiago Gasiba
 *
 * Parts of this code have been taken from
 *     http://www.coranac.com/2009/07/sines/
 */


void _premain(void) {
    volatile int *pnt = (volatile int *)0x1000;

    *pnt = 12;
}
