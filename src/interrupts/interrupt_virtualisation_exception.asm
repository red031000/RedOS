; -------------------------------------
; interrupt_virtulisation_exception.asm - Version 1.0
; Copyright (c) red031000 2024-11-22
; -------------------------------------

; Virtualisation exception interrupt handler

%include "panic.inc"

bits 64

section .rodata

virtualisation_exception_text:
    db "Interrupt: Virtualisation Exception", 0x0

section .text

global interrupt_virtualisation_exception_handler
interrupt_virtualisation_exception_handler:
    ; Virtualisation exceptions occur when an EPT violation in VMX (intel) occurs, AMD likely has an equivalent error
    ; in theory this is recoverable, however since VMX is not implemented yet, this should not happen
    ; so for now, panic.

    push rbx
    lea rbx, [rsp + 0x10]
    mov rbx, qword[rbx]
    mov qword[rip_replacement], rbx
    pop rbx

    ; we need to restore the flags
    push qword[rsp + 0x18]
    popfq

    push virtualisation_exception_text

    call panic

    ; panic never returns but iretq is good practice anyway
    iretq
