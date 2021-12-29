#include "x86.h"
#include "types.h"
#include "print.h"

extern void int_init();
extern void seg_init();
extern void ioapic_init();

int main() {
    seg_init();
    int_init();
    ioapic_init();
    print_str("\nBoot Success \\ ^ _ ^ /\n");

    // 無限loop
    for(;;);
}