; -------------------------------------
; stack.asm - Version 1.0
; Copyright (c) red031000 2024-08-17
; -------------------------------------

; Stack definition and functions

; We are in protected mode here
bits 32

global stack_bottom
global stack_top
section .bss
align 16
stack_bottom:
    resb 0x4000
stack_top:
stack: