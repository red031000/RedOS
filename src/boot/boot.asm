; -------------------------------------
; boot.asm - Version 1.0
; Copyright (c) red031000 2024-08-17
; -------------------------------------

; Very basic boot code

%include "macros.inc"
%include "stack.inc"
%include "paging.inc"
%include "gdt.inc"
%include "multiboot.inc"
%include "terminal.inc"

; We are in protected mode here
bits 32

section .boot.text

global _start_32
_start_32:
    ; Bootloader has passed us here, we're in protected mode, interrupts disabled, paging disabled
    ; no stack, no nothing, we gotta set everything up, EAX contains multiboot magic, EBX has the
    ; multiboot info pointer, we should probably save this in multiboot.asm

    ; Before anything, set up the stack - eventually we'll want to make the stack dynamic, it's
    ; only 16kb for now
    mov esp, VIRT64_TO_PHYS(stack_top)
    mov ebp, VIRT64_TO_PHYS(stack_bottom)

    ; Check the multiboot magic and store the info, we'll need it
    call multiboot_check_magic
    call multiboot_store_info

    ; init long mode paging
    call paging_init_long

    ; enable paging
    mov eax, cr0
    or eax, 0x80000000 ; set PG bit
    mov cr0, eax

    ; now we're in long mode, but still compatibility
    ; we gotta update the gdt
    lgdt [VIRT64_TO_PHYS(gdtr)]

    ; time to go to 64 bit mode
    jmp 0x10:VIRT64_TO_PHYS(_setup_higher_half)

bits 64

section .text

global _setup_higher_half
_setup_higher_half:
    ; 64 bit mode here, we need to reload segment registers
    mov ax, 0x18
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; jump thinks that we are in higher half already, we're not so we have to work around this
    mov rax, VIRT64_TO_PHYS(paging_higher_setup)
    jmp rax

global _start_64
_start_64:
    ; reload stack
    mov rsp, stack_top
    mov rbp, stack_bottom

    ; we need to reload the GDT and segment registers *again*
    call gdt_higher_init

    ; unmap the lower half
    call unmap_lower_half

    ; TODO here: enable floating point instructions, ISEs, IDT

    call terminal_init

    mov rbx, hello_world ; load address of hello_world string
    call terminal_print ; print hello_world string

    ; infinite loop
    cli
.loop:
    hlt
    jmp .loop

section .rodata
hello_world:
    db "Hello, world!", 0xA, 0
