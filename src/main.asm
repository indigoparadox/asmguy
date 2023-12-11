
%include "src/platdos.asm"

char_mv_right:
   push 127
   push 100
   push 0
   call midi_note_on
   pop ax
   pop ax
   pop ax
   push ax
   mov ax, [x]
   inc ax ; Increment X.
   mov [x], ax
   pop ax
   ret

char_mv_down:
   push 127
   push 60
   push 0
   call midi_note_on
   pop ax
   pop ax
   pop ax
   push ax
   mov ax, [y]
   inc ax ; Increment Y.
   mov [y], ax
   pop ax
   ret

char_mv_up:
   push 127
   push 80
   push 0
   call midi_note_on
   pop ax
   pop ax
   pop ax
   push ax
   mov ax, [y]
   dec ax ; Decrement Y.
   mov [y], ax
   pop ax
   ret

char_mv_left:
   push 127
   push 80
   push 0
   call midi_note_on
   pop ax
   pop ax
   pop ax
   push ax
   mov ax, [x]
   dec ax ; Decrement X.
   mov [x], ax
   pop ax
   ret

char_q:
   pop ax
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
   mov si, keys_in ; Reset dx to keys array.
   add si, bx ; Add loop iterator offset to keys array.
   cmp byte [si], 0 ; Check for null keys array terminator.
   je loop ; All keys checked, return to loop.
   cmp byte [si], al
   je this_key ; This is the key. Call its callback!
   inc bx ; Increment loop iterator.
   jmp check_key ; Check the next key.
this_key:
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
keys_cb: dw char_mv_up, char_mv_down, char_mv_left, char_mv_right, char_q, 0

[SECTION .bss]

x: resb 2
y: resb 2

