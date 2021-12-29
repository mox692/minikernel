#include "x86.h"
#include "print.h"

#define COM1 0x3f8

void
uartputc(int c)
{
  outb(COM1+0, c);
  return;
}

void
print_str(char *str) {
    for(char* c = str; *c; c++) {
        uartputc(*c);
    }
}

void 
print_int(int n) {
  // intの最大の桁数
  int arr[10];
  int len = 0;
  do {
    arr[len] = n % 10;
    n = n * 0.1;
    len++;
  } while(1 <= n);

  for(int i = len-1; i >= 0; i--) {
      uartputc(arr[i] + '0');
  }
}