; -------------------------------------
; panic.asm - Version 1.0
; Copyright (c) red031000 2024-09-08
; -------------------------------------

%include "strutils.inc"
%include "terminal.inc"

; panic function

bits 64

section .rodata

align 4
global strings
strings:
    db "rax: "
    db "rbx: "
    db "rcx: "
    db "rdx: "
    db "rdi: "
    db "rsi: "
    db "rsp: "
    db "rbp: "
    db " r8: "
    db " r9: "
    db "r10: "
    db "r11: "
    db "r12: "
    db "r13: "
    db "r14: "
    db "r15: "
    db "flg: "
    db "rip: "

align 4
newline:
    db 0xA, 0x0

space:
    db " ", 0x0

panic_text:
    db "PANIC! ", 0

section .data

align 16
register:
    resq 2

section .text

align 4
global panic
panic:
    ; ok we panic
    ; push all registers we gotta use
    pushfq
    push r15
    push r14
    push r13
    push r12
    push r11
    push r10
    push r9
    push r8
    push rbp
    push rsp
    push rsi
    push rdi
    push rdx
    push rcx
    push rbx

    call convert_int_to_hex_string
    vmovdqa [register], xmm0

    ; TODO: newline if not newline

    ; print panic info first
    mov rbx, panic_text
    call terminal_print

    lea rbx, [rsp + 0x88]
    mov rbx, qword[rbx]
    call terminal_print

    mov rbx, newline
    call terminal_print

    xor r10, r10
    xor r9, r9
.loop:
    test r9, r9
    jz .skip_convert
    call convert_int_to_hex_string
    vmovdqa [register], xmm0

.skip_convert:
    mov rbx, strings
    add rbx, r9
    mov eax, 5
    call terminal_write

    mov rbx, register
    mov eax, 16
    call terminal_write

    mov rbx, space
    call terminal_print

    cmp r10, 1
    jne .no_newline

    mov rbx, newline
    call terminal_print

    xor r10, r10
    jmp .continue

.no_newline:
    inc r10

.continue:
    add r9, 5
    cmp r9, 90
    je .end

    pop rax
    jmp .loop

.end:
    cli
.loop2:
    hlt
    jmp .loop2
