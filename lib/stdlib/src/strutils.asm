; -------------------------------------
; strutils.asm - Version 1.0
; Copyright (c) red031000 2024-08-27
; -------------------------------------

; string utilities

bits 64

section .text

ConvertIntegerToHexString:
    ; in: rax = integer value
    ; out: xmm0 = hexadecimal value (big endian, for printing)
    bswap rax
    vmovq xmm1, rax
    shr rax, 4
    vmovq xmm0, rax
    vpunpcklbw xmm0, xmm0, xmm1
    vpand xmm0, xmm0, [rel .mask]
    vpcmpgtb xmm1, xmm0, [rel .compare]
    vpblendvb xmm1, xmm1, [rel .offset], xmm1
    vpaddb xmm1, xmm1, [rel .add] 
    vpaddb xmm0, xmm0, xmm1
    ret

.mask:    times 16 db 0xf
.compare: times 16 db 9
.offset:  times 16 db "A" - ("0" + 10)
.add:     times 16 db "0"
