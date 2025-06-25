; -------------------------------------
; page_alloc.asm - Version 1.0
; Copyright (c) red031000 2025-03-07
; -------------------------------------

%include "multiboot.inc"

; (Relatively) simple buddy allocator, for page allocation

; struct buddy_tree {
;     u64 upper_pos_bound;
;     u64 size_for_order_offset;
;     u8 order;
;     u8 flags;
; }

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
    ; buddy_tree_order_for_memory
    ; start by calculating the order required for the memory size in rbx
    shr rax, 12
    bsr rbx, rax
    mov r12, rbx

    ; buddy_tree_sizeof
    ; then convert this to the size for the bitset, using a loop to properly account for order increases
    xor r9, r9
    mov r10, 1

.loop:
    mov r11, rbx
    imul r11, r10
    add r9, r11

    dec rbx
    add r10, r10

    cmp rbx, 0
    jne .loop

    ; align r9 to the nearest 8
    dec r9
    and r9, 7
    inc r9

    ; account for "memoization?" (not sure why this is necessary but doing it anyway)
    add r12, 2
    shl r12, 3
    add r9, r12

    ; add the size of the buddy struct, and the tree struct
    add r9, 50

    ; TODO: calculate the additional size required for the page table entries

    ret
