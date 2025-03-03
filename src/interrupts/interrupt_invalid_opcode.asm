; -------------------------------------
; interrupt_invalid_opcode.asm - Version 1.0
; Copyright (c) red031000 2024-09-13
; -------------------------------------

; Invalid Opcode interrupt handler

%include "panic.inc"

bits 64

section .rodata

invalid_opcode_text:
    db "Interrupt: Invalid Opcode", 0x0

section .text

global interrupt_invalid_opcode_handler
interrupt_invalid_opcode_handler:
    ; Invalid opcode interrupt means we either did something the CPU doesn't support or wasn't activated yet
    ; could also be something that's not valid atm, either way we want to panic

    ; todo userland
    push rbx
    lea rbx, [rsp + 0x10]
    mov rbx, qword[rbx]
    mov qword[rip_replacement], rbx
    pop rbx

    ; we need to restore the flags
    push qword[rsp + 0x18]
    popfq

    push invalid_opcode_text

    call panic

    ; panic never returns but iretq is good practice anyway
    iretq
