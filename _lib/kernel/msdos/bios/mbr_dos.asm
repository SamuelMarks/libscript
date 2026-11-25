; Clean-room MIT/CC0 446-byte DOS MBR loader for LibScript
BITS 16
ORG 0x0600
start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti
    cld
    mov si, 0x7C00
    mov di, 0x0600
    mov cx, 256
    rep movsw
    jmp 0x0000:relocated
relocated:
    mov si, 0x07BE
    mov cx, 4
find_active:
    cmp byte [si], 0x80
    je boot_part
    add si, 16
    loop find_active
    hlt
boot_part:
    mov [0x05FF], dl
    mov ax, [si + 8]
    mov dx, [si + 10]
    mov di, 0x0500
    mov word [di], 16
    mov word [di + 2], 1
    mov word [di + 4], 0x7C00
    mov word [di + 6], 0x0000
    mov [di + 8], ax
    mov [di + 10], dx
    mov word [di + 12], 0
    mov word [di + 14], 0
    mov si, 0x0500
    mov dl, [0x05FF]
    mov ah, 0x42
    int 0x13
    jmp 0x0000:0x7C00
