
%include "src/platdos.asm"

; = Key Handler: Character Movement =

; Stack:
; - A single word arg where 1 means decrement and 2 means increment.
; - A pointer to the memory address of the value to inc/dec.
; - Word indicating pitch of the note to play.

char_mv:
   push bp ; Stow stack bottom.
   mov bp, sp ; Put stack pointer on bp so we can do arithmetic below.
   push 127 ; Velocity
   push word [bp + 4] ; Pitch
   push 0 ; Channel
   call midi_note_on
   push s_maid01
   push word [y]
   push word [x]
   call sprite_copy
   mov si, [bp + 8] ; Put the address of the char's location in si.
   cmp word [bp + 6], 1 ; Check the stack arg to see if we inc/dec.
   je char_mv_inc
   jmp char_mv_dec
char_mv_inc:
   inc word [si] ; Increment X/Y.
   jmp char_mv_cleanup
char_mv_dec:
   dec word [si] ; Decrement X/Y.
char_mv_cleanup:
   push s_maid01
   push word [y]
   push word [x]
   call sprite_copy
   pop bp ; Restore stack bottom stored at start of char_mv.
   ret 6 ; Return and dispose of 3 word args (pitch/dec/loc).

; = Key Handler: Quit =

char_q:
   pop ax ; Dispose of key note arg.
   pop ax ; Dispose of key callback arg.
   pop ax ; Dispose of key callback pointer.
   pop ax ; Pop the return address from call... We're not coming back!
   jmp prog_shutdown

; = Program Start/Setup =

start:
   jmp scr_setup ; Can't call since it might push.
scr_setup_done:
   call scr_clear

; = Program Main Loop =

   mov ax, 5
   mov [x], ax ; Initialize X coord of sprite.
   mov ax, 10
   mov [y], ax ; Initialize Y coord of sprite.

   call midi_init

   push s_maid01
   push word [y]
   push word [x]
   call sprite_copy

loop:
   call poll_key
   jz loop ; All keys checked, return to loop.
   mov bx, 0 ; Initialize loop iterator.
check_key:
   mov si, keys_in ; Reset si to keys array.
   add si, bx ; Add loop iterator offset to keys array.
   cmp byte [si], 0 ; Check for null keys array terminator.
   je loop ; All keys checked, return to loop.
   cmp byte [si], al
   je this_key ; This is the key. Call its callback!
   inc bx ; Increment loop iterator.
   jmp check_key ; Check the next key.
this_key:
   mov si, bx ; Add loop iterator offset to key ptr array.
   shl si, 1 ; keys_vr is a word array, so offset each index by *2 bytes.
   add si, keys_vr ; Add offset to keys ptr array.
   push word [si] ; Put key ptr on the stack.
   mov si, bx ; Add loop iterator offset to keys callback arg array.
   shl si, 1 ; keys_cb is a word array, so offset each index by *2 bytes.
   add si, keys_dc ; Add offset to keys callback arg array.
   push word [si] ; Put key callback arg on the stack.
   mov si, bx ; Add loop iterator offset to key notes arg array.
   add si, keys_nt ; Add offset to key notes arg array.
   push word [si] ; Put key callback arg on the stack.
   mov si, bx ; Add loop iterator offset to callbacks array.
   shl si, 1 ; keys_cb is a word array, so offset each index by *2 bytes.
   add si, keys_cb ; Reset cx to callbacks array.
   call [si] ; Call the callback from keys_cb.
   jmp loop ; Restart the main loop.

; = Program Cleanup =

end:
   jmp prog_shutdown

[SECTION .data]

%include "src/assets.asm"

keys_in: db 'w', 's', 'a', 'd', 'q', 0
keys_dc: dw 2h,  1h,  2h,  1h,  0,   0
keys_vr: dw y,   y,   x,   x,   0,   0
keys_nt: db 20,  40,  60,  80,  0,   0
keys_cb: dw char_mv, char_mv, char_mv, char_mv, char_q, 0

[SECTION .bss]

x: resb 2
y: resb 2

