; -------------------------------------
; multiboot.asm - Version 1.1
; Copyright (c) red031000 2024-08-25
; -------------------------------------

%include "macros.inc"

; Multiboot 2 header and functions
; TODO: Use proper memory mapping for the kernel

; Multiboot 2 format:
; struct multiboot {
;     u32 magic,
;     u32 architecture,
;     u32 header_length,
;     u32 checksum
;     struct tags[] tags;
; }

; tags are of variable length

; We are in protected mode here
bits 32


; Multiboot v2 magic number is 0xE85250D6
MULTIBOOT_MAGIC equ 0xE85250D6

MULTIBOOT_ARCHITECTURE equ 0

section .multiboot
align 4

MULTIBOOT_HEADER_LENGTH equ multiboot_end - multiboot_start

MULTIBOOT_CHECKSUM equ -(MULTIBOOT_MAGIC + MULTIBOOT_ARCHITECTURE + MULTIBOOT_HEADER_LENGTH)

multiboot_start:
dd MULTIBOOT_MAGIC
dd MULTIBOOT_ARCHITECTURE
dd MULTIBOOT_HEADER_LENGTH
dd MULTIBOOT_CHECKSUM
multiboot_end:

; we want things page aligned, tag 6 is the page alignment tag
dw 6
dw 0
dd 8

; end tags, 0 is the end tag
dw 0
dw 0
dd 8

; TODO: Implement multiboot memory handling functions
section .boot.bss nobits
align 4
multiboot_info:
    resb 4096 ; doubt it'll be more

section .boot.text exec

bits 32

global multiboot_store_info
multiboot_store_info:
    ; Store multiboot info in multiboot_info
    mov edi, VIRT64_TO_PHYS(multiboot_info)
    mov esi, ebx
    mov ecx, dword[ebx] ; total size is the first entry in the multiboot info
    rep movsb

    ret

global multiboot_check_magic
multiboot_check_magic:
    ; Multiboot2 magic is 0x36D76289 in eax
    cmp eax, 0x36D76289
    jne .not_multiboot
    ret

.not_multiboot:
    ; infinite loop - TODO: panic
    cli
.loop:
    hlt
    jmp .loop
