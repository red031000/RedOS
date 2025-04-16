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

multiboot_find_memmap:
    ; find the memmap in the multiboot 2 info
    ; returns:
    ; rsi - address of the mmap header
    ; rcx - size of the mmap header
    mov rsi, PHYS_TO_VIRT64(multiboot_info + 8)
.loop:
    mov rbx, qword[rsi]
    mov ecx, ebx
    shr rbx, 32
    cmp ebx, 6
    je .end
    test ebx, ebx
    jz .not_found

    ; sizes do not include padding, so to accurately get the address of the next tag, we need to pad to 8
    ; ourselves
    dec ecx
    or ecx, 7
    inc ecx

    add rsi, rcx
    jmp .loop

.not_found:
    ; no mem info, panic
    push memmap_not_found
    jmp panic

.end:
    ret

global multiboot_fix_memmap
multiboot_fix_memmap:
    ; WIP: do not use yet
    ; fixes the multiboot memmap to be page aligned
    call multiboot_find_memmap
    mov eax, 0xaaaaaaab
    imul rcx, rax
    shr rcx, 36
    lea rdi, [rsi + 16]

    xor r10, r10 ; check if 
    xor r9, r9 ; counter

.loop:
    mov ebx, dword[rdi + 16]
    mov r8, qword[rdi + 8]
    mov rdx, qword[rdi]
    cmp ebx, 1
    jne .occupied

    ; base address align to next 4096
    cmp r10, 1
    jne .noalign

    xor r10, r10

    mov rax, rdx
    neg rax
    and rax, 4095
    add rdx, rax

    ; save new base address
    mov qword[rdi], rdx
    
    ; subtract difference in size and save
    sub r8, rax
    mov qword[rdi + 8], r8

    test r9, r9
    jz .noalign

    ; adjust the size of the previous entry to go up to the new base address
    add qword[rdi - 16], rax
    jmp .noalign

.occupied:
    ; two stages - check if base addres is aligned to 4096, if not then adjust previous entry (if it's free)
    ; then check if length is 4096 aligned, if not then set r10 to signify an alignment in the next entry

    mov rax, rdx
    and rax, 4095
    test rax, rax
    jz .check_1_bypass

    ; TODO: check if this works
    ; round down
    mov rax, rdx
    neg rax
    mov r11, -0xFFF
    and rax, r11
    add rdx, rax


.check_1_bypass:

.noalign:
    add rdi, 24
    inc r9
    dec ecx
    jnz .loop

    ret

global multiboot_get_memmap
multiboot_get_memmap:
    ; gets the multiboot memmap info
    ; returns:
    ; rsi - address of mmap tag (mmap starts at rsi + 16)
    ; rax - amount of available memory total
    ; rcx - number of mmap entries
    ; r9 - amount of total memory
    call multiboot_find_memmap

    xor r9, r9
    mov eax, 0xaaaaaaab
    imul rcx, rax
    shr rcx, 36
    xor eax, eax
    mov edx, ecx
    lea rdi, [rsi + 16]

.loop:
    mov ebx, dword[rdi + 16]
    mov r8, qword[rdi + 8]
    add r9, r8
    cmp ebx, 1
    jne .not_available
    add rax, r8

.not_available:
    add rdi, 24
    dec edx
    jnz .loop
    ret

section .rodata

memmap_not_found:
    db "Memmap not present in multiboot header", 0x0
