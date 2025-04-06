; -------------------------------------
; page_alloc.asm - Version 1.0
; Copyright (c) red031000 2025-03-07
; -------------------------------------

%include "multiboot.inc"

; (Relatively) simple buddy allocator, for page allocation

bits 64

section .text

global buddy_init
buddy_init:
    call multiboot_get_memmap
    
    push rax
    call buddy_calculate_size
    pop rax
    ret

buddy_calculate_size:
    ; start by calculating the order required for the memory size in r9

