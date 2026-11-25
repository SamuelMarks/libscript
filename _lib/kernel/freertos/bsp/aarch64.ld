ENTRY(_start)
SECTIONS
{
    . = 0x40080000;
    .text : {
        KEEP(*(.text.init))
        *(.text*)
        *(.rodata*)
    }
    .data : ALIGN(16) {
        *(.data*)
    }
    .bss : ALIGN(16) {
        *(.bss*)
        *(COMMON)
        . = ALIGN(16);
        . += 32K;
        _estack = .;
    }
}
