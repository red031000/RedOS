; -------------------------------------
; gdt.asm - Version 1.0
; Copyright (c) red031000 2024-08-23
; -------------------------------------

%include "macros.inc"

; Global Descriptor Table (GDT) definition and functions

; GDT will be loaded in long mode, bits don't matter for data though
bits 64

; format of GDT code entry:
; 63:56 - base address 31:24
; 55 - granularity
; 54 - default
; 53 - long mode
; 52 - available for kernel use
; 51:48 - limit 19:16
; 47 - present
; 46:45 - descriptor privilege level
; 44 - reserved (1)
; 43 - executable
; 42 - confirming
; 41 - readable
; 40 - accessed
; 39:16 - base address 23:0
; 15:0 - limit 15:0

; format of GDT data entry:
; 63:56 - base address 31:24
; 55 - granularity
; 54 - big
; 53 - reserved (0)
; 52 - available for kernel use
; 51:48 - limit 19:16
; 47 - present
; 46:45 - descriptor privilege level
; 44 - reserved (1)
; 43 - executable
; 42 - expansion direction
; 41 - writable
; 40 - accessed
; 39:16 - base address 23:0
; 15:0 - limit 15:0

section .data

gdt_entry_start:
global gdt_entry_null
gdt_entry_null:
    dq 0

global gdt_entry_kernel_code_32
gdt_entry_kernel_code_32:
    dw 0xFFFF ; limit 15:0
    dw 0 ; base 23:0
    db 0 ; base 31:24
    db 0x9A ; readable, executable, privilege level 0, present
    db 0xCF ; limit 19:16, 4kb granularity, default 32-bit operand size
    db 0 ; base 31:24

global gdt_entry_kernel_code_64
gdt_entry_kernel_code_64:
    dw 0xFFFF ; limit 15:0
    dw 0 ; base 23:0
    db 0 ; base 31:24
    db 0x9A ; readable, executable, privilege level 0, present
    db 0xAF ; limit 19:16, 4kb granularity, 64-bit operand size, long mode
    db 0 ; base 31:24

global gdt_entry_kernel_data
gdt_entry_kernel_data:
    dw 0xFFFF ; limit 15:0
    dw 0 ; base 23:0
    db 0 ; base 31:24
    db 0x92 ; writable, privilege level 0, present
    db 0xCF ; limit 19:16, 4kb granularity, big (4gb)
    db 0 ; base 31:24

global gdt_entry_user_code_32
gdt_entry_user_code_32:
    dw 0xFFFF ; limit 15:0
    dw 0 ; base 23:0
    db 0 ; base 31:24
    db 0xFA ; readable, executable, privilege level 3, present
    db 0xCF ; limit 19:16, 4kb granularity, default 32-bit operand size
    db 0 ; base 31:24

global gdt_entry_user_code_64
gdt_entry_user_code_64:
    dw 0xFFFF ; limit 15:0
    dw 0 ; base 23:0
    db 0 ; base 31:24
    db 0xFA ; readable, executable, privilege level 3, present
    db 0xAF ; limit 19:16, 4kb granularity, 64-bit operand size, long mode
    db 0 ; base 31:24

global gdt_entry_user_data
gdt_entry_user_data:
    dw 0xFFFF ; limit 15:0
    dw 0 ; base 23:0
    db 0 ; base 31:24
    db 0xF2 ; writable, privilege level 3, present
    db 0xCF ; limit 19:16, 4kb granularity, big (4gb)
    db 0 ; base 31:24

global gdt_entry_tss
gdt_entry_tss:
    dw 0x0067 ; limit 15:0
    dw 0 ; base 15:0, virtual address doesn't matter until we get to the upper dword
    db 0 ; base 23:16
    db 0x89 ; present, privilege level 0
    db 0 ; base 31:24
    db 0 ; limit 19:16
    dq 0 ; base 63:32, reserved - will need to change this when we enable paging
gdt_entry_end:

GDT_SIZE EQU gdt_entry_end - gdt_entry_start - 1

global gdtr
gdtr:
    dw GDT_SIZE
    dq VIRT64_TO_PHYS(gdt_entry_null) ; this must be 32 bit for 32 bit mode

section .bss

global tss
tss: ; we're gonna pretend tss is allocated in the gdt, but we'll allocate it when we init higher half
    resb 0x68 ; 0x68 bytes for TSS

bits 64 ; need this function in long mode

section .text

global gdt_higher_init
gdt_higher_init:
    ; we need to use the new address, since paging will be on
    mov rax, tss
    mov word[gdt_entry_tss + 2], ax
    shr rax, 16
    mov byte[gdt_entry_tss + 4], al
    shr rax, 8
    mov byte[gdt_entry_tss + 6], al
    shr rax, 8
    mov dword[gdt_entry_tss + 8], eax

    ; update the GDT address
    mov qword[gdtr + 2], gdt_entry_null
    lgdt [gdtr]

    jmp far [rel .address]
.address:
    dq .reload_registers
    dw 0x10

.reload_registers:
    mov ax, 0x18
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    ret

