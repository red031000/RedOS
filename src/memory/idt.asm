; -------------------------------------
; idt.asm - Version 1.0
; Copyright (c) red031000 2024-08-25
; -------------------------------------

%include "macros.inc"
%include "interrupt.inc"

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
    dw interrupt_div_error_handler
    dw 0x0010 ; kernel code 64
    db 0x00 ; no IST
    db 0x8E ; interrupt gate, present, privilege level 0
    dw 0 ; address 16:31
    dd 0xFFFFFFFF ; higher bits
    dd 0 ; reserved

global idt_entry_debug
idt_entry_debug:
    dw interrupt_debug_handler
    dw 0x0010 ; kernel code 64
    db 0x00 ; no IST
    db 0x8E ; interrupt gate, present, privilege level 0
    dw 0 ;address 16:31
    dd 0xFFFFFFFF ; higher bits
    dd 0 ; reserved

global idt_entry_non_maskable
idt_entry_non_maskable:
    dw interrupt_non_maskable_handler
    dw 0x0010 ; kernel code 64
    db 0x00 ; no IST
    db 0x8E ; interrupt gate, present, privilege level 0
    dw 0 ; address 16:31
    dd 0xFFFFFFFF ; higher bits
    dd 0 ; reserved

global idt_entry_breakpoint
idt_entry_breakpoint:
    dw interrupt_breakpoint_handler
    dw 0x0010 ; kernel code 64
    db 0x00 ; no IST
    db 0x8F ; trap gate, present, privilege level 0
    dw 0 ; address 16:31
    dd 0xFFFFFFFF ; higher bits
    dd 0 ; reserved

section .text

global setup_idt
setup_idt:
    mov rax, interrupt_div_error_handler
    shr rax, 16
    mov word[idt_entry_div_error + 6], ax

    mov rax, interrupt_debug_handler
    shr rax, 16
    mov word[idt_entry_debug + 6], ax

    mov rax, interrupt_non_maskable_handler
    shr rax, 16
    mov word[idt_entry_non_maskable + 6], ax

    mov rax, interrupt_breakpoint_handler
    shr rax, 16
    mov word[idt_entry_breakpoint + 6], ax

    ret
