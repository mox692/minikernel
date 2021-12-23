
const int COM1 = 0x3f8;
int foo() {
    asm volatile("nop");
    asm volatile("out %0,%1" : : "a" (COM1), "d" (1));
    asm volatile("nop");
    return 0;
}
int add(int a, int b) {
    asm volatile("nop");
    return a + b;
}
int sub() {
    asm volatile("nop");
    int a = add(3,5);
    asm volatile("nop");
    return a;
}
int main() {
    // Emulate `outb(COM1+2, 0);`
    asm volatile("nop");
    foo();
    asm volatile("nop");
    sub();
}