
# vi:syntax=make noexpandtab

ASMS = src/main.asm

asmguy.com: $(ASMS)
	nasm -f bin -o $@ $^

tools/assetimg: tools/assetimg.c
	gcc -o $@ $<

