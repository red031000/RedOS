; -------------------------------------
; features.asm - Version 1.0
; Copyright (c) red031000 2024-08-20
; -------------------------------------

; CPU feature detection

; protective shield
bits 32

section .bss

align 4
cpu_features:
    resd 2 ; 1 for now, might need more

cpu_vendor_info:
    resd 4 ; 3 for vendor string, 1 for max eax

section .text

global cpu_features_init
cpu_features_init:
    ; Detect and init CPU features

    mov eax, 0
    cpuid

    ; why is the second part of the string in edx and not ecx? who decided this? weird
    mov [cpu_vendor_info], ebx
    mov [cpu_vendor_info + 4], edx
    mov [cpu_vendor_info + 8], ecx
    mov [cpu_vendor_info + 12], eax ; store the max eax val

    ; get feature flags
    mov eax, 1
    cpuid
    mov [cpu_features], edx
    mov [cpu_features + 4], ecx

    ; init x87 FPU with 0x37F as the control word, if we have no FPU, the kernel can't run
    mov eax, cr0
    and eax, 0xFFFFFFFB ; clear EM bit
    mov cr0, eax

    fninit

    ; don't really care about VME/DE/PSE, not very useful to us

    test edx, 0x10
    jz .no_tsc

    ; enable TSC
    mov eax, cr4
    and eax, 0xFFFFFFFB ; clear TSD bit
    mov cr4, eax

.no_tsc:
    ; MSRs may be useful to us, but we don't need them right now
    ; we'll enable PAE when we switch to long mode, as that requires remapping paging
    ; we'll probably want MCE too, but this requires interrupt handling
    ; don't need to do anything for CX8, APIC needs interrupt handling, and nothing needed for SEP
    ; MTRR maybe for long mode, don't want PGE, MCA maybe, but needs interrupts, nothing needed for CMOV
    ; PATs will be addressed in long mode, PSE-36 is unwanted, PSN nothing needed, CLFSH can be useful for allocators
    ; don't need DS, or ACPI
    ; next thing we need is MMX, we can assume this exists too, cause it's needed for long mode
    ; luckily this has been activated when we turned on the x87 FPU
    ; we *do* need to check and activate FXSR though, specifically OS support for it

    test edx, 0x1000000
    jz .no_fxsr

    ; enable FXSR OS support
    mov eax, cr4
    or eax, 0x200 ; set OSFXSR bit
    mov cr4, eax

.no_fxsr:
    

    ret