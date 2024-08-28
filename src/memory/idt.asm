; -------------------------------------
; idt.asm - Version 1.0
; Copyright (c) red031000 2024-08-25
; -------------------------------------

%include "macros.inc"

; Interrupt Descriptor Table (IDT) definition and functions

bits 64

; IDT gate entry structure
; 96:127 - reserved
; 64:95 - offset 32:63
; 48:63 - offset 16:31
; 47 - present
; 45:46 - descriptor privilege level
; 44 - 0
; 40:43 - gate type (0b1110 for 64-bit interrupt gate)
; 35:39 - reserved
; 32:34 - interrupt stack table - offset into TSS
; 16:31 - segment selector
; 0:15 - offset 0:15


section .data

idt_entry_start:
global idt_entry_div_error
idt_entry_div_error:
