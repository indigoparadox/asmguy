
%include "src/platdos.asm"

; = Program Start/Setup =

start:
   jmp scr_setup ; Can't call since it might push.
scr_setup_done:
   call scr_clear

; = Program Main Loop =

   mov ax, 5
   mov [x], ax
   mov ax, 10
   mov [y], ax
   mov si, s_maid01_e ; Load si with address of maid sprite.
   call sprite_copy
loop:
   call poll_key
   jz loop ; Loop if no key pressed.

; = Program Cleanup =

end:
   jmp prog_shutdown

[SECTION .data]

%include "src/assets.asm"

[SECTION .bss]

x: resb 2
y: resb 2

