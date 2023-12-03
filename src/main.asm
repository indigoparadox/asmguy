
%include "src/platdos.asm"

; = Program Start/Setup =

start:
   jmp scr_setup ; Can't call since it might push.
scr_setup_done:
   call scr_clear

; = Program Main Loop =

loop:
   call poll_key
   jz loop ; Loop if no key pressed.

; = Program Cleanup =

end:
   jmp prog_shutdown

