; -------------------------------------
; boot.asm - Version 1.0
; Copyright (c) red031000 2024-08-17
; -------------------------------------

; Very basic boot code

%include "stack.inc"
%include "paging.inc"
%include "multiboot.inc"
%include "terminal.inc"

; We are in protected mode here
bits 32

section .text

global _start
_start:
    ; Bootloader has passed us here, we're in protected mode, interrupts disabled, paging disabled
    ; no stack, no nothing, we gotta set everything up, EAX contains multiboot magic, EBX has the
    ; multiboot info pointer, we should probably save this in multiboot.asm

    ; Before anything, set up the stack - eventually we'll want to make the stack dynamic, it's
    ; only 16kb for now
    mov esp, stack_top
    mov ebp, stack_bottom

    ; Check the multiboot magic and store the info, we'll need it
    call multiboot_check_magic
    call multiboot_store_info

    call terminal_init

    ; init temporary 32 bit paging
    call paging_init32

    ; TODO here: enable floating point instructions, ISEs, GDT, IDT

    mov ebx, hello_world ; load address of hello_world string
    call terminal_print ; print hello_world string

    ; infinite loop
    cli
.loop:
    hlt
    jmp .loop

section .rodata
hello_world:
    db "Hello, world!", 0xA, 0
