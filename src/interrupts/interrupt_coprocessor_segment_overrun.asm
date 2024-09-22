; -------------------------------------
; interrupt_coprocessor_segment_overrun.asm - Version 1.0
; Copyright (c) red031000 2024-09-17
; -------------------------------------

; Coprocessor segmenet overrun interrupt handler

bits 64

section .text

global interrupt_coprocessor_segment_overrun_handler
interrupt_coprocessor_segment_overrun_handler:
    ; this handler is blank, coprocessor segment overruns can only happen in i386s, they should be handled by
    ; executing FNINIT, but since they're an i386 only interrupt, and don't occur on i486 or anything
    ; more modern (including any 64 bit systems), we don't handle it

    iretq
