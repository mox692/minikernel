#include "int.h"

.globl kbd_handler
kbd_handler:
  pushl $0
  pushl $0
  # Build trap frame.
  pushl %ds
  pushl %es
  pushl %fs
  pushl %gs
  pushal
  
  # Set up data segments.
  movw $(SEG_KDATA<<3), %ax
  movw %ax, %ds
  movw %ax, %es

  # Call trap(tf), where tf=%esp
  pushl %esp
  # TODO: trapの実装
  # call trap