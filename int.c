#include "int.h"
#include "print.h"

struct gatedesc idt[256];

void default_handler() {
    // とりあえず無限loop
    for(;;);
}

extern void kbd_handler();

inline void
lidt(struct gatedesc *p, int size)
{
  volatile ushort pd[3];

  pd[0] = size-1;
  pd[1] = (uint)p;
  pd[2] = (uint)p >> 16;

  asm volatile("lidt (%0)" : : "r" (pd));
  print_str("\nlidt Done ...\n");
}

void set_intr_desc(int index, int is_trap, int sel, void *addr, int d)
{
	idt[index].off_15_0 = (uint)(addr) & 0xffff;
	idt[index].cs = SEG_KCODE<<3;
	idt[index].args = 0;
	idt[index].rsv1 = 0;
	idt[index].type = (is_trap) ? STS_TG32 : STS_IG32;
	idt[index].p = 1;
	idt[index].dpl = d;
	idt[index].s = 0;
	idt[index].off_31_16 = (uint)(addr) >> 16;
}

void
int_init() {
    // defaultハンドラを登録
    for(int i = 0; i < 256; i++) {
        set_intr_desc(i, 0, SEG_KCODE<<3, default_handler, 0);
    }

    // kbdハンドラを登録
    set_intr_desc(KBC_INTR_NO, 0, SEG_KCODE<<3, kbd_handler, 0);

    // lidt命令
    lidt(idt, sizeof(idt));
}
