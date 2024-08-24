; -------------------------------------
; features.asm - Version 1.0
; Copyright (c) red031000 2024-08-20
; -------------------------------------

; CPU feature detection

; protective shield
bits 32

section .boot.bss nobits

align 4
cpu_features:
    resd 2 ; 2 for now, might need more

cpu_vendor_info:
    resd 4 ; 3 for vendor string, 1 for max eax

msr_feature_control_set:
    resb 1 ; keep track of whether we've set this

section .boot.text exec

global init_cpu_for_long_mode
init_cpu_for_long_mode:
    ; we can assume everything for long mode exists, the OS doesn't work without it
    ; init x87 FPU with 0x37F as the control word
    mov eax, cr0
    and eax, 0xFFFFFFFB ; clear EM 
    or eax, 0x00000002 ; set MP
    mov cr0, eax
    fninit

    ; enable SSE/SSE2 by enabling FXSR support
    mov eax, cr4
    or eax, 0x600 ; set OSFXSR and OSXMMEXCEPT bits
    mov cr4, eax

    ret

global cpu_features_init
cpu_features_init:
    ; Detect and init CPU features

    mov eax, 0
    cpuid

    ; why is the second part of the string in edx and not ecx? who decided this? weird
    mov dword[cpu_vendor_info], ebx
    mov dword[cpu_vendor_info + 4], edx
    mov dword[cpu_vendor_info + 8], ecx
    mov dword[cpu_vendor_info + 12], eax ; store the max eax val

    ; get feature flags
    mov eax, 1
    cpuid
    mov dword[cpu_features], edx
    mov dword[cpu_features + 4], ecx

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
    ; we *do* need to activate FXSR though, specifically OS support for it, if it's not present there's no SSE

    ; enable FXSR OS support
    ; we can also enable OSXMMEXCEPT here, as we need it for SSE
    ; OSXMMEXCEPT requires interrupts, we'll set that up soon, but *nothing* can generate an exception until then
;    mov eax, cr4
;    or eax, 0x600 ; set OSFXSR and OSXMMEXCEPT bits
;    mov cr4, eax

    ; SSE is next, it's enabled as above, however, we'll want to unmask exceptions when we have an interrupt handler going
    ; SSE2 is enabled with SSE
    ; SS is not relevant for us, HTT will be needed to check if we can do multithreading, but that's for later
    ; TM relies on MSRs, we'll take a look at it with ACPI
    ; don't need to do anything with PBE

    ; moving on to ecx
    ; SSE3 is already enabled, PCLMULQDQ is already enabled, DTES64 is to do with segmentation, we don't have a GDT yet
    ; we might be able to use MONITOR, but don't need it yet, can't use DS-CPL until debug is set up

    ; we can enable VMX

    ; check if VMX is supported by the CPU
    test ecx, 0x20
    jz .vmx_end

    ; then check if we can access MSRs
    test edx, 0x20
    jz .vmx_end

    ; let's see if the bios has set the IA32_FEATURE_CONTROL lock bit, and if so, if VMX is enabled
    push ecx
    push edx
    mov ecx, 0x3A
    rdmsr
    test eax, 0x1
    jnz .feature_control_set

    ; not set, so set it ourselves
    call set_feature_control_msr

.feature_control_set:
    test eax, 0x6
    pop edx
    pop ecx
    jz .vmx_end

    mov eax, cr4
    or eax, 0x2000 ; set VMXE bit
    mov cr4, eax

.vmx_end:

    ret

global set_feature_control_msr
set_feature_control_msr:
    ; edx, eax, and ecx should already be pushed here
    push edi
    ; we need to read IA32_MCG_CAP first, minimum is 06_01H, we should be above that
    mov ecx, 0x179
    rdmsr

    ; get the value of LMCE enabled bit, place it where it should be for feature control, and store it in edi
    and eax, 0x08000000
    shr eax, 7
    mov edi, eax

    ; now we gotta check SGX stuff
    xor ecx, ecx
    mov eax, 0x7
    cpuid

    ; SGX global enable
    and ebx, 0x4 ; get the SGX bit
    shl ebx, 16 ; shift to the right position
    or edi, ebx ; save to edi

    ; SGX launch control enable
    shr ecx, 13 ; shift to the right position
    and ecx, 0x20000 ; get the SGX_LC bit
    or edi, ecx ; save to edi

    ; next is SENTER, we'll use cpu_features for this
    mov ecx, dword[cpu_features + 4]

    test ecx, 0x40 ; check if SMX is supported
    jz .no_smx

    or edi, 0xFF00 ; set SENTER enable and features

.no_smx:
    or edi, 0x7 ; set lock bit, enable VMX in both SMX and non-SMX mode, we may want to make it SMX only eventually

    ; now we can write the value to the MSR
    mov ecx, 0x3A
    mov eax, edi
    xor edx, edx
    wrmsr

    mov byte[msr_feature_control_set], 1 ; we've set the feature control MSR

    pop edi
    ret
