; -------------------------------------
; interrupt_bound_range.asm - Version 1.0
; Copyright (c) red031000 2024-08-25
; -------------------------------------

; Bound range interrupt handler

%include "panic.inc"

bits 64

section .rodata

bound_range_text:
    db "Interrupt: Bound Range Exceeded", 0x0

section .text

global interrupt_bound_range_handler
interrupt_bound_range_handler:
    ; bound range exception occurs when the "bound" instruction indicates the array is out of range
    ; this should be handled, probably be re-assigning the array etc, however we cannot do that yet
    ; so we panic in kernel mode, should close the program in user mode

    ; todo: userland

    ; we want rip to point to the instruction that cause the error
    push rbx
    lea rbx, [rsp + 0x10]
    mov rbx, qword[rbx]
    mov qword[rip_replacement], rbx
    pop rbx

    ; we need to restore the flags
    push qword[rsp + 0x18]
    popfq

    push bound_range_text

    call panic

    ; panic never returns but iretq is good practice anyway
    iretq
