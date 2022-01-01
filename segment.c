#include "segment.h"
#include "print.h"

// TODO: segmentをいくつかに分ける

segdesc gdt[1];

static inline void
lgdt(segdesc *p, int size)
{
  volatile ushort pd[3];

  pd[0] = size-1;
  pd[1] = (uint)p;
  pd[2] = (uint)p >> 16;
  asm volatile("lgdt (%0)" : : "r" (pd));
  print_str("\nlgdt Done ...\n");
}

segdesc
set_gdt_entry(int type, uint base, uint lim, int dpl) {
    segdesc desc;
    desc.lim_15_0 = lim & 0xffff;
    desc.base_15_0 = base & 0xffff;
    desc.base_23_16 = base & 0xff0000;
    desc.type = type;
    desc.lim_19_16 = lim & 0xf0000;
    desc.avl = 0;
    desc.rsv1 = 0;
    desc.db = 1;
    desc.g = 1;
    desc.base_31_24 = base & 0xff000000;
    return desc;
}

void
seg_init() {
    // TODO: 全部特権で割り当ててる.
    gdt[0] = set_gdt_entry(SEG_EX | SEG_WRITE | SEG_READ, 0, 0xffffffff, 0);
    lgdt(gdt, sizeof(gdt));
}
