; -------------------------------------
; interrupt_machine_check.asm - Version 1.0
; Copyright (c) red031000 2024-11-22
; -------------------------------------

; Machine check interrupt handler

%include "panic.inc"

bits 64

section .rodata

machine_check_text:
    db "Interrupt: Machine Check", 0x0

section .text

global interrupt_machine_check_handler
interrupt_machine_check_handler:
    ; Machine check exceptions are model specific and have to be explicitly enabled, so in theory they should not
    ; happen, if one does, panic.

    push rbx
    lea rbx, [rsp + 0x10]
    mov rbx, qword[rbx]
    mov qword[rip_replacement], rbx
    pop rbx

    ; we need to restore the flags
    push qword[rsp + 0x18]
    popfq

    push machine_check_text

    call panic

    ; panic never returns but iretq is good practice anyway
    iretq
