; -------------------------------------
; interrupt_stack_fault.asm - Version 1.0
; Copyright (c) red031000 2024-10-31
; -------------------------------------

; Stack fault interrupt handler

%include "panic.inc"

bits 64

section .rodata

stack_fault_text:
    db "Interrupt: Stack Fault", 0x0

section .text

global interrupt_stack_fault_handler
interrupt_stack_fault_handler:
    ; Stack faults are caused by three things, the first is a stack segment not present, this should never happen unless
    ; SS is changed, and the segment isn't in memory, second, the stack pointer is outside addressable virtual memory, or
    ; third, a stack overflow occurs, where rsp <= rbp (presumably, can't find much info on this)
    ; in theory this is entirely recoverable, however, realloc should be implemented for this, or the SS is loaded and SP
    ; or BP is set properly, for now panic.

    ; TODO: implement realloc to recover
    push rbx
    lea rbx, [rsp + 0x10]
    mov qword[rip_replacement], rbx
    pop rbx

    ; we need to restore the flags
    push qword[rsp + 0x18]
    popfq

    push stack_fault_text

    call panic

    ; panic never returns but iretq is good practice anyway
    iretq
