; -------------------------------------
; interrupt_general_protection.asm - Version 1.0
; Copyright (c) red031000 2024-10-31
; -------------------------------------

; General Protection interrupt handler

%include "panic.inc"

bits 64

section .rodata

general_protection_text:
    db "Interrupt: General Protection", 0x0

section .text

global interrupt_general_protection_handler
interrupt_general_protection_handler:
    ; General Protection Exceptions are very common, they mostly stem from a page not mapped
    ; it can also come from any other invalid thing that doesn't create a different exception
    ; it's very much a catch all. General protection at the moment means a programming error so
    ; panic.

    push rbx
    lea rbx, [rsp + 0x10]
    mov qword[rip_replacement], rbx
    pop rbx

    ; we need to restore the flags
    push qword[rsp + 0x18]
    popfq

    push general_protection_text

    call panic

    ; panic never returns but iretq is good practice anyway
    iretq
