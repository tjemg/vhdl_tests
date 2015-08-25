/*
 * (C) 2015, Tiago Gasiba
 *
 * Parts of this code have been taken from
 *     http://www.coranac.com/2009/07/sines/
 */


int isin_S3(int x) {
	// S(x) = x * ( (3<<p) - (x*x>>r) ) >> s
	// n : Q-pos for quarter circle             13
	// A : Q-pos for output                     12
	// p : Q-pos for parentheses intermediate   15
	// r = 2n-p                                 11
	// s = A-1-p-n                              17

	const int qN = 13, qA= 12, qP= 15, qR= 2*qN-qP, qS= qN+qP+1-qA;

	x = x<<(30-qN);          // shift to full s32 range (Q13->Q30)

	if ( (x^(x<<1)) < 0)     // test for quadrant 1 or 2
		x= (1<<31) - x;

	x = x>>(30-qN);

	return x * ( (3<<qP) - (x*x>>qR) ) >> qS;
}

void _premain(void) {
    volatile int *pnt = (volatile int *)0x1000;
    int           i   = 0;
    int           tmp;
    int           Sin;
    
    //const int qN = 13;
    //const int qA = 12;
    //const int qP = 15;
    //const int qR = 2*qN-qP;
    //const int qS = qN+qP+1-qA;

    while (1) {
      //tmp = i<<(30-qN);          // shift to full s32 range (Q13->Q30)
      //if ( (tmp^(tmp<<1)) < 0) {
      //  // test for quadrant 1 or 2
      //  tmp= (1<<31) - tmp;
      //}
      //tmp = tmp>>(30-qN);
      //Sin = tmp * ( (3<<qP) - (tmp*tmp>>qR) ) >> qS;

        //*pnt = Sin;
        *pnt = isin_S3(i);
	i   += 0x00000006;
    }
}
