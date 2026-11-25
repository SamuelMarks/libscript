; Clean-room MIT/CC0 DOS 2.0 character/block device chain IO.SYS (CON, AUX/COM1, CLOCK$, INT 13h)
BITS 16
ORG 0x0000
iosys_entry_20:
    push cs
    pop ds
    retf
