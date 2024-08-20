ENTRY(_start)

SECTIONS
{
    /* TODO: adjust this to use multiboot 2, we need to adjust it for a higher half kernel anyway */
    . = 2M;

    .text BLOCK(4K) : ALIGN(4K)
    {
        *(.multiboot)
        *(.text)
    }

    .rodata BLOCK(4K) : ALIGN(4K)
    {
        *(.rodata)
    }

    .bss BLOCK(4K) : ALIGN(4K)
    {
        *(COMMON)
        *(.bss)
    }
}
