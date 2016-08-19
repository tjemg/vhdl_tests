/*
 * (C) 2015, Tiago Gasiba
 *
 * Parts of this code have been taken from
 *     http://www.coranac.com/2009/07/sines/
 */

static __attribute__ ((noinline)) int func( int a, int b) {
  volatile int x;
  volatile int y;
  volatile int z;

  x = 1;
  y = 2;
  z = 3;
  return a+b;
}

void _premain(void) {
    volatile int *pnt = (volatile int *)0x1000;

    volatile int v = func(10, 20);
    *pnt = 12 + v;
}
