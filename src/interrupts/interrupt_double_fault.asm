; -------------------------------------
; interrupt_double_fault.asm - Version 1.0
; Copyright (c) red031000 2024-09-18
; -------------------------------------

; Double fault interrupt handler

%include "panic.inc"

bits 64

section .rodata

double_fault_text:
    db "Interrupt: Double Fault", 0x0

section .text

global interrupt_double_fault_handler
interrupt_double_fault_handler:
    ; A double fault usually means something went wrong in the interrupt handler
    ; since a triple fault reboots the CPU, we panic now and get the state while we still can

    ; todo userland
    push rbx
    lea rbx, [rsp + 0x10]
    mov qword[rip_replacement], rbx
    pop rbx

    ; we need to restore the flags
    push qword[rsp + 0x18]
    popfq

    push double_fault_text

    call panic

    ; panic never returns but iretq is good practice anyway
    iretq
