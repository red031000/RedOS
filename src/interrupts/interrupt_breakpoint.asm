; -------------------------------------
; interrupt_breakpoint.asm - Version 1.0
; Copyright (c) red031000 2024-09-10
; -------------------------------------

; breakpoint interrupt handler

bits 64

section .text

global interrupt_breakpoint_handler
interrupt_breakpoint_handler:
    ; eventually we'll want to print registers with this exception
    ; for now just return

    iretq
