
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
   push 1 ; XOR to copy sprite (to erase previous position).
   push s_maid01 ; Push pointer to player sprite.
   push word [y] ; Push  player old Y.
   push word [x] ; Push  player old X.
   call blit
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
   push 1 ; XOR to copy sprite.
   push s_maid01 ; Push pointer to player sprite.
   push word [y] ; Push player new Y.
   push word [x] ; Push player new X.
   call blit
   pop bp ; Restore stack bottom stored at start of char_mv.
   ret 6 ; Return and dispose of 3 word args (pitch/dec/loc).

; = Key Handler: Quit =

char_q:
   pop ax ; Dispose of key note arg.
   pop ax ; Dispose of key callback arg.
   pop ax ; Dispose of key callback pointer.
   pop ax ; Pop the return address from call... We're not coming back!
   jmp prog_shutdown

; = Draw Map =

; Stack:
; - Pointer to the map tiles array to draw from.

map_blit:
   push bp ; Stow stack bottom.
   mov bp, sp ; Put stack pointer on bp so we can do arithmetic below.
   push ax
   push bx
   push dx
   xor bx, bx ; Zero loop iterator.
map_blit_tile:
   mov ax, bx ; Put loop counter in ax for div.
   push bx ; Stow loop iterator so div can use bx.
   push si ; Stow si so we can index some arrays.
   mov si, ax ; Add loop counter to map tiles array.
   add si, [bp + 4] ; Add offset to map passed as arg.
   xor bx, bx ; Zero out bx.
   mov bl, [si] ; Get single-byte index of tile in tileset from map.
   shl bx, 1 ; Multiply tile index by 2 since tileset is word array.
   add bx, tileset ; Add memory offset of tileset index array.
   cmp word [bx], 0 ; See if tile is blank.
   je map_blit_tile_blank
   push 0 ; Arg to blit: Copy sprite.
   push word [bx] ; Pointer to tile to draw.
   xor dx, dx ; Zero out dx for div.
   mov bx, 20 ; Divisor: Maps are 20 tiles wide (300px / 16px).
   div bx ; Get X/Y of this tile: divide loop counter (ax) by bx.
   shl ax, 3 ; Multiply Y by tile height.
   push ax ; Push tile Y (idx / tile width).
   shl dx, 2 ; Multiply X by tile width.
   push dx ; Push tile X (idx % tile width).
   call blit
map_blit_tile_blank:
   pop si ; Restore si pushed at start of map_blit_tile.
   pop bx ; Restore loop counter pushed at start of map_blit_tile.
   inc bx ; Increment loop counter.
   cmp bx, 240 ; If we've reached the maximum tiles in a map, quit.
   jne map_blit_tile
   pop dx
   pop bx
   pop ax
   pop bp ; Restore stack bottom stored at start of char_mv.
   ret 2 ; Skip arg (map to blit).

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

   push map_field
   call map_blit

   push 1 ; XOR to copy sprite.
   push s_maid01 ; Push pointer to player sprite.
   push word [y] ; Push  player Y.
   push word [x] ; Push  player X.
   call blit

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

tileset: dw 0, t_rock
map_field: db \
   01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, \
   01h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 01h, \
   01h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 01h, \
   01h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 01h, \
   01h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 01h, \
   01h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 01h, \
   01h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 01h, \
   01h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 01h, \
   01h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 01h, \
   01h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 01h, \
   01h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h, 01h, \
   01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h, 01h

[SECTION .bss]

x: resb 2
y: resb 2

