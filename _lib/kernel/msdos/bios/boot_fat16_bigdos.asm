; Clean-room MIT/CC0 FAT16 BIGDOS (0x06) LBA VBR for MS-DOS 4.00
BITS 16
ORG 0x7C00
jmp short boot_bigdos
nop
oem_id: db 'MSDOS4.0'
times 0x5A - ($ - $$) db 0
boot_bigdos:
    cli
    xor ax, ax
    mov ds, ax
    mov ss, ax
    mov sp, 0x7C00
    sti
    jmp 0x0060:0x0000
times 510 - ($ - $$) db 0
dw 0xAA55
