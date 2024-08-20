; -------------------------------------
; strlen.asm - Version 1.0
; Copyright (c) red031000 2024-08-18
; -------------------------------------

; strlen implementation

bits 32

section .text

; TODO - use vectors, if MMX/SSE/SSE2/AVX is installed use vpcmpeqb and vpmovmskb
global strlen_32
strlen_32:
    ; String address should be in ebx already

    ; Initialise counter in eax
    mov eax, -1

    ; Loop through string
.loop:
    cmp byte[ebx + eax + 1], 0
    ; lea to not overwrite flags
    lea eax, [eax + 1]
    jne .loop

    ret
