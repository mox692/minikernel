// Boot loader.
//
// Part of the boot block, along with bootasm.S, which calls bootmain().
// bootasm.S has put the processor into protected 32-bit mode.
// bootmain() loads an ELF kernel image from the disk starting at
// sector 1 and then jumps to the kernel entry routine.

#include "types.h"
#include "elf.h"
#include "x86.h"
#include "memlayout.h"

#define SECTSIZE  512

void readseg(uchar*, uint, uint);

void
bootmain(void)
{
  struct elfhdr *elf;
  struct proghdr *ph, *eph;
  void (*entry)(void);
  uchar* pa;
//  0x80480d0
  // MEMO: kernelのload先っぽい、ここの0x10000も決め打ち？
  elf = (struct elfhdr*)0x10000;  // scratch space

  // Read 1st page off disk
  // MEMO: HDDから、(uchar*)elfが指すpointer(からoffset 0の位置)へ、
  // 4096byte分kernelをloadする.
  // 内部ではシリアル命令を使ってHWに命令を送っている.
  readseg((uchar*)elf, 4096, 0);

  // Is this an ELF executable?
  if(elf->magic != ELF_MAGIC)
    return;  // let bootasm.S handle error

  // Load each program segment (ignores ph flags).
  // MEMO: program header tableのはじめのエントリ.
  ph = (struct proghdr*)((uchar*)elf + elf->phoff);
  // MEMO: table のエントリ数
  eph = ph + elf->phnum;
  // MEMO: 「ph++」で、「struct proghdr*」型をincrementしてるっぽいけど、
  // これはsizeof(struct proghdr*)分だけincrementされる.
  for(; ph < eph; ph++){
    pa = (uchar*)ph->paddr;
    // MEMO: 
    // pa -> 定義的には、The segment's physical address for systems in which physical addressing is relevant.
    //       Because the system ignores physical addressing for application programs,
    //       this member has unspecified contents for executable files and shared objects.
    //       となってるが、今回のcaseではこのfieldには意味がありそう.
    //       恐らく、リンカスクリプトとかでこの辺りのセグメントのアドレスを管理していそう??
    // ph -> これはelfの先頭からのoffset.
    readseg(pa, ph->filesz, ph->off);
    if(ph->memsz > ph->filesz)
      stosb(pa + ph->filesz, 0, ph->memsz - ph->filesz);
  }

  // Call the entry point from the ELF header.
  // Does not return!
  // MEMO: 上のloopでkernelのloadは完了しており、そこのentryにとぶ.
  entry = (void(*)(void))(elf->entry);
  entry();
}

void
waitdisk(void)
{
  // Wait for disk ready.
  while((inb(0x1F7) & 0xC0) != 0x40)
    ;
}

// Read a single sector at offset into dst.
// MEMO: ref https://bochs.sourceforge.io/techspec/PORTS.LST#:~:text=01F2%09r/w%09sector%20count
//
// Ref
// PIO: https://wiki.osdev.org/ATA_PIO_Mode#Hardware
void
readsect(void *dst, uint offset)
{
  // Issue command.
  waitdisk();
  outb(0x1F2, 1);   // count = 1
  outb(0x1F3, offset);
  outb(0x1F4, offset >> 8);
  outb(0x1F5, offset >> 16);
  outb(0x1F6, (offset >> 24) | 0xE0);
  outb(0x1F7, 0x20);  // cmd 0x20 - read sectors

  // Read data.
  waitdisk();
  insl(0x1F0, dst, SECTSIZE/4);
}

// Read 'count' bytes at 'offset' from kernel into physical address 'pa'.
// Might copy more than asked.
void
readseg(uchar* pa, uint count, uint offset)
{
  uchar* epa;
  // MEMO: end of physical address.
  epa = pa + count;

  // Round down to sector boundary.
  pa -= offset % SECTSIZE;

  // Translate from bytes to sectors; kernel starts at sector 1.
  // MEMO: HDDからkernelをLoadしてくる.
  // MEMO: (0 / 512) + 1 = 0 + 1 = 1
  offset = (offset / SECTSIZE) + 1;

  // If this is too slow, we could read lots of sectors at a time.
  // We'd write more to memory than asked, but it doesn't matter --
  // we load in increasing order.
  for(; pa < epa; pa += SECTSIZE, offset++)
    readsect(pa, offset);
}
