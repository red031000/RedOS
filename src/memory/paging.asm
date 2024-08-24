; -------------------------------------
; paging.asm - Version 1.0
; Copyright (c) red031000 2024-08-20
; -------------------------------------

%include "terminal.inc"
%include "macros.inc"
%include "boot.inc"

; Basic paging code

bits 64

section .bss

; align to a page, this should be put in the page immediately after the kernel


; page map level 4 entry format:
; 63 - execute disable
; 62:52 - available for kernel use
; 52:12 - address
; 11 - HLAT restart, normally available for kernel use
; 10:8 - available for kernel use - bit 8 DO NOT FREE
; 7 - reserved
; 6 - available for kernel use - mark as alloced
; 5 - accessed - set by CPU, cleared on free
; 4 - cache disabled
; 3 - write through
; 2 - user/superviser
; 1 - read/write
; 0 - present
align 4096
page_map_level_4:
    resq 512


; page directory pointer table entry format:
; 63 - execute disable
; 62:52 - available for kernel use
; 52:12 - address
; 11 - HLAT restart, normally available for kernel use
; 10:8 - available for kernel use - bit 8 DO NOT FREE
; 7 - page size - must be 0
; 6 - available for kernel use - mark as alloced
; 5 - accessed - set by CPU, cleared on free
; 4 - cache disabled
; 3 - write through
; 2 - user/superviser
; 1 - read/write
; 0 - present
align 4096
first_page_directory_pointer_table:
    resq 512

; page directory entry format:
; 63 - execute disable
; 62:52 - available for kernel use
; 52:12 - address
; 11 - HLAT restart, normally available for kernel use
; 10:8 - avaiable for kernel use - bit 8 DO NOT FREE
; 7 - page size (we'll use 4kb pages), must be 0
; 6 - available for kernel use - mark as alloced
; 5 - accessed - set by CPU, cleared on free
; 4 - cache disabled
; 3 - write through
; 2 - user/superviser
; 1 - read/write
; 0 - present

align 4096
first_page_directory:
    resq 512

; page table entry format:
; 63 - execute disable
; 62:59 - protection key, requres CR4.PKE or CR4.PKS, normally available for kernel use
; 58:52 - available for kernel use
; 52:12 - address
; 11 - HLAT restart, normally available for kernel use
; 10:9 - available for kernel use - bit 9 - mark as alloced - bit 10 DO NOT FREE
; 8 - global, do not invalidate TLB on CR3 write, relies on PGE bit in CR4
; 7 - PAT, page attribute table, indicates memory caching type
; 6 - dirty, determines if page has been written to
; 5 - accessed, set by CPU, cleared on free
; 4 - cache disabled
; 3 - write through
; 2 - user/superviser
; 1 - read/write
; 0 - present

align 4096
first_kernel_page_table:
    resq 512

; IDIOT - a page table is 2MB now, because of PGE, so we need a second one
align 4096
second_kernel_page_table:
    resq 512

bits 32

section .boot.text

global paging_init_long
paging_init_long:
    ; set up paging for long mode
    ; first enable PGE
    mov eax, cr4
    or eax, 0x20 ; set PGE bit
    mov cr4, eax

    ; set up page map level 4
    mov dword[VIRT64_TO_PHYS(page_map_level_4)], 0x147 ; alloced, do not free, present, read/write, user/superviser

    ; set up page directory pointer table
    mov dword[VIRT64_TO_PHYS(first_page_directory_pointer_table)], 0x147 ; alloced, do not free, present, read/write, user/superviser

    ; add directory pointer table to page map level 4
    or dword[VIRT64_TO_PHYS(page_map_level_4)], VIRT64_TO_PHYS(first_page_directory_pointer_table) ; we can do this as it's all under 4gb

    ; setup page directory
    mov dword[VIRT64_TO_PHYS(first_page_directory)], 0x143 ; alloced, do not free, present, read/write
    mov dword[VIRT64_TO_PHYS(first_page_directory) + 8], 0x143 ; alloced, do not free, present, read/write

    ; add directory to directory pointer table
    or dword[VIRT64_TO_PHYS(first_page_directory_pointer_table)], VIRT64_TO_PHYS(first_page_directory) ; same as above

    ; setup page table - first table is static, rest will be allocated
    mov edi, VIRT64_TO_PHYS(first_kernel_page_table)
    xor ecx, ecx

.loop:
    mov eax, ecx
    shl eax, 12

    ; TODO: text and rodata should not be writable
    or eax, 0x607 ; present, read/write, alloced, do not free
    mov dword[edi + ecx * 8], eax ; add page to table
    inc ecx
    cmp ecx, 1024
    jle .loop

    ; add table to directory
    or dword[VIRT64_TO_PHYS(first_page_directory)], VIRT64_TO_PHYS(first_kernel_page_table)
    or dword[VIRT64_TO_PHYS(first_page_directory) + 8], VIRT64_TO_PHYS(second_kernel_page_table)

    ; set LME bit in EFER
    mov ecx, 0xC0000080
    rdmsr
    or eax, (1 << 8)
    wrmsr

    ; set cr3 to page map level 4
    mov eax, VIRT64_TO_PHYS(page_map_level_4)
    mov cr3, eax

    ret

bits 64

section .text

global paging_higher_setup
paging_higher_setup:
    ; we need to do what we weren't able to in protected mode first - set everything to R/W
    mov rcx, 510
    mov rdi, VIRT64_TO_PHYS(first_page_directory) + 16
    mov rax, 0x2
    rep stosq

    mov rcx, 511
    mov rdi, VIRT64_TO_PHYS(first_page_directory_pointer_table) + 8
    mov rax, 0x2
    rep stosq

    mov rcx, 511
    mov rdi, VIRT64_TO_PHYS(page_map_level_4) + 8
    mov rax, 0x2
    rep stosq

    ; we need to map the kernel to the higher half
    mov rcx, VIRT64_TO_PHYS(page_map_level_4)
    mov rax, qword[rcx] 
    mov qword[rcx + 4088], rax ; copy the mapping to the higher half

    mov rdx, VIRT64_TO_PHYS(first_page_directory_pointer_table)
    mov rax, qword[rdx]
    mov qword[rdx + 4080], rax ; *should* be the last 2gb

    ; set cr3 to page map level 4
    mov cr3, rcx

    ; everything is higher half now
    ; jump already thinks we're in higher half, we're not yet
    mov rax, _start_64
    jmp rax ; this is pretty stinky but we need to jump to higher half memory

global unmap_lower_half
unmap_lower_half:
    ; unmap the old mapping

    mov rcx, page_map_level_4
    mov qword[rcx], 0x2
    mov qword[first_page_directory_pointer_table], 0x2

    mov rcx, VIRT64_TO_PHYS(page_map_level_4)
    mov cr3, rcx
    ret