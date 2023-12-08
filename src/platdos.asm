
bits 16
jmp start ; Skip utility routines.
org 100h

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
   mov ax, [y] ; Offset vertically by [y] in .bss.
   add ax, cx ; Offset vertically by iterated lines in current sprite.
   mov dx, 80 ; Multiply ax by screen width (80 bytes).
   mul dx ; Multiply ax (cx/lines offset) by ax (screen width in bytes).
   add ax, [x] ; Offset horizontally by [x] in .bss.
   mov di, ax ; Move result into destination offset.
   push cx ; Stop loop counter.
   mov cx, 4 ; rep movsb 4 times (4 * 4 px (1 byte) = 16px)
   rep movsb ; Perform the blit.
   pop cx ; Restore loop counter.
   inc cx ; Increment cx (lines copied).
   cmp cx, 8 ; Copied 8 rows yet?
   jl sprite_copy_start ; Keep copying lines.
sprite_copy_cleanup:
   pop dx ; Restore original dx.
   pop cx ; Restore original cx.
   pop ax ; Restore original ax.
   ret

; = Program End =

prog_shutdown:
   pop ax ; Get stored video mode.
   xor ah,ah ; Zero AH.
   int 010h ; Call video interrupt; reset video.
   pop es ; Restore dest segment.
   mov ah, 04ch ; Termination service.
   int 21h ; Call function handler interrupt.

