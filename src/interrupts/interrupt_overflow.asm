; -------------------------------------
; interrupt_overflow.asm - Version 1.0
; Copyright (c) red031000 2024-09-10
; -------------------------------------

; overflow interrupt handler

bits 64

section .text

global interrupt_overflow_handler
interrupt_overflow_handler:
    ; eventually we'll want to print registers with this exception
    ; for now just return

    iretq
