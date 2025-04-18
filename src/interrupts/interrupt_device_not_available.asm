; -------------------------------------
; interrupt_device_not_available.asm - Version 1.0
; Copyright (c) red031000 2024-09-17
; -------------------------------------

; Device not available interrupt handler

%include "panic.inc"

bits 64

section .rodata

device_not_available_text:
    db "Interrupt: Device Not Available", 0x0

section .text

global interrupt_device_not_available_handler
interrupt_device_not_available_handler:
    ; If device is not available that means that either x87 is not inited, wait/fwait is used without MP and TS, or SSE/MMX/x87
    ; instruction is used without TS and EM in CR0
    ; This should never happen, if it does something in setup broke, so panic
    ; alternatively they were turned off, ideally then we want to look and see what turned it off
    ; if EM is set, we should emulate the instruction instead

    ; todo userland
    push rbx
    lea rbx, [rsp + 0x10]
    mov rbx, qword[rbx]
    mov qword[rip_replacement], rbx
    pop rbx

    ; we need to restore the flags
    push qword[rsp + 0x18]
    popfq

    push device_not_available_text

    call panic

    ; panic never returns but iretq is good practice anyway
    iretq
