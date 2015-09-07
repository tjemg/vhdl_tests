int main( void ){
    int var1 = 0x0101;
    int var2 = 0x0037;
    int var3 = 0x1001;
    int var4 = 0x3456;
    int var5 = 0x1234;
    int var6 = var2 + var1;

    var3 = var1 + var2;
    var6 = var4 - var5;
    var1 = var2 ^ var4;
    var5 = var1 | var3;
    var3 = var1 & var2;
    var6 = var1 / var2;
    var4 = var1 * var2;
    var5 = var1 % var2;
}
