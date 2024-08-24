; -------------------------------------
; strlen.asm - Version 1.0
; Copyright (c) red031000 2024-08-18
; -------------------------------------

; strlen implementation

bits 64

section .text

; TODO - use vectors, if MMX/SSE/SSE2/AVX is installed use vpcmpeqb and vpmovmskb
global strlen
strlen:
    ; String address should be in rbx already

    ; Initialise counter in rax
    mov rax, -1

    ; Loop through string
.loop:
    cmp byte[rbx + rax + 1], 0
    ; lea to not overwrite flags
    lea rax, [rax + 1]
    jne .loop

    ret
