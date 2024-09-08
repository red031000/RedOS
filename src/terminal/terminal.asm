; -------------------------------------
; terminal.asm - Version 1.0
; Copyright (c) red031000 2024-08-18
; -------------------------------------

%include "strlen.inc"
%include "macros.inc"

bits 64

; Basic terminal using VGA text mode

VGA_WIDTH equ 80
VGA_HEIGHT equ 25
TERMINAL_BUFFER equ PHYS_TO_VIRT64(0xB8000)

section .bss
align 4

terminal_pos: ; row in high byte, column in low byte
    resw 1
terminal_color:
    resb 1

section .text

align 4
global terminal_init
terminal_init:
    ; terminal setup
    xor rax, rax
    mov word[terminal_pos], ax

    ; fill the screen with black spaces, also use some values to init
    mov rax, 0x0F200F200F200F20
    mov byte[terminal_color], ah ; higher 8 bits of ax

    mov rdi, TERMINAL_BUFFER

    mov ecx, VGA_WIDTH * VGA_HEIGHT / 4
    rep stosq

    ret

align 4
global terminal_print
terminal_print:
    call strlen
    call terminal_write

    ret

align 4
global terminal_write
terminal_write:
    ; rax is strlen
    ; rbx is string address
    ; we use negatives here as it allows only one increment
    neg rax
    jnc .end
    sub rbx, rax ; add positive rax, pointing at the end of the string, we work backwards
    xor rsi, rsi ; offset

    movzx rcx, word[terminal_pos]
    movzx rdx, cl ; cl is the column
    movzx edi, ch ; ch is the row
    imul rdi, rdi, VGA_WIDTH * 2
    sub rdx, rax ; move the row to the end of the string, basically adding strlen to the current row
    lea rdi, [TERMINAL_BUFFER + rdi + rdx * 2] ; this points to the end of the string
    mov dh, byte[terminal_color]

.loop:
    mov dl, byte[rbx + rax] ; load the current character, the addition is actually a subtraction cause negative
    cmp dl, 0xa ; check for newline
    je .newline

    lea r8, [rdi + 2 * rsi]
    mov word[2 * rax + r8], dx ; write the character to the correct position

    inc rcx ; increment the terminal column
    cmp cl, VGA_WIDTH
    jne .check

    cmp byte[rbx + rax + 1], 0xa
    je .check ; if the next character is a newline, don't wrap

    ; wrap to the next line
    add rcx, 0x100 - VGA_WIDTH
    jmp .height_check

.newline:
    movzx r8, cl
    sub rsi, r8
    dec rsi ; account for \n
    ; clear the entire row
    or rcx, 0xff
    inc rcx

    ; add to the row
    add rdi, VGA_WIDTH * 2

.height_check:
    cmp ch, VGA_HEIGHT
    jne .check
    sub rdi, 2 * VGA_WIDTH * VGA_HEIGHT
    xor rcx, rcx

.check:
    inc rax ; add 1 to neg strlen
    jnz .loop

    mov word[terminal_pos], cx

.end:
    ret
