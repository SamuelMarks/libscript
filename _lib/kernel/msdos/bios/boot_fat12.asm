; Clean-room MIT/CC0 FAT12 VBR loading contiguous IO.SYS from cluster 2 to 0060:0000h
BITS 16
ORG 0x7C00
jmp short boot_entry
nop
oem_id: db 'MSDOS2.0'
times 0x5A - ($ - $$) db 0
boot_entry:
    cli
    xor ax, ax
    mov ds, ax
    mov ss, ax
    mov sp, 0x7C00
    sti
    mov ax, 0x0060
    mov es, ax
    xor bx, bx
    mov ax, 0x0204
    mov cx, 0x0002
    xor dh, dh
    int 0x13
    jmp 0x0060:0x0000
times 510 - ($ - $$) db 0
dw 0xAA55
