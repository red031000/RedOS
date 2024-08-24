ifeq ($(TARGET),)
$(error TARGET is not set)
endif

rwildcard=$(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))
uniq = $(if $1,$(firstword $1) $(call uniq,$(filter-out $(firstword $1),$1)))

LIBSRCS = $(call rwildcard, lib, *.asm)

LIBINCLUDES = $(call rwildcard, lib, *.inc)
INCLUDES = $(call rwildcard, include, *.inc) $(LIBINCLUDES)

SOURCES = $(call rwildcard, src, *.asm) $(LIBSRCS)
OBJECTS = $(SOURCES:%.asm=%.o)

INCLUDEDIRS = $(call uniq, $(sort $(dir $(INCLUDES))))

# we use .boot.bss, it's a bss section, it's marked as such, you don't need to scream at us that it's not bss
NASMFLAGS = -felf64 -g -F dwarf $(foreach dir,$(INCLUDEDIRS),-I $(dir)) -w-zeroing

.PHONY: all clean

all: iso
	@:

iso: kernel
	mkdir -p isodir/boot/grub
	cp grub.cfg isodir/boot/grub
	cp kernel isodir/boot
	grub-mkrescue -o RedOS.iso isodir

kernel: $(OBJECTS)
	$(TARGET)-ld -o kernel -T linker.ld -Map kernel.map $(OBJECTS)

%.o: %.asm
	nasm $(NASMFLAGS) $< -o $@

clean:
	rm -f $(OBJECTS) kernel RedOS.iso
	rm -rf isodir
