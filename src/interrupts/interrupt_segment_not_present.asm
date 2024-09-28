; -------------------------------------
; interrupt_segment_not_present.asm - Version 1.0
; Copyright (c) red031000 2024-09-27
; -------------------------------------

; Segment not present interrupt handler

%include "panic.inc"

bits 64

section .rodata

segment_not_present_text:
    db "Interrupt: Segment Not Present", 0x0

section .text

global interrupt_segment_not_present_handler
interrupt_segment_not_present_handler:
    ; If the segment is not present, then CS, DS, ES, FS, or GS is set to a value not in the GDT, or
    ; LDT is not present when the LDTR instruction is used, or TSS is not present, or the gate
    ; descriptor is not present, either of these are a major error in how thigns are programmed
    ; so panic.
    push rbx
    lea rbx, [rsp + 0x10]
    mov qword[rip_replacement], rbx
    pop rbx

    ; we need to restore the flags
    push qword[rsp + 0x18]
    popfq

    push segment_not_present_text

    call panic

    ; panic never returns but iretq is good practice anyway
    iretq
