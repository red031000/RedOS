; -------------------------------------
; interrupt_non_maskable.asm - Version 1.0
; Copyright (c) red031000 2024-09-10
; -------------------------------------

; Non-maskable interrupt handler

bits 64

section .text

global interrupt_non_maskable_handler
interrupt_non_maskable_handler:
    ; NMIs are complicated, and require AIPC to handle properly, for now we panic
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
