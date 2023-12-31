
bits 16 ; Assume we're using 16-bit instructions by default.
org 100h ; Tell the assembler where the program will be loaded.
cpu 186 ; Tell the assembler not to allow instructions for the 286+.
jmp start ; Skip utility routines.

%define FLAGS_BEEPING 1b

; = Poll Key =

; Registers out: ax = 0 if no key pressed.

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

; TODO: Refactor this so it can be called with call.

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
   push bp ; Stow stack bottom.
   mov bp, sp ; Put stack pointer on bp so we can do arithmetic below.
   push ax
   ;mov ax, 0aah ; Blocks of whole bytes.
   xor ax, ax
   xor di, di ; Set offset to CGA plane 1.
   call scr_clear_plane
   ;mov ax, 055h ; Blocks of whole bytes.
   mov di, 02000h ; Set offset to CGA plane 2.
   call scr_clear_plane
   pop ax
   pop bp ; Restore stack bottom stored at start of blit.
   ret

; = Copy Sprite =

; Stack:
; - Word 1 to use XOR or 0 to straight copy.
; - Pointer to the sprite data to XOR.
; - Y coordinate to draw on-screen.
; - X coordinate to draw on-screen.

blit:
   push bp ; Stow stack bottom.
   mov bp, sp ; Put stack pointer on bp so we can do arithmetic below.
   push ax ; Stow ax for a moment (Working reg).
   push cx ; Stow cx for a moment (Loop counter).
   push dx ; Stow dx for a moment (Used by mul).
   mov si, [bp + 8]
   mov cx, 0 ; Initialize offset in lines.
blit_start:
   mov ax, cx ; Offset vertically by iterated lines in current sprite.
   shr ax, 1 ; Shift 1, divide lines by 2.
   add ax, [bp + 6] ; Offset vertically by Y coord.
   mov dx, 80 ; Multiply ax by screen width (80 bytes).
   mul dx ; Multiply ax (cx/lines offset) by dx (screen width in bytes).
   add ax, [bp + 4] ; Offset horizontally by X coord.
   mov di, ax ; Move result into destination offset.
   mov dx, [bp + 10]
   test cx, 1 ; Check if cx/lines offset is even.
   jz blit_line
   add di, 2000h ; If not even, blit to second CGA plane.
blit_line:
   cmp dx, 1
   je blit_line_xor
   push cx ; Stow loop counter.
   mov cx, 4 ; rep movsb 4 times (4 * 4 px (1 byte) = 16px)
   rep movsb ; Perform the blit.
   pop cx ; Restore loop counter.
   jmp blit_line_done
blit_line_xor:
   mov word ax, [ds:si] ; Move current source line into ax.
   xor word [es:di], ax ; XOR source line onto dest line.
   mov word ax, [ds:si + 2] ; Move current source line into ax.
   xor word [es:di + 2], ax ; XOR source line onto dest line.
   add si, 4 ; Increment source line by 4 bytes for the two XORs above.
blit_line_done:
   inc cx ; Increment cx (total lines copied).
   cmp cx, 16 ; Copied 16 lines yet?
   jl blit_start ; Keep blitting lines.
   pop dx ; Restore original dx.
   pop cx ; Restore original cx.
   pop ax ; Restore original ax.
   pop bp ; Restore stack bottom stored at start of blit.
   ret 8 ; Return and dispose of 

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
   push bp ; Stow stack bottom.
   mov bp, sp ; Put stack pointer on bp so we can do arithmetic below.
   push ax ; Stow ax for later. (+2)
   push dx ; Stow dx for later. (+2)
   call midi_wait
   jnz midi_note_on_cleanup ; Cancel if MIDI never allows write.
   mov dx, 0x330 ; Set MIDI register.
   mov ax, 0x90 ; Set MIDI status to note on.
   or ax, [bp + 4] ; Channel, after +2 (ax) +2 (dx) +2 (bp) +2 (call/ret).
   out dx, ax ; Write MIDI status byte to MPU.
   mov ax, [bp + 6] ; Pitch, after +2 (ax) +2 (dx) +2 (bp) +2 (call/ret) +2.
   out dx, ax ; Write MIDI pitch byte to MPU.
   mov ax, [bp + 8] ; Velocity, after +2 (ax) +2 (dx) +2 (bp) +2 (call/ret) +4.
   out dx, ax ; Write MIDI velocity byte to MPU.
