MEMORY
{
    ROM (rx)  : ORIGIN = 0x80000000, LENGTH = 128K
    RAM (rwx) : ORIGIN = 0x80020000, LENGTH = 128K
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

    .tohost :
    {
        . = ALIGN(16);
        *(.tohost)
    } > RAM

    .signature :
    {
        . = ALIGN(16);
        *(.signature)
    } > RAM

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
}
