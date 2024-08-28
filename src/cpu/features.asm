; -------------------------------------
; features.asm - Version 1.0
; Copyright (c) red031000 2024-08-20
; -------------------------------------

; CPU feature detection and enabling

; long mode
bits 64

section .bss

align 4
cpu_features:
    resd 2 ; 2 for now, might need more

cpu_vendor_info:
    resd 4 ; 3 for vendor string, 1 for max eax

msr_feature_control_set:
    resb 1 ; keep track of whether we've set this

section .rodata

align 16
AuthenticAMD:
    dq "enticAMD", "Auth"

section .text

global cpu_features_init
cpu_features_init:
    ; Detect and init CPU features
    xor rax, rax
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

    ; frees up rcx, as we just use rdx
    shl rdx, 32
    or rdx, rcx

    ; init x87 FPU with 0x37F as the control word
    mov rax, cr0
    mov rbx, 0xFFFFFFFFFFFFFFFB
    and rax, rbx ; clear EM 
    or rax, 0x0000000000000002 ; set MP
    mov cr0, rax
    fninit

    ; enable SSE by enabling FXSR support
    mov rax, cr4
    or rax, 0x40600 ; set OSFXSR, OSXMMEXCEPT, and OSXSAVE bits
    mov cr4, rax

    ; SSE2 requires XCR0 to be adjusted
    push rdx

    xor rcx, rcx
    xgetbv ; get XCR0
    or rax, 0x6 ; set SSE and AVX bits, SSE and YMM in AMD
    xsetbv ; set XCR0

    pop rdx

    ; don't really care about VME/DE/PSE, not very useful to us

    bt rdx, 37 ; check if we have TSC
    jnc .no_tsc

    ; enable TSC
    mov rax, cr4
    mov rbx, 0xFFFFFFFFFFFFFFFB
    and rax, rbx ; clear TSD bit
    mov cr4, rax

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
    ; FXSR is already enabled, we did it above, same with OSXMMEXCEPT, SSE and SSE2

    ; SSE is next, it's enabled as above, however, we'll want to unmask exceptions when we have an interrupt handler going
    ; SSE2 is enabled with SSE
    ; SS is not relevant for us, HTT will be needed to check if we can do multithreading, but that's for later
    ; TM/TM2 is set by the bios, we don't need to do anything
    ; don't need to do anything with PBE

    ; SSE3 is already enabled, PCLMULQDQ is already enabled, DTES64 is to do with segmentation, we don't have a GDT yet
    ; we might be able to use MONITOR, but don't need it yet, can't use DS-CPL until debug is set up

    ; we can enable VMX, but only for intel cpus, AMD doesn't have VMX

    vmovdqa xmm1, [cpu_vendor_info]
    vpsrldq xmm1, xmm1, 4
    vpcmpeqb xmm0, xmm1, [AuthenticAMD]
    vpmovmskb eax, xmm0
    inc ax
    jz .vmx_end

    ; check if VMX is supported by the CPU
    bt rdx, 5
    jnc .vmx_end

    ; then check if we can access MSRs
    test rdx, 0x20
    jz .vmx_end

    ; let's see if the bios has set the IA32_FEATURE_CONTROL lock bit, and if so, if VMX is enabled
    push rdx
    mov ecx, 0x3A
    rdmsr
    test rax, 0x1
    jnz .intel_feature_control_set_vmx

    ; not set, so set it ourselves
    call set_intel_feature_control_msr

.intel_feature_control_set_vmx:
    pop rdx
    test rax, 0x6
    jz .vmx_end

    mov rax, cr4
    or rax, 0x2000 ; set VMXE bit
    mov cr4, rax

.vmx_end:
    ; next is SMX, again this is intel only

    ; xmm0 should already have the comparison bits set
    vpmovmskb eax, xmm0
    inc ax
    jz .smx_end

    ; check if SMX is supported
    bt rdx, 6
    jnc .smx_end

    ; check if we can access MSRs
    test rdx, 0x20
    jz .smx_end

    ; check if we've alredy set the feature control MSR
    cmp byte[msr_feature_control_set], 1
    jnz .intel_feature_control_set_smx_no_pop

    ; let's see if the bios has set the IA32_FEATURE_CONTROL lock bit
    push rdx
    mov ecx, 0x3A
    rdmsr
    test rax, 0x1
    jnz .intel_feature_control_set_smx

    ; not set, so set it ourselves
    call set_intel_feature_control_msr

.intel_feature_control_set_smx:
    pop rdx

.intel_feature_control_set_smx_no_pop:
    mov rax, cr4
    or rax, 0x4000 ; set SMXE bit
    mov cr4, rax

.smx_end:

    ; we should enable speedstep, again it's intel only

    ; xmm0 should already have the comparison bits set
    vpmovmskb eax, xmm0
    inc ax
    jz .speedstep_end

    ; check if EIST is supported
    bt rdx, 7
    jnc .speedstep_end

    ; check if we can access MSRs
    test rdx, 0x20
    jz .speedstep_end

    ; we need to set speedstep in the IA32_MISC_ENABLE MSR
    push rdx
    mov ecx, 0x1A0
    rdmsr

    or rax, 0x10000

    wrmsr
    pop rdx

.speedstep_end:



    ret

global set_intel_feature_control_msr
set_intel_feature_control_msr:
    ; edx, eax, and ecx should already be pushed here
    ; we need to read IA32_MCG_CAP first, minimum is 06_01H, we should be above that
    mov ecx, 0x179
    rdmsr

    ; get the value of LMCE enabled bit, place it where it should be for feature control, and store it in edi
    and rax, 0x08000000
    shr rax, 7
    mov rdi, rax

    ; now we gotta check SGX stuff
    xor rcx, rcx
    mov eax, 0x7
    cpuid

    ; SGX global enable
    and rbx, 0x4 ; get the SGX bit
    shl rbx, 16 ; shift to the right position
    or rdi, rbx ; save to edi

    ; SGX launch control enable
    shr rcx, 13 ; shift to the right position
    and rcx, 0x20000 ; get the SGX_LC bit
    or rdi, rcx ; save to edi

    ; next is SENTER, we'll use cpu_features for this
    mov ecx, dword[cpu_features + 4]

    test rcx, 0x40 ; check if SMX is supported
    jz .no_smx

    or rdi, 0xFF00 ; set SENTER enable and features

.no_smx:
    or rdi, 0x7 ; set lock bit, enable VMX in both SMX and non-SMX mode, we may want to make it SMX only eventually

    ; now we can write the value to the MSR
    mov rcx, 0x3A
    mov rax, rdi
    xor rdx, rdx
    wrmsr

    mov byte[msr_feature_control_set], 1 ; we've set the feature control MSR

    ret
