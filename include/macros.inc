; -------------------------------------
; macros.inc - Version 1.0
; Copyright (c) red031000 2024-08-23
; -------------------------------------

; common macros

bits 64

KERNEL_VIRTUAL_OFFSET EQU 0xFFFFFFFF80000000

%define VIRT64_TO_PHYS(label) ((label) - KERNEL_VIRTUAL_OFFSET)
%define PHYS_TO_VIRT64(label) ((label) + KERNEL_VIRTUAL_OFFSET)
