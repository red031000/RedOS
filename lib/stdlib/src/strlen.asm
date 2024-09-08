; -------------------------------------
; strlen.asm - Version 1.0
; Copyright (c) red031000 2024-08-18
; -------------------------------------

; strlen implementation

bits 64

section .text

global strlen
strlen:
    xor eax, eax
.loop:
    vlddqu xmm0, [rbx + rax]
    ; this is some ax6 magic, thanks
    vpcmpistri xmm0, xmm0, 0x38
    lea rax, [rax + rcx]
    jnc .loop
    ret

global strlen_slow
strlen_slow:
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
