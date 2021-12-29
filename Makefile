OBJS = print.o int.o trap_vectors.o ioapic.o segment.o

CC = gcc
AS = gas

# MEMO:
#  -fno-pie https://stackoverflow.com/questions/47778099/what-is-no-pie-used-for
CFLAGS = -fno-pic -static -fno-builtin -fno-strict-aliasing -O2 -Wall -MD -ggdb -m32 -Werror -fno-omit-frame-pointer
CFLAGS += $(shell $(CC) -fno-stack-protector -E -x c /dev/null >/dev/null 2>&1 && echo -fno-stack-protector)
# Disable PIE when possible (for Ubuntu 16.10 toolchain)
ifneq ($(shell $(CC) -dumpspecs 2>/dev/null | grep -e '[^f]no-pie'),)
CFLAGS += -fno-pie -no-pie
endif
ifneq ($(shell $(CC) -dumpspecs 2>/dev/null | grep -e '[^f]nopie'),)
CFLAGS += -fno-pie -nopie
endif
ASFLAGS = -m32 -gdwarf-2 -Wa,-divide

LD = ld
LDFLAGS += -m $(shell $(LD) -V | grep elf_i386 2>/dev/null | head -n 1)
OBJDUMP = objdump
OBJCOPY = objcopy

minikernel.img: bootblock kernel;
	dd if=/dev/zero of=minikernel.img count=10000
	dd if=bootblock of=minikernel.img conv=notrunc
	dd if=kernel of=minikernel.img seek=1 conv=notrunc

bootblock: bootasm.S bootmain.c;
	$(CC) $(CFLAGS) -fno-pic -O -nostdinc -I. -c bootmain.c
	$(CC) $(CFLAGS) -fno-pic -nostdinc -I. -c bootasm.S
	$(LD) $(LDFLAGS) -N -e start -Ttext 0x7C00 -o bootblock.o bootasm.o bootmain.o
	$(OBJDUMP) -S bootblock.o > bootblock.asm
	$(OBJCOPY) -S -O binary -j .text bootblock.o bootblock
	./sign.pl bootblock

kernel: $(OBJS) kernelmain.c
	$(CC) $(CFLAGS) -fno-pic -O -nostdinc -I. -c kernelmain.c -o kernelmain.o 
	$(LD) $(LDFLAGS) -N -e main -o kernel kernelmain.o $(OBJS)

QEMU = qemu-system-i386
QEMUOPTS = -drive file=minikernel.img,index=0,media=disk,format=raw -m 512  # fsimgはまだ入れてない
qemu: minikernel.img;
	$(QEMU) -serial mon:stdio $(QEMUOPTS)

# QEMU's gdb stub command line changed in 0.11
QEMUGDB = $(shell if $(QEMU) -help | grep -q '^-gdb'; \
	then echo "-gdb tcp::$(GDBPORT)"; \
	else echo "-s -p $(GDBPORT)"; fi)
GDBPORT = $(shell expr `id -u` % 5000 + 25000)
.gdbinit: .gdbinit.tmpl
	sed "s/localhost:1234/localhost:$(GDBPORT)/" < $^ > $@

qemu-nox-gdb: minikernel.img .gdbinit
	@echo "*** Now run 'gdb'." 1>&2
	$(QEMU) -nographic $(QEMUOPTS) -S $(QEMUGDB)

clean:;
	rm -f *.tex *.dvi *.idx *.aux *.log *.ind *.ilg \
	*.o *.d *.asm *.sym vectors.S bootblock entryother \
	initcode initcode.out kernel xv6.img fs.img kernelmemfs \
	xv6memfs.img mkfs .gdbinit minikernel.img \

q:;
	make clean
	make qemu

gdb:;
	make clean
	make qemu-nox-gdb

# 実際に叩くことはない、gdbのutilコマンド等
gdbin:;
	// gdb kernel
# GDB Commands... (MEMO: extended-remote modeについて https://sourceware.org/gdb/onlinedocs/gdb/Connecting.html)
	target remote localhost:25000
	b main
	la src
	c
