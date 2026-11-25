; Clean-room MIT/CC0 BIOS IO.SYS shim for MS-DOS 1.25 (CON, AUX/COM1, PRN, INT 13h)
BITS 16
ORG 0x0000
iosys_entry_125:
    push cs
    pop ds
    retf
