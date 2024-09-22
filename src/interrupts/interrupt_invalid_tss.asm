; -------------------------------------
; interrupt_invalid_tss.asm - Version 1.0
; Copyright (c) red031000 2024-09-22
; -------------------------------------

; Invalid TSS interrupt handler

%include "panic.inc"

bits 64

section .rodata

invalid_tss_text:
    db "Interrupt: Invalid TSS", 0x0

section .text

global interrupt_invalid_tss_handler
interrupt_invalid_tss_handler:
    ; invalid tss means something went wrong during task switching, since we don't task switch this should never happen
    ; if it does, panic, we'll need to implement it properly when we actually start task switching

    push rbx
    lea rbx, [rsp + 0x10]
    mov qword[rip_replacement], rbx
    pop rbx

    ; we need to restore the flags
    push qword[rsp + 0x18]
    popfq

    push invalid_tss_text

    call panic

    ; panic never returns but iretq is good practice anyway
    iretq
