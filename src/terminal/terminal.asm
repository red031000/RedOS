; -------------------------------------
; terminal.asm - Version 1.0
; Copyright (c) red031000 2024-08-18
; -------------------------------------

%include "strlen.inc"

bits 32

; Basic terminal using VGA text mode

VGA_WIDTH equ 80
VGA_HEIGHT equ 25
TERMINAL_BUFFER equ 0xB8000

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
    push ecx
    push eax

    ; terminal setup
    xor eax, eax
    mov word[terminal_pos], ax

    ; fill the screen with black spaces, also use some values to init
    mov eax, 0x0F200F20
    mov byte[terminal_color], ah ; higher 8 bits of ax

    mov edi, TERMINAL_BUFFER

    mov ecx, VGA_WIDTH * VGA_HEIGHT / 2
    rep stosd

    pop eax
    pop ecx
    ret

align 4
global terminal_print
terminal_print:
    call strlen_32
    call terminal_write

    ret

align 4
global terminal_write
terminal_write:
    ; eax is strlen
    ; ebx is string address
    ; we use negatives here as it allows only one increment
    neg eax
    jnc .end
    sub ebx, eax ; add positive eax, pointing at the end of the string, we work backwards

    push ecx
    push edx
    push edi

    movzx ecx, word[terminal_pos]
    movzx edx, cl ; cl is the column
    movzx edi, ch ; ch is the row
    imul edi, edi, VGA_WIDTH * 2
    sub edx, eax ; move the row to the end of the string, basically adding strlen to the current row
    lea edi, [TERMINAL_BUFFER + edi + edx * 2] ; this points to the end of the string
    mov dh, byte[terminal_color]

.loop:
    mov dl, [ebx + eax] ; load the current character, the addition is actually a subtraction cause negative
    cmp dl, 0xa ; check for newline
    je .newline

    mov [edi + 2 * eax], dx ; write the character to the correct position

    inc ecx ; increment the terminal column
    cmp cl, VGA_WIDTH
    jne .check

    ; wrap to the next line
    add ecx, 0x100 - VGA_WIDTH
    jmp .height_check

.newline:
    mov edx, ecx

    ; clear the entire row
    or ecx, 0xff
    inc ecx

    ; calculate the difference
    sub edx, ecx
    neg edx
    lea edi, [edi + edx * 2] ; add the difference to edi

.height_check:
    cmp ch, VGA_HEIGHT
    jne .check
    sub edi, 2 * VGA_WIDTH * VGA_HEIGHT
    xor ecx, ecx

.check:
    inc eax ; add 1 to neg strlen
    jnz .loop

    mov word[terminal_pos], cx

    pop edi
    pop edx
    pop ecx
.end:
    ret
