
# vi:syntax=make noexpandtab

ASMS = src/main.asm

asmguy.com: $(ASMS)
	nasm -f bin -o $@ $^

