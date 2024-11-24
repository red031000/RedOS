; -------------------------------------
; interrupt_control_protection.asm - Version 1.0
; Copyright (c) red031000 2024-11-24
; -------------------------------------

; Control protection interrupt handler

%include "panic.inc"

bits 64

section .rodata

control_protection_text:
    db "Interrupt: Control Protection", 0x0

section .text

global interrupt_control_protection_handler
interrupt_control_protection_handler:
    ; Control protection exceptions happen when "a control flow transfer attempt violate(s) the
    ; control flow enforcement technology constraints". They need to be explicitly enabled, which we haven't done
    ; so they should not occur at the moment, if they do, panic

    ; todo: userland

    ; we want rip to point to the instruction that cause the error
    push rbx
    lea rbx, [rsp + 0x10]
    mov qword[rip_replacement], rbx
    pop rbx

    ; we need to restore the flags
    push qword[rsp + 0x18]
    popfq

    push control_protection_text

    call panic

    ; panic never returns but iretq is good practice anyway
    iretq
