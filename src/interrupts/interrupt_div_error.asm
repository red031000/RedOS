; -------------------------------------
; interrupt_div_error.asm - Version 1.0
; Copyright (c) red031000 2024-08-25
; -------------------------------------

; Division error interrupt handler

bits 64

section .text

global interrupt_div_error_handler
interrupt_div_error_handler:
    
    iretq