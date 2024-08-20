ifeq ($(TARGET),)
$(error TARGET is not set)
endif

rwildcard=$(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))

LIBSRCS = $(call rwildcard, lib, *.asm)

LIBINCLUDES = $(call rwildcard, lib, *.inc)
INCLUDES = $(call rwildcard, include, *.inc) $(LIBINCLUDES)

SOURCES = $(call rwildcard, src, *.asm) $(LIBSRCS)
OBJECTS = $(SOURCES:%.asm=%.o)

NASMFLAGS = -felf64 $(foreach dir, $(dir $(INCLUDES)), -I $(dir))

.PHONY: all clean

all: iso
	@:

iso: kernel
	mkdir -p isodir/boot/grub
	cp grub.cfg isodir/boot/grub
	cp kernel isodir/boot
	grub-mkrescue -o RedOS.iso isodir

kernel: $(OBJECTS)
	$(TARGET)-ld -o kernel -T linker.ld $(OBJECTS)

%.o: %.asm
	nasm $(NASMFLAGS) $< -o $@

clean:
	rm -f $(OBJECTS) kernel RedOS.iso
	rm -rf isodir
