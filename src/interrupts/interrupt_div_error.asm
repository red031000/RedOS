; -------------------------------------
; interrupt_div_error.asm - Version 1.0
; Copyright (c) red031000 2024-08-25
; -------------------------------------

; Division error interrupt handler

%include "panic.asm"

bits 64

section .rodata

div_error_text:
    db "Interrupt: Division Error", 0x0

section .text

global interrupt_div_error_handler
interrupt_div_error_handler:
    ; this is classified as a "fault" by the intel manual, however, an actual division error
    ; (which is either a divide by zero, or too large to fit) in user space we want it to
    ; close the program, but in kernel space we gotta panic

    ; todo: userland

    ; we want rip to point to the instruction that cause the error
    push rbx
    lea rbx, [rsp + 0x10]
    mov qword[rip_replacement], rbx
    pop rbx

    ; we need to restore the flags
    push [rsp + 0x18]
    popfq

    push div_error_text

    call panic

    ; panic never returns but iretq is good practice anyway
    iretq
