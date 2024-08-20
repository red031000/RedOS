; -------------------------------------
; multiboot.asm - Version 1.0
; Copyright (c) red031000 2024-08-17
; -------------------------------------

; Multiboot 1 header and functions
; TODO: Upgrade to multiboot 2, use proper memory mapping for the kernel

; Multiboot 1 format (not including optional features):
; struct multiboot {
;     u32 magic,
;     u32 flags,
;     u32 checksum
; }

; We are in protected mode here
bits 32

; We want to align all boot modules to 4KB, as this allows direct paged address mapping
MULTIBOOT_ALIGN equ 1 << 0

; We want memory information/map if available to be passed
MULTIBOOT_MEMINFO equ 1 << 1

MULTIBOOT_FLAGS equ MULTIBOOT_ALIGN | MULTIBOOT_MEMINFO

; Multiboot v1 magic number is 0x1BADB002
MULTIBOOT_MAGIC equ 0x1BADB002

MULTIBOOT_CHECKSUM equ -(MULTIBOOT_MAGIC + MULTIBOOT_FLAGS)

section .multiboot
align 4
dd MULTIBOOT_MAGIC
dd MULTIBOOT_FLAGS
dd MULTIBOOT_CHECKSUM

; TODO: Implement multiboot memory handling functions
section .bss
align 4
multiboot_info:
    resb 116

section .text

bits 32

global multiboot_store_info
multiboot_store_info:
    ; Store multiboot info in multiboot_info
    mov edi, multiboot_info
    mov esi, ebx
    mov ecx, 116
    rep movsb

    ret


global multiboot_check_magic
multiboot_check_magic:
    ; Multiboot magic is 0x2BADB002 in eax
    cmp eax, 0x2BADB002
    jne .not_multiboot
    ret

.not_multiboot:
    ; infinite loop - TODO: panic
    cli
.loop:
    hlt
    jmp .loop
