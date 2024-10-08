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
    dw 0 ; address 0:15
    dw 0x0010 ; kernel code 64
    db 0x00 ; no IST
    db 0x8E ; interrupt gate, present, privilege level 0
    dw 0 ; address 16:31
    dd 0xFFFFFFFF ; higher bits
    dd 0 ; reserved

global idt_entry_debug
idt_entry_debug:
    dw 0 ; address 0:15
    dw 0x0010 ; kernel code 64
    db 0x00 ; no IST
    db 0x8E ; interrupt gate, present, privilege level 0
    dw 0 ;address 16:31
    dd 0xFFFFFFFF ; higher bits
    dd 0 ; reserved

global idt_entry_non_maskable
idt_entry_non_maskable:
    dw 0 ; address 0:15
    dw 0x0010 ; kernel code 64
    db 0x00 ; no IST
    db 0x8E ; interrupt gate, present, privilege level 0
    dw 0 ; address 16:31
    dd 0xFFFFFFFF ; higher bits
    dd 0 ; reserved

global idt_entry_breakpoint
idt_entry_breakpoint:
    dw 0 ; address 0:15
    dw 0x0010 ; kernel code 64
    db 0x00 ; no IST
    db 0x8F ; trap gate, present, privilege level 0
    dw 0 ; address 16:31
    dd 0xFFFFFFFF ; higher bits
    dd 0 ; reserved

global idt_entry_overflow
idt_entry_overflow:
    dw 0 ; address 0:15
    dw 0x0010 ; kernel code 64
    db 0x00 ; no IST
    db 0x8F ; trap gate, present, privilege level 0
    dw 0 ; address 16:31
    dd 0xFFFFFFFF ; higher bits
    dd 0 ; reserved

global idt_entry_bound_range
idt_entry_bound_range:
    dw 0 ; address 0:15
    dw 0x0010 ; kernel code 64
    db 0x00 ; no IST
    db 0x8E ; interrupt gate, present, privilege level 0
    dw 0 ; address 16:31
    dd 0xFFFFFFFF ; higher bits
    dd 0 ; reserved

global idt_entry_invalid_opcode
idt_entry_invalid_opcode:
    dw 0 ; address 0:15
    dw 0x0010 ; kernel code 64
    db 0x00 ; no IST
    db 0x8E ; interrupt gate, present, privilege level 0
    dw 0 ; address 16:31
    dd 0xFFFFFFFF ; higher bits
    dd 0 ; reserved

global idt_entry_device_not_available
idt_entry_device_not_available:
    dw 0 ; address 0:15
    dw 0x0010 ; kernel code 64
    db 0x00 ; no IST
    db 0x8E ; interrupt gate, present, privilege level 0
    dw 0 ; address 16:31
    dd 0xFFFFFFFF ; higher bits
    dd 0 ; reserved

global idt_entry_double_fault
idt_entry_double_fault:
    dw 0 ; address 0:15
    dw 0x0010 ; kernel code 64
    db 0x00 ; no IST
    db 0x8E ; interrupt gate, present, privilege level 0
    dw 0 ; address 16:31
    dd 0xFFFFFFFF ; higher bits
    dd 0 ; reserved

global idt_entry_coprocessor_segment_overrun
idt_entry_coprocessor_segment_overrun:
    dw 0 ; address 0:15
    dw 0x0010 ; kernel code 64
    db 0x00 ; no IST
    db 0x8E ; interrupt gate, present, privilege level 0
    dw 0 ; address 16:31
    dd 0xFFFFFFFF ; higher bits
    dd 0 ; reserved

global idt_entry_invalid_tss
idt_entry_invalid_tss:
    dw 0 ; address 0:15
    dw 0x0010 ; kernel code 64
    db 0x00 ; no IST
    db 0x8E ; interrupt gate, present, privilege level 0
    dw 0 ; address 16:31
    dd 0xFFFFFFFF ; higher bits
    dd 0 ; reserved

global idt_entry_segment_not_present
idt_entry_segment_not_present:
    dw 0 ; address 0:15
    dw 0x0010 ; kernel code 64
    db 0x00 ; no IST
    db 0x8E ; interrupt gate, present, privilege level 0
    dw 0 ; address 16:31
    dd 0xFFFFFFFF ; higher bits
    dd 0 ; reserved

section .text

global setup_idt
setup_idt:
    mov rax, interrupt_div_error_handler
    mov word[idt_entry_div_error], ax
    shr rax, 16
    mov word[idt_entry_div_error + 6], ax

    mov rax, interrupt_debug_handler
    mov word[idt_entry_debug], ax
    shr rax, 16
    mov word[idt_entry_debug + 6], ax

    mov rax, interrupt_non_maskable_handler
    mov word[idt_entry_non_maskable], ax
    shr rax, 16
    mov word[idt_entry_non_maskable + 6], ax

    mov rax, interrupt_breakpoint_handler
    mov word[idt_entry_breakpoint], ax
    shr rax, 16
    mov word[idt_entry_breakpoint + 6], ax

    mov rax, interrupt_overflow_handler
    mov word[idt_entry_overflow], ax
    shr rax, 16
    mov word[idt_entry_overflow + 6], ax

    mov rax, interrupt_bound_range_handler
    mov word[idt_entry_bound_range], ax
    shr rax, 16
    mov word[idt_entry_bound_range + 6], ax

    mov rax, interrupt_invalid_opcode_handler
    mov word[idt_entry_invalid_opcode], ax
    shr rax, 16
    mov word[idt_entry_invalid_opcode + 6], ax

    mov rax, interrupt_device_not_available_handler
    mov word[idt_entry_device_not_available], ax
    shr rax, 16
    mov word[idt_entry_device_not_available + 6], ax

    mov rax, interrupt_double_fault_handler
    mov word[idt_entry_double_fault], ax
    shr rax, 16
    mov word[idt_entry_double_fault + 6], ax

    mov rax, interrupt_coprocessor_segment_overrun_handler
    mov word[idt_entry_coprocessor_segment_overrun], ax
    shr rax, 16
    mov word[idt_entry_coprocessor_segment_overrun + 6], ax

    mov rax, interrupt_invalid_tss_handler
    mov word[idt_entry_invalid_tss], ax
    shr rax, 16
    mov word[idt_entry_invalid_tss + 6], ax

    mov rax, interrupt_segment_not_present_handler
    mov word[idt_entry_segment_not_present], ax
    shr rax, 16
    mov word[idt_entry_segment_not_present + 6], ax

    ret