midi_note_on_cleanup:
   pop dx ; Restore dx stowed at start of midi_note_on.
   pop ax ; Restore ax stowed at start of midi_note_on.
   pop bp ; Restore stack bottom stored at start of midi_note_on.
   ret 6 ; Return and dispose of 3 word args (chan/pitch/vel).

; = MIDI Voice =

;midi_set_voice:
;   push ax ; Stow ax for later.
;   push dx ; Stow dx for later.
;   call midi_wait
;   jnz midi_set_voice_cleanup ; Cancel if MIDI never allows write.
;   mov dx, 0x330
;   mov ax, 0xc0 ; Set MIDI status to pgmchange.
;   or ax, [midi_chan]
;   out dx, ax ; Write MIDI status byte to MPU.
;   mov ax, [midi_voice]
;   out dx, ax ; Write MIDI voice byte to MPU.
;midi_set_voice_cleanup:
;   pop dx ; Restore dx stowed at start of midi_note_on.
;   pop ax ; Restore ax stowed at start of midi_note_on.
;   ret

; = Beep =

; TODO: Transform this into a "start beeping" and schedule a stop later.
; TODO: Fix persistent clicking?

spkr_beep_on:
   push bp ; Stow stack bottom.
   mov bp, sp ; Put stack pointer on bp so we can do arithmetic below.
   push ax
   ; TODO: Save the values on init and restore them later.
   mov al, 0b6h
   out 43h, al
   mov ax, [bp + 4] ; Grab frequency divisor arg.
   out 42h, al ; Send lower bits of frequency divisor.
   mov al, ah ; We can't push to out directly from ah.
   out 42h, al ; Send upper bits of frequency divisor.
   in al, 61h ; Get the keyboard controller status.
   or al, 3h ; Turn on the bits that enable the PC speaker.
   out 61h, al ; Set the new keyboard controller status.
   pop ax
   pop bp ; Restore stack bottom stored at start of spkr_beep_off.
   ret 2

spkr_beep_off:
   push bp ; Stow stack bottom.
   mov bp, sp ; Put stack pointer on bp so we can do arithmetic below.
   push ax
   in al, 61h ; Get the keyboard controller status.
   and al, 0fch ; Turn off the bits that enable the PC speaker.
   out 61h, al ; Set the new keyboard controller status.
   pop ax
   pop bp ; Restore stack bottom stored at start of spkr_beep_off.
   ret

; = Get System Ticks =

; Return: current ticks on ax.

ticks_get:
   push ds ; Stow ds.
   mov ax, 40h ; Put the BIOS data segment in bx.
   mov ds, ax ; Put bx into ds.
   mov ax, [ds:6ch] ; Put the current ticks on the stack.
   pop ds
   ret

; = Print Number String =

; Stack:
; - Word-sized integer to print.

print_num:
   push bp ; Stow stack bottom.
   mov bp, sp ; Put stack pointer on bp so we can do arithmetic below.
   push ax ; Stow ax.
   push bx ; Stow bx.
   push dx ; Stow dx.
   push word [bp + 4] ; Put input number on the new stack.
   mov bx, 10000 ; Initialize tens place counter.
print_num_digit:
   xor dx, dx ; Zero out dx.
   pop ax ; Put remainder of input number into ax.
   div bx ; Divide remainder of input number (ax) by tens place (bx).
   push dx ; Put new remainder of input number on the stack.
   mov dx, ax ; Move quotient of input number to dx.
   add dl, '0' ; Make quotient into printable digit.
   mov ax, 0200h ; Select Print Character service.
   int 21h ; Call DOS function IRQ.
   xor dx, dx ; Zero out dx.
   mov ax, bx ; Put tens place counter into ax.
   mov bx, 10 ; Dividing by 10 reduces the tens place by 1.
   div bx ; Divide tens place counter by 10.
   mov bx, ax ; Put new tens place counter back into bx.
   cmp bx, 0 ; Check tens place counter.
   jg print_num_digit
   pop ax ; Pop remaining remainder.
   pop dx ; Restore stowed dx.
   pop bx ; Restore stowed bx.
   pop ax ; Restore stowed ax.
   pop bp
   ret 2 ; Return and dispose of 

; = Program End =

prog_shutdown:
   pop ax ; Get stored video mode.
   xor ah,ah ; Zero AH.
   int 010h ; Call video interrupt; reset video.
   pop es ; Restore dest segment.
   mov ah, 04ch ; Termination service.
   int 21h ; Call function handler interrupt.

