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

; struct buddy {
;     u64 memory_size;
;     u64 alignment;
;     union {
;         u8 *main;
;         u64 main_offset;
;     } arena;
;     u64 buddy_flags;
; }

bits 64

section .bss

align 4096
buddy_page_directory:
    resq 512

buddy_page_table:
    resq 1

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

    ; account for memoization (caching)
    add r12, 2
    shl r12, 3
    add r9, r12

    ; add the size of the buddy struct, and the tree struct
    add r9, 50

    ; TODO: check if this is correct
    ; static pages in the OS are 2MB large, however dynamic pages are 4KB
    ; this means we need a new page directory, defined above
    ; we also have 1 page table already assigned in the static area, account for this
    lea r10, [r9 - 1]
    shr r10, 12

    mov r11, r10

    xor r12, r12
    cmp r11, 511
    jl .no_directory

    ; at least 1 extra directory needed
    mov r12, 8
    sub r10, 511

    cmp r10, 512
    jl .no_directory

    ; loop to add directories
.loop2:
    add r12, 8
    sub r10, 512

    cmp r10, 512
    jge .loop2

.no_directory:
    ; this can handle up to 4tb fine, anything more needs adjustment, a new page for the directories, and an L3 entry
    shl r11, 3

    add r9, r12

    ; TODO: check, this might throw a PF, might need an extra page at the end if r9 & 0xFFF + r11 & 0xFFF > 4096
    add r9, r11

    ret
