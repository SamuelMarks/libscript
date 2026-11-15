ENTRY(_start)
SECTIONS
{
    . = 1M;
    .text : ALIGN(4K) {
        KEEP(*(.multiboot))
        *(.text*)
        *(.rodata*)
    }
    .data : ALIGN(4K) {
        *(.data*)
    }
    .bss : ALIGN(4K) {
        *(COMMON)
        *(.bss*)
        . = ALIGN(16);
        . += 16K;
        _estack = .;
    }
}
