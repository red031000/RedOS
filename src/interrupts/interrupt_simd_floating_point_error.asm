; -------------------------------------
; interrupt_simd_floating_point_error.asm - Version 1.0
; Copyright (c) red031000 2024-11-22
; -------------------------------------

; simd floating point error interrupt handler

%include "panic.inc"

bits 64

section .rodata

simd_floating_point_error_text:
    db "Interrupt: SIMD Floating-Point Error", 0x0

section .text

global interrupt_simd_floating_point_error_handler
interrupt_simd_floating_point_error_handler:
    ; simd floating point errors occur when an invalid operation or invalid operands are used. They can also
    ; occur if the result is not exact, or an overflow/underflow has occurred. This *may* be recoverable
    ; however, for now, panic.

    push rbx
    lea rbx, [rsp + 0x10]
    mov rbx, qword[rbx]
    mov qword[rip_replacement], rbx
    pop rbx

    ; we need to restore the flags
    push qword[rsp + 0x18]
    popfq

    push simd_floating_point_error_text

    call panic

    ; panic never returns but iretq is good practice anyway
    iretq
