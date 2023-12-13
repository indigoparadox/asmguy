
# vi:syntax=make noexpandtab

ASMS := src/main.asm src/assets.asm
ASSETS := s_maid01.bmp s_maid02.bmp t_rock.bmp
CFLAGS := -fsanitize=undefined -fsanitize=address -g -Wall --std=c89 -DDEBUG_BMP

all: asmguy.com

asmguy.com: $(ASMS)
	nasm -f bin -o $@ $<

tools/assetimg: tools/assetimg.c
	gcc $(CFLAGS) -o $@ $<

assets/%.asm: tools/assetimg
	tools/assetimg $(subst .asm,.bmp,$@) $(subst assets/,,$(basename $@)) > $@

src/assets.asm: $(addprefix assets/,$(subst .bmp,.asm,$(ASSETS)))
	cat $^ > $@

clean:
	rm -f tools/assetimg asmguy.com assets/*.asm

