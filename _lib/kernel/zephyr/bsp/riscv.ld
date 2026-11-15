OUTPUT_ARCH("riscv")
ENTRY(_start)
SECTIONS
{
    . = 0x80000000;
    .text : {
        KEEP(*(.text.init))
        *(.text*)
        *(.rodata*)
    }
    .data : ALIGN(16) {
        *(.sdata*)
        *(.data*)
    }
    .bss : ALIGN(16) {
        *(.sbss*)
        *(.bss*)
        *(COMMON)
        . = ALIGN(16);
        . += 32K;
        _estack = .;
    }
}
