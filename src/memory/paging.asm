; -------------------------------------
; paging.asm - Version 1.0
; Copyright (c) red031000 2024-08-20
; -------------------------------------

%include "terminal.inc"

; Basic paging code

bits 32

section .bss

; align to a page, this should be put in the page immediately after the kernel

; page directory entry format:
; 31:12 - bits 31-12 of address
; 11:8 - avaiable for kernel use - bit 8 DO NOT FREE
; 7 - page size (we'll use 4kb pages)
; 6 - available for kernel use - mark as alloced
; 5 - accessed - set by CPU, cleared on free
; 4 - cache disabled
; 3 - write through
; 2 - user/superviser
; 1 - read/write
; 0 - present

align 4096
page_directory:
    resd 1024

; page table entry format:
; 31:12 - bits 31-12 of address
; 11:9 - available for kernel use - bit 9 - mark as alloced - bit 10 DO NOT FREE
; 8 - global, do not invalidate TLB on CR3 write, relies on PGE bit in CR4
; 7 - PAT, page attribute table, indicates memory caching type
; 6 - dirty, determines if page has been written to
; 5 - accessed, set by CPU, cleared on free
; 4 - cache disabled
; 3 - write through
; 2 - user/superviser
; 1 - read/write
; 0 - present

align 4096
first_kernel_page_table:
    resd 1024

section .rodata
paging_setup:
    db "Paging setup.", 0xA, 0

section .text

; Set up paging - 32 bit, we'll map to higher half when jumping to long mode
global paging_init32
paging_init32:
    ; setup page directory
    push edi
    push ecx
    push eax

    mov edi, page_directory
    mov ecx, 1024
    mov eax, 0x00000002 ; enable read/write

    rep stosd ; clear page directory

    ; setup page table - first table is static in memory, taking up a page itself, future tables will be allocated
    mov edi, first_kernel_page_table
    xor ecx, ecx

    ; identity map first 4mb - there's probably a way to do this with stosd or smth
.loop:
    mov eax, ecx
    imul eax, eax, 0x1000 

    ; TODO: text and rodata should not be writable
    or eax, 0x603 ; present, read/write, alloced, do not free
    mov dword[edi + ecx * 4], eax
    inc ecx
    cmp ecx, 1024
    jle .loop

    ; add table to directory
    or edi, 0x141 ; present, alloced, do not free
    mov dword[page_directory], edi ; store the table in the first entry of the directory

    ; set cr3 to page directory
    mov eax, page_directory
    mov cr3, eax

    ; enable paging
    mov eax, cr0
    or eax, 0x80000000 ; set paging bit
    mov cr0, eax

    mov ebx, paging_setup
    call terminal_print

    pop eax
    pop ecx
    pop edi
    ret