#include "x86.h"
#include "types.h"
#include "print.h"
#include "kbd.h"

extern void int_init();
extern void seg_init();
extern void ioapic_init();

int main() {
    seg_init();
    int_init();
    ioapic_init();
    print_str("\nBoot Success \\ ^ _ ^ /\n");
    print_str("Input key...\n");

    // 無限loop
    while (1) {
		  char c = getc();
      print_char(c);
	  }
}