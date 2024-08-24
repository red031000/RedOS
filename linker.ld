ENTRY(_start_32)

KERNEL_HIGHER_OFFSET = 0xFFFFFFFF80000000;

SECTIONS
{
    /* TODO: adjust this to use multiboot 2, we need to adjust it for a higher half kernel anyway */
    . = 2M;

    .boot.text ALIGN(4K) :
    {
        *(.multiboot)
        *(.boot.text)
    }

    .boot.rodata ALIGN(4K) :
    {
        *(.boot.rodata)
    }

    .boot.bss ALIGN(4K) (NOLOAD) :
    {
        *(.boot.bss)
    }

    . += KERNEL_HIGHER_OFFSET;

    .text ALIGN(4K) : AT(ADDR(.text) - KERNEL_HIGHER_OFFSET)
    {
        *(.text)
    }

    .rodata ALIGN(4K) : AT(ADDR(.rodata) - KERNEL_HIGHER_OFFSET)
    {
        *(.rodata)
    }

    .data ALIGN(4K) : AT(ADDR(.data) - KERNEL_HIGHER_OFFSET)
    {
        *(.data)
    }

    .bss ALIGN(4K) : AT(ADDR(.bss) - KERNEL_HIGHER_OFFSET)
    {
        *(COMMON)
        *(.bss)
    }
}
