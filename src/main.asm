
%include "src/platdos.asm"

; = Key Handler: Character Movement =

; Stack:
; - A single word arg where 1 means decrement and 2 means increment.
; - A pointer to the memory address of the value to inc/dec.

char_mv:
   push 127 ; Velocity
   push 40 ; Pitch
   push 0 ; Channel
   call midi_note_on
   pop ax ; Dispose of channel.
   pop ax ; Dispose of pitch.
   pop ax ; Dispose of velocity.
   push bp ; Stow stack frame.
   mov bp, sp ; Put stack pointer on bp so we can do arithmetic below.
   and sp, 0xfff0 ; Align stack to allow arithmetic below.
   mov si, [bp + 6] ; Put the address of the char's location in si.
   cmp word [bp + 4], 1 ; Check the stack arg to see if we inc/dec.
   je char_mv_inc
   jmp char_mv_dec
char_mv_inc:
   inc word [si] ; Increment X.
   jmp char_mv_cleanup
char_mv_dec:
   dec word [si] ; Increment X.
char_mv_cleanup:
   mov sp, bp ; Restore stack pointer.
   pop bp ; Restore stack frame stored at start of midi_note_on.
   ret

; = Key Handler: Quit =

char_q:
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

loop:
   mov si, s_maid01 ; Load si with address of maid sprite.
   call sprite_copy

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
   mov si, bx ; Add loop iterator offset to callbacks array.
   shl si, 1 ; keys_cb is a word array, so offset each index by *2 bytes.
   add si, keys_cb ; Reset cx to callbacks array.
   call [si] ; Call the callback from keys_cb.
   pop ax ; Dispose of key callback arg.
   pop ax ; Dispose of key callback pointer.
   jmp loop ; Restart the main loop.

; = Program Cleanup =

end:
   jmp prog_shutdown

[SECTION .data]

%include "src/assets.asm"

keys_in: db 'w', 's', 'a', 'd', 'q', 0
keys_dc: dw 2h,  1h,  2h,  1h,  0,   0
keys_vr: dw y,   y,   x,   x,   0,   0
keys_cb: dw char_mv, char_mv, char_mv, char_mv, char_q, 0

[SECTION .bss]

x: resb 2
y: resb 2

