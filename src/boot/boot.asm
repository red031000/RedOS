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
%include "features.inc"
%include "terminal.inc"
%include "panic.inc"

; We are in protected mode here
bits 32

section .boot.text exec

global _start_32
_start_32:
    ; Bootloader has passed us here, we're in protected mode, interrupts disabled, pagingdisabled 
    ; no stack, no nothing, we gotta set everything up, EAX contains multiboot magic, EBX has the
    ; multiboot info pointer, we should probably save this in multiboot.asm

    cli ; disable interrupts

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

    ; init terminal
    call terminal_init

    ; check for avx first
    call avx_check

    ; init CPU features
    call cpu_features_init

    ; TODO here: IDT

    mov rbx, redos ; os identifier
    call terminal_print ; print os identifier

    mov rbx, amogus ; amogus
    call terminal_print ; print hello_world string

    push test_panic

    ; test panic
    call panic

    ; infinite loop
    cli
.loop:
    hlt
    jmp .loop

section .rodata
hello_world:
;    db "Hello, world!", 0xA, 0

redos:
    db "====================================RedOS v1====================================", 0xA, 0x0

amogus:
    db "..................", 0xA
    db "......AMONGUS.....", 0xA
    db "....UNA.....M.....", 0xA
    db "....SGO.....N.....", 0xA
    db "....MOGUSAMON.....", 0xA
    db "......G.....U.....", 0xA
    db "......SA....MO....", 0xA
    db "When the OS is sus", 0xA, 0x0

test_panic:
    db "Test panic from boot.asm", 0x0