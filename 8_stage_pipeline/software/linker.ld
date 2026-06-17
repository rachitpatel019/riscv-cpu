MEMORY
{
    ROM (rx) : ORIGIN = 0x00000000, LENGTH = 4K
    RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 4K
}

SECTIONS
{
    .text :
    {
        . = ALIGN(4);
        *(.text)
        *(.text.*)
    } > ROM

    .rodata :
    {
        . = ALIGN(4);
        *(.rodata)
        *(.rodata.*)
    } > ROM

    .data :
    {
        . = ALIGN(4);
        *(.data)
        *(.data.*)
    } > RAM

    .bss :
    {
        . = ALIGN(4);
        *(.bss)
        *(.bss.*)
        *(COMMON)
    } > RAM

    /DISCARD/ :
    {
        *(.comment)
        *(.note*)
    }
}
