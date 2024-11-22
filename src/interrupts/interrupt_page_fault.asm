; -------------------------------------
; interrupt_page_fault.asm - Version 1.0
; Copyright (c) red031000 2024-11-22
; -------------------------------------

; Page Fault interrupt handler

%include "panic.inc"

bits 64

section .rodata

page_fault_text:
    db "Interrupt: Page Fault", 0x0

section .text

global interrupt_page_fault_handler
interrupt_page_fault_handler:
    ; Page Fault exceptions usually means the page is not mapped properly, and something tried to access it
    ; Depending on the type of fault and what caused it, ideally we can recover from it, however
    ; a proper paging setup (including Buddy/SLUB) is needed to allocate the pages first
    ; and decoding of the error code is needed to be able to determine what action to take
    ; for now if this occurs, panic

    push rbx
    lea rbx, [rsp + 0x10]
    mov qword[rip_replacement], rbx
    pop rbx

    ; we need to restore the flags
    push qword[rsp + 0x18]
    popfq

    push page_fault_text

    call panic

    ; panic never returns but iretq is good practice anyway
    iretq
