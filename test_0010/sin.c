#include <stdio.h>
#include <stdlib.h>
#include <math.h>

int main( void ) {
    int ii;

    for (ii=0; ii<256; ii++) {
        printf("%d => x\"%.04x\",\n",ii,0xffff & (int)(15000*sin(2*3.1416*1.0*ii/256)));
    }

    return 0;
}
