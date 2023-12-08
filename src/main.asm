
%include "src/platdos.asm"

char_mv_right:
   push ax
   mov ax, 0
   mov [midi_chan], ax
   mov ax, 100
   mov [midi_pitch], ax ; Set MIDI pitch byte.
   mov ax, 127
   mov [midi_vel], ax ; Set MIDI velocity byte.
   call midi_note_on
   mov ax, [x]
   inc ax ; Increment X.
   mov [x], ax
   pop ax
   ret

char_mv_down:
   push ax
   mov ax, 0
   mov [midi_chan], ax
   mov ax, 60
   mov [midi_pitch], ax ; Set MIDI pitch byte.
   mov ax, 127
   mov [midi_vel], ax ; Set MIDI velocity byte.
   call midi_note_on
   mov ax, [y]
   inc ax ; Increment Y.
   mov [y], ax
   pop ax
   ret

char_mv_up:
   push ax
   mov ax, 0
   mov [midi_chan], ax
   mov ax, 80
   mov [midi_pitch], ax ; Set MIDI pitch byte.
   mov ax, 127
   mov [midi_vel], ax ; Set MIDI velocity byte.
   call midi_note_on
   mov ax, [y]
   dec ax ; Decrement Y.
   mov [y], ax
   pop ax
   ret

char_mv_left:
   push ax
   mov ax, 0
   mov [midi_chan], ax
   mov ax, 40
   mov [midi_pitch], ax ; Set MIDI pitch byte.
   mov ax, 127
   mov [midi_vel], ax ; Set MIDI velocity byte.
   call midi_note_on
   mov ax, [x]
   dec ax ; Decrement X.
   mov [x], ax
   pop ax
   ret

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
   mov si, s_maid01_e ; Load si with address of maid sprite.
   call sprite_copy

   call poll_key
check_q:
   jz loop ; Loop if no key pressed.
   cmp al, 'q' ; Check for key 'q'.
   jne check_d ; Skip to next check.
   jmp end ; Quit on 'q'.
check_d:
   cmp al, 'd' ; Check for key 'd'.
   jne check_s ; Skip to next check.
   call char_mv_right
   jmp loop
check_s:
   cmp al, 's' ; Check for key 's'.
   jne check_w ; Skip to next check.
   call char_mv_down
   jmp loop
check_w:
   cmp al, 'w' ; Check for key 'w'.
   jne check_a ; Skip to next check.
   call char_mv_up
   jmp loop
check_a:
   cmp al, 'a' ; Check for key 'a'.
   jne check_done ; Skip to next check.
   call char_mv_left
   jmp loop
check_done:
   jmp loop

; = Program Cleanup =

end:
   jmp prog_shutdown

[SECTION .data]

%include "src/assets.asm"

[SECTION .bss]

x: resb 2
y: resb 2
midi_pitch: resb 1
midi_vel: resb 1
midi_chan: resb 1
midi_Voice: resb 1

