; -------------------------------------
; multiboot.asm - Version 1.1
; Copyright (c) red031000 2024-08-25
; -------------------------------------

%include "macros.inc"
%include "panic.inc"

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
align 8

MULTIBOOT_HEADER_LENGTH equ multiboot_end - multiboot_start

MULTIBOOT_CHECKSUM equ -(MULTIBOOT_MAGIC + MULTIBOOT_ARCHITECTURE + MULTIBOOT_HEADER_LENGTH)

multiboot_start:
dd MULTIBOOT_MAGIC
dd MULTIBOOT_ARCHITECTURE
dd MULTIBOOT_HEADER_LENGTH
dd MULTIBOOT_CHECKSUM
multiboot_end:

; request mmap tag
dw 1
dw 0
dd 12
dd 6

; padding to align tags
dd 0

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
    mov edi, multiboot_info
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

section .text

bits 64

global multiboot_get_memmap
multiboot_get_memmap:
    ; gets the multiboot memmap info
    ; returns:
    ; rsi - address of mmap tag (mmap starts at rsi + 16)
    ; rax - amount of available memory total
    ; rcx - number of mmap entries
    mov rsi, PHYS_TO_VIRT64(multiboot_info + 8)
_loop:
    mov ebx, dword[rsi]
    mov ecx, dword[rsi + 4]
    cmp ebx, 6
    je _found
    cmp ebx, 0
    je _not_found

    ; sizes do not include padding, so to accurately get the address of the next tag, we need to pad to 8
    ; ourselves
    bsf edx, ecx
    cmp edx, 3
    jg _no_pad
    
    ; there's probably a better way to do this
    shr ecx, 3
    shl ecx, 3
    add ecx, 8

_no_pad:
    add rsi, rcx
    jmp _loop

_found:
    mov eax, ecx
    xor edx, edx
    mov ecx, 24
    div ecx
    mov ecx, eax
    mov edx, eax
    xor eax, eax
    lea rdi, [rsi + 16]

_loop2:
    mov ebx, dword[rdi + 16]
    cmp ebx, 1
    jne _not_available
    mov r8, qword[rdi + 8]
    add rax, r8

_not_available:
    add rdi, 24
    dec edx
    jnz _loop2
    ret

_not_found:
    ; no mem info, panic
    push memmap_not_found
    call panic

section .rodata

memmap_not_found:
    db "Memmap not present in multiboot header", 0x0
