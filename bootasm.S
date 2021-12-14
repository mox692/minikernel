#include "asm.h"
#include "memlayout.h"
#include "mmu.h"

# Start the first CPU: switch to 32-bit protected mode, jump into C.
# The BIOS loads this code from the first sector of the hard disk into
# memory at physical address 0x7c00 and starts executing in real mode
# with %cs=0 %ip=7c00.

# 16bit mode -> ref: https://ftp.gnu.org/old-gnu/Manuals/gas-2.9.1/html_node/as_203.html
.code16                       # Assemble for 16-bit
.globl start
start:
  cli                         # BIOS enabled interrupts; disable

  # Zero data segment registers DS, ES, and SS.
  # MEMO: 16bit modeなので、演算にも16bitレジスタを使用する.
  # MEMO: instructionも16bit用のinstruction(movwなど).
  xorw    %ax,%ax             # Set %ax to zero
  movw    %ax,%ds             # -> Data Segment
  movw    %ax,%es             # -> Extra Segment
  movw    %ax,%ss             # -> Stack Segment

  # Physical address line A20 is tied to zero so that the first PCs 
  # with 2 MB would run software that assumed 1 MB.  Undo that.
  # ref: https://cstmize.hatenablog.jp/entry/2019/06/11/A20_gate%E3%81%A8keyboard_controller%E3%81%A8%E3%81%AE%E3%82%84%E3%82%8A%E3%81%A8%E3%82%8A%28xv6%E3%82%92%E4%BE%8B%E3%81%AB%E3%81%97%E3%81%A6%29
  #      https://www.quora.com/What-is-the-A20-gate-in-a-CPU
  #      https://www.techarp.com/bios-guide/gate-a20-option/
  # ports ref: https://bochs.sourceforge.io/techspec/PORTS.LST
seta20.1:
  inb     $0x64,%al               # Wait for not busy
  # difference `cmp` and `test`: https://stackoverflow.com/questions/39556649/in-x86-whats-difference-between-test-eax-eax-and-cmp-eax-0
  # MEMO: input bufとout bufがfullじゃなくなったらloopを抜ける
  testb   $0x2,%al
  jnz     seta20.1

  movb    $0xd1,%al               # 0xd1 -> port 0x64
  outb    %al,$0x64

seta20.2:
  inb     $0x64,%al               # Wait for not busy
  testb   $0x2,%al
  jnz     seta20.2

  movb    $0xdf,%al               # 0xdf -> port 0x60
  # MEMO: ここでA20lineを有効化してる (https://bochs.sourceforge.io/techspec/PORTS.LST#:~:text=DF%09sngl%20%20enable%20address%20line%20A20%20(HP%20Vectra%20only%3F%3F%3F))
  outb    %al,$0x60

  # Switch from real to protected mode.  Use a bootstrap GDT that makes
  # virtual addresses map directly to physical addresses so that the
  # effective memory map doesn't change during the transition.
  # MEMO: やってることとしては、
  # * gdtをLoadする
  # * cr0レジスタに0x00000001をセットする
  lgdt    gdtdesc
  movl    %cr0, %eax
  orl     $CR0_PE, %eax
  movl    %eax, %cr0

//PAGEBREAK!
  # Complete the transition to 32-bit protected mode by using a long jmp
  # to reload %cs and %eip.  The segment descriptors are set up with no
  # translation, so that the mapping is still the identity mapping.
  # MEMO: 第一引数 -> csレジスタを8( SEG_ASM(STA_X|STA_R, 0x0, 0xffffffff) )エントリ目を指すように
  # MEMO: 第二引数 -> ipをstart32に。
  ljmp    $(SEG_KCODE<<3), $start32

.code32  # Tell assembler to generate 32-bit code now.
start32:
  # Set up the protected-mode data segment registers
  movw    $(SEG_KDATA<<3), %ax    # Our data segment selector
  movw    %ax, %ds                # -> DS: Data Segment
  movw    %ax, %es                # -> ES: Extra Segment
  movw    %ax, %ss                # -> SS: Stack Segment
  movw    $0, %ax                 # Zero segments not ready for use
  movw    %ax, %fs                # -> FS
  movw    %ax, %gs                # -> GS

  # Set up the stack pointer and call into C.
  # MEMO: start(0x7C00)からの領域(startより小さいaddressの領域)をstackに使う(なんでここなのかは謎.)
  movl    $start, %esp
  call    bootmain

  # If bootmain returns (it shouldn't), trigger a Bochs
  # breakpoint if running under Bochs, then loop.
  movw    $0x8a00, %ax            # 0x8a00 -> port 0x8a00
  movw    %ax, %dx
  outw    %ax, %dx
  movw    $0x8ae0, %ax            # 0x8ae0 -> port 0x8a00
  outw    %ax, %dx
spin:
  jmp     spin

# Bootstrap GDT
# TODO: なぜ初めにnull segを用意する？
# MEMO: codesegとdatasegがかぶってるけど問題ないの？
# ref: https://vmm.dev/ja/lowlevel/xv6/xv6-1.md#GDT_is_%E4%BD%95
.p2align 2                                # force 4 byte alignment
gdt:
  SEG_NULLASM                             # null seg
  SEG_ASM(STA_X|STA_R, 0x0, 0xffffffff)   # code seg
  SEG_ASM(STA_W, 0x0, 0xffffffff)         # data seg

# MEMO: word, longは擬似命令: http://www.hpcs.cs.tsukuba.ac.jp/~msato/lecture-note/kikaigo2008/lecture2.pdf
# MEMO: `gdtdesc`というラベルがついた先頭部分から16bitは(gdtdesc - gdt - 1)を入れて、その直後の32bitにはgdtを入れる.
gdtdesc:
  .word   (gdtdesc - gdt - 1)             # sizeof(gdt) - 1
  .long   gdt                             # address gdt

