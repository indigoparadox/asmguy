
bits 16
org 100h
cpu 186
jmp start ; Skip utility routines.

; = Poll Key =

poll_key:
   mov ah, 1 ; BIOS 16h service 1 (get key state).
   int 016h ; Call keyboard interrupt.
   jz poll_key_none ; Skip to end if no key pressed (ZF = 1).
   xor ah, ah ; BIOS 16x service 0 (read key).
   int 016h ; Call keyboard interrupt.
   jmp poll_key_done
poll_key_none:
   xor ax, ax ; Zero AX.
poll_key_done:
   or ah, ah ; Set zero flag if no key found.
   ret

; = Setup Screen =

scr_setup:
   push es ; Save dest segment to restore at end.
   mov bx, 0b800h ; CGA video memory segment.
   mov es, bx ; Indirectly pass bx to stosb.
   mov ax, 0f00h ; Get video mode.
   int 010h ; Call video interrupt.
   push ax ; Save video mode to restore at end.

   mov ax, 04h ; CGA mode 320x200x4.
   int 010h ; Call video interrupt.
   jmp scr_setup_done

; = Clear Screen =

scr_clear_plane:
   mov cx, 8000 ; (320 Px * 200 Px) / 4 (2-byte pairs) = 8000 bytes each.
   rep stosb ; Fill the plane.
   ret

scr_clear:
   mov ax, 0aah ; Blocks of whole bytes.
   mov di, 0h ; Set offset to CGA plane 1.
   call scr_clear_plane
   mov ax, 055h ; Blocks of whole bytes.
   mov di, 02000h ; Set offset to CGA plane 2.
   call scr_clear_plane
   ret

; = Copy Sprite =

sprite_copy:
   push ax ; Stow ax for a moment.
   push cx ; Stow cx for a moment.
   push dx ; Stow dx for a moment.
   mov cx, 0 ; Initialize offset in lines.
sprite_copy_start:
   mov ax, cx ; Offset vertically by iterated lines in current sprite.
   shr ax, 1 ; Shift 1, divide lines by 2.
   add ax, [y] ; Offset vertically by [y] in .bss.
   mov dx, 80 ; Multiply ax by screen width (80 bytes).
   mul dx ; Multiply ax (cx/lines offset) by ax (screen width in bytes).
   add ax, [x] ; Offset horizontally by [x] in .bss.
   mov di, ax ; Move result into destination offset.
   test cx, 1 ; Check if cx/lines offset is even.
   jz sprite_copy_line
   add di, 2000h ; If not even, copy to second CGA plane.
sprite_copy_line:
   push cx ; Stow loop counter.
   mov cx, 4 ; rep movsb 4 times (4 * 4 px (1 byte) = 16px)
   rep movsb ; Perform the blit.
   pop cx ; Restore loop counter.
   inc cx ; Increment cx (lines copied).
   cmp cx, 16 ; Copied 16 lines yet?
   jl sprite_copy_start ; Keep copying lines.
sprite_copy_cleanup:
   pop dx ; Restore original dx.
   pop cx ; Restore original cx.
   pop ax ; Restore original ax.
   ret

; = MIDI Wait =

midi_wait:
   push cx
   push dx
   mov cx, 30 ; Wait 30 tries.
   mov dx, 0x331 ; Check MPU status port.
midi_wait_loop:
   in ax, dx ; Get MPU status.
   test ax, 0x40 ; Check if MPU ready flag set.
   jnz midi_wait_ready
   dec cx ; Decrement timer.
   cmp cx, 0 ; Check if timeout exceeded.
   je midi_wait_timeout
   jmp midi_wait_loop
midi_wait_timeout:
   xor ax, ax ; Zero ax before returning.
midi_wait_ready:
   pop dx
   pop cx
   ret

; = MIDI Init =

midi_init:
   push dx
   push ax
   call midi_wait
   jnz midi_init_cleanup ; Cancel if MIDI never inits.
   mov ax, 0xff ; 0xff = command to put MPU in UART mode.
   mov dx, 0x331 ; Write to MPU status port.
   out dx, ax ; Output UART command to MPU.
midi_init_cleanup:
   pop ax
   pop dx
   ret

; = MIDI Note On =

midi_note_on:
   push ax ; Stow ax for later.
   push dx ; Stow dx for later.
   call midi_wait
   jnz midi_note_on_cleanup ; Cancel if MIDI never allows write.
   mov dx, 0x330
   mov ax, 0x90 ; Set MIDI status to note on.
   or ax, [midi_chan]
   out dx, ax ; Write MIDI status byte to MPU.
   mov ax, [midi_pitch]
   out dx, ax ; Write MIDI pitch byte to MPU.
   mov ax, [midi_vel]
   out dx, ax ; Write MIDI velocity byte to MPU.
midi_note_on_cleanup:
   pop dx ; Restore dx stowed at start of midi_note_on.
   pop ax ; Restore ax stowed at start of midi_note_on.
   ret

; = MIDI Voice =

midi_voice:
   push ax ; Stow ax for later.
   push dx ; Stow dx for later.
   call midi_wait
   jnz midi_voice_cleanup ; Cancel if MIDI never allows write.
   mov dx, 0x330
   mov ax, 0xc0 ; Set MIDI status to pgmchange.
   or ax, [midi_chan]
   out dx, ax ; Write MIDI status byte to MPU.
   mov ax, [midi_voice]
   out dx, ax ; Write MIDI voice byte to MPU.
midi_voice_cleanup:
   pop dx ; Restore dx stowed at start of midi_note_on.
   pop ax ; Restore ax stowed at start of midi_note_on.
   ret

; = Program End =

prog_shutdown:
   pop ax ; Get stored video mode.
   xor ah,ah ; Zero AH.
   int 010h ; Call video interrupt; reset video.
   pop es ; Restore dest segment.
   mov ah, 04ch ; Termination service.
   int 21h ; Call function handler interrupt.

