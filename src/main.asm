
%include "src/platdos.asm"

; = Program Start/Setup =

start:
   jmp scr_setup ; Can't call since it might push.
scr_setup_done:
   call scr_clear

; = Program Main Loop =

   mov si, s_maid01
   mov bx, 0b800h ; CGA video memory segment.
   mov ds, bx ; Indirectly pass bx to stosb.
   mov di, 0h ; Set offset to CGA plane 1.
   movsd

   mov si, s_maid01 + 4
   mov bx, 0b800h ; CGA video memory segment.
   mov ds, bx ; Indirectly pass bx to stosb.
   mov di, 02000h ; Set offset to CGA plane 2.
   movsd

loop:
   call poll_key
   jz loop ; Loop if no key pressed.

; = Program Cleanup =

end:
   jmp prog_shutdown

[SECTION .data]

%include "src/assets.asm"

[SECTION .bss]

