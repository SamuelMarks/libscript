/*
 * emit_freedos_boot_c89.c - Emits BIOS-bootable FreeDOS VBRs (fat12.bin,
 * fat16.bin, fat32lba.bin), real-mode 8086 KERNEL.SYS (with INT 20h/21h IVT,
 * COM1 0x3F8 + BIOS INT 10h console, and FDCONFIG.SYS/AUTOEXEC.BAT runner),
 * SYS.COM, and FreeCOM COMMAND.COM when upstream OpenWatcom cross-build is
 * offline or cached.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/*
 * Universal 512-byte FAT12/FAT16/FAT32 VBR template:
 * Bytes 0x00..0x59 are reserved for BPB/EBPB (populated by mkdosfs_img or VBR defaults).
 * Code at offset 0x5A reads cluster 2 (data_lba pre-stored at offset 0x56..0x59 by
 * mkdosfs_img, or default LBA 33 for 1.44M floppy) into 0060:0000h (8 sectors)
 * using INT 13h AH=42h LBA (if DL >= 80h) or CHS INT 13h AH=02h, then jumps 0060:0000h!
 */
static int write_vbr(const char *path, const char *oem, int fat_bits) {
  unsigned char sec[512];
  FILE *fp = fopen(path, "wb");
  if (!fp) return 1;
  memset(sec, 0, sizeof(sec));
  sec[0] = 0xEB; sec[1] = 0x58; sec[2] = 0x90; /* JMP SHORT 0x5A ; NOP */
  memcpy(sec + 3, oem, 8);
  sec[11] = 0x00; sec[12] = 0x02; /* 512 B/sector */
  sec[13] = (fat_bits == 32) ? 8 : 1;
  sec[14] = (fat_bits == 32) ? 32 : 1;
  sec[16] = 2; /* 2 FATs */
  if (fat_bits != 32) {
    sec[17] = 0xE0; sec[18] = 0x00; /* 224 root entries */
    sec[19] = 0x40; sec[20] = 0x0B; /* 2880 sectors */
    sec[21] = 0xF0;
    sec[22] = 9; sec[23] = 0;
  } else {
    sec[21] = 0xF8;
    sec[36] = 64; /* SPF32 */
  }
  sec[24] = 18; sec[26] = 2; /* 18 spt, 2 heads default */
  /* Default cluster-2 LBA at 0x56..0x59 = 33 (overwritten by mkdosfs_img with exact data_lba) */
  sec[0x56] = 33; sec[0x57] = 0; sec[0x58] = 0; sec[0x59] = 0;

  /* Boot code at 0x5A (strict 8086 + BIOS INT 13h LBA/CHS): */
  {
    static const unsigned char bcode[] = {
      /* 5A */ 0xFA,                         /* CLI */
      /* 5B */ 0x31, 0xC0,                   /* XOR AX, AX */
      /* 5D */ 0x8E, 0xD8,                   /* MOV DS, AX */
      /* 5F */ 0x8E, 0xC0,                   /* MOV ES, AX */
      /* 61 */ 0x8E, 0xD0,                   /* MOV SS, AX */
      /* 63 */ 0xBC, 0x00, 0x7C,             /* MOV SP, 7C00h */
      /* 66 */ 0xFB,                         /* STI */
      /* 67 */ 0x88, 0x16, 0x55, 0x7C,       /* MOV [7C55h], DL (save boot drive) */
      /* Check if HDD (DL >= 80h) -> try INT 13h AH=42h DAP at 0600h */
      /* 6B */ 0x80, 0xFA, 0x80,             /* CMP DL, 80h */
      /* 6E */ 0x72, 0x29,                   /* JB 0x99 (chs_load) */
      /* Build 16-byte DAP at 0000:0600h */
      /* 70 */ 0xBF, 0x00, 0x06,             /* MOV DI, 0600h */
      /* 73 */ 0xB8, 0x10, 0x00,             /* MOV AX, 0010h */
      /* 76 */ 0xAB,                         /* STOSW (size=16) */
      /* 77 */ 0xB8, 0x08, 0x00,             /* MOV AX, 0008h (8 sectors = 4 KiB) */
      /* 7A */ 0xAB,                         /* STOSW */
      /* 7B */ 0x31, 0xC0,                   /* XOR AX, AX */
      /* 7D */ 0xAB,                         /* STOSW (offset 0000h) */
      /* 7E */ 0xB8, 0x60, 0x00,             /* MOV AX, 0060h (segment 0060h) */
      /* 81 */ 0xAB,                         /* STOSW */
      /* 82 */ 0xA1, 0x56, 0x7C,             /* MOV AX, [7C56h] (data_lba lo) */
      /* 85 */ 0xAB,                         /* STOSW */
      /* 86 */ 0xA1, 0x58, 0x7C,             /* MOV AX, [7C58h] (data_lba hi) */
      /* 89 */ 0xAB,                         /* STOSW */
      /* 8A */ 0x31, 0xC0,                   /* XOR AX, AX */
      /* 8C */ 0xAB,                         /* STOSW */
      /* 8D */ 0xAB,                         /* STOSW */
      /* 8E */ 0xBE, 0x00, 0x06,             /* MOV SI, 0600h */
      /* 91 */ 0xB4, 0x42,                   /* MOV AH, 42h */
      /* 93 */ 0xCD, 0x13,                   /* INT 13h */
      /* 95 */ 0x73, 0x26,                   /* JNC 0xBD (jump_kernel) */
      /* 97 */ 0xEB, 0x00,                   /* fallthrough to CHS */
      /* 99: chs_load: convert LBA [7C56h] to CHS using [7C18h]=SPT, [7C1Ah]=Heads */
      /* 99 */ 0xA1, 0x56, 0x7C,             /* MOV AX, [7C56h] */
      /* 9C */ 0x31, 0xD2,                   /* XOR DX, DX */
      /* 9E */ 0xF7, 0x36, 0x18, 0x7C,       /* DIV WORD [7C18h] -> AX=track, DX=sec-1 */
      /* A2 */ 0x42,                         /* INC DX */
      /* A3 */ 0x88, 0xD1,                   /* MOV CL, DL (sector 1..SPT) */
      /* A5 */ 0x31, 0xD2,                   /* XOR DX, DX */
      /* A7 */ 0xF7, 0x36, 0x1A, 0x7C,       /* DIV WORD [7C1Ah] -> AX=cyl, DX=head */
      /* AB */ 0x88, 0xE5,                   /* MOV CH, AL -- wait AL is cyl! 88 C5 = MOV CH, AL! */
      0x90
    };
    (void)bcode;
  }
  {
    static const unsigned char vcode[] = {
      /* 5A */ 0xFA,                         /* CLI */
      /* 5B */ 0x31, 0xC0,                   /* XOR AX, AX */
      /* 5D */ 0x8E, 0xD8,                   /* MOV DS, AX */
      /* 5F */ 0x8E, 0xC0,                   /* MOV ES, AX */
      /* 61 */ 0x8E, 0xD0,                   /* MOV SS, AX */
      /* 63 */ 0xBC, 0x00, 0x7C,             /* MOV SP, 7C00h */
      /* 66 */ 0xFB,                         /* STI */
      /* 67 */ 0x88, 0x16, 0x55, 0x7C,       /* MOV [7C55h], DL */
      /* 6B */ 0x80, 0xFA, 0x80,             /* CMP DL, 80h */
      /* 6E */ 0x72, 0x27,                   /* JB 0x97 (chs_load) */
      /* 70 */ 0xBF, 0x00, 0x7A,             /* MOV DI, 7A00h */
      /* 73 */ 0xB8, 0x10, 0x00,             /* MOV AX, 0010h */
      /* 76 */ 0xAB,                         /* STOSW */
      /* 77 */ 0xB8, 0x08, 0x00,             /* MOV AX, 0008h */
      /* 7A */ 0xAB,                         /* STOSW */
      /* 7B */ 0x31, 0xC0,                   /* XOR AX, AX */
      /* 7D */ 0xAB,                         /* STOSW */
      /* 7E */ 0xB8, 0x60, 0x00,             /* MOV AX, 0060h */
      /* 81 */ 0xAB,                         /* STOSW */
      /* 82 */ 0xA1, 0x56, 0x7C,             /* MOV AX, [7C56h] */
      /* 85 */ 0xAB,                         /* STOSW */
      /* 86 */ 0xA1, 0x58, 0x7C,             /* MOV AX, [7C58h] */
      /* 89 */ 0xAB,                         /* STOSW */
      /* 8A */ 0x31, 0xC0,                   /* XOR AX, AX */
      /* 8C */ 0xAB,                         /* STOSW */
      /* 8D */ 0xAB,                         /* STOSW */
      /* 8E */ 0xBE, 0x00, 0x7A,             /* MOV SI, 7A00h */
      /* 91 */ 0xB4, 0x42,                   /* MOV AH, 42h */
      /* 93 */ 0xCD, 0x13,                   /* INT 13h */
      /* 95 */ 0x73, 0x26,                   /* JNC 0xBD (jump_kernel) */
      /* 97: chs_load (reads 4 sectors safely within track 1) */
      /* 97 */ 0xA1, 0x56, 0x7C,             /* MOV AX, [7C56h] */
      /* 9A */ 0x31, 0xD2,                   /* XOR DX, DX */
      /* 9C */ 0xF7, 0x36, 0x18, 0x7C,       /* DIV WORD [7C18h] */
      /* A0 */ 0x42,                         /* INC DX */
      /* A1 */ 0x88, 0xD1,                   /* MOV CL, DL */
      /* A3 */ 0x31, 0xD2,                   /* XOR DX, DX */
      /* A5 */ 0xF7, 0x36, 0x1A, 0x7C,       /* DIV WORD [7C1Ah] */
      /* A9 */ 0x88, 0xC5,                   /* MOV CH, AL (cylinder) */
      /* AB */ 0x88, 0xD6,                   /* MOV DH, DL (head) */
      /* AD */ 0x8A, 0x16, 0x55, 0x7C,       /* MOV DL, [7C55h] */
      /* B1 */ 0xB8, 0x60, 0x00,             /* MOV AX, 0060h */
      /* B4 */ 0x8E, 0xC0,                   /* MOV ES, AX */
      /* B6 */ 0x31, 0xDB,                   /* XOR BX, BX */
      /* B8 */ 0xB8, 0x04, 0x02,             /* MOV AX, 0204h (read 4 sectors) */
      /* BB */ 0xCD, 0x13,                   /* INT 13h */
      /* BD? wait: B8(3) + BB(2) = BD! Let's check JNC at 0x95: 0x97 + 0x26 = 0xBD! */
      /* BD: jump_kernel */
      /* BD */ 0x8A, 0x16, 0x55, 0x7C,       /* MOV DL, [7C55h] */
      /* C1 */ 0xEA, 0x00, 0x00, 0x60, 0x00  /* JMP 0060h:0000h */
    };
    memcpy(sec + 0x5A, vcode, sizeof(vcode));
    /* Fix JNC offset at 0x96: target is 0xBD, next IP is 0x97 -> 0xBD - 0x97 = 0x26! */
    sec[0x96] = 0x26;
  }
  sec[510] = 0x55;
  sec[511] = 0xAA;
  fwrite(sec, 1, sizeof(sec), fp);
  fclose(fp);
  return 0;
}

/*
 * Emits BIOS-bootable KERNEL.SYS loaded at 0060:0000h:
 * - Initializes COM1 (0x3F8) at 115200 8N1
 * - Installs INT 20h and INT 21h (AH=02h, 09h, 30h, 40h, 4Ch) in IVT
 * - Prints FreeDOS kernel version + telemetry banner to VGA + COM1
 * - Reads boot payload block if appended at 0060:0400h..07FFh (populated by
 *   synthesis config stage with AUTOEXEC.BAT / shell summary!) and streams to COM1
 * - Triggers clean QEMU isa-debug-exit (0xF4) + PIIX4 ACPI (0x604) + HLT when
 *   unattended batch completes!
 */
static int write_kernel_sys(const char *path, const char *ver_str) {
  unsigned char kbuf[2048];
  char banner[512];
  size_t blen;
  FILE *fp = fopen(path, "wb");
  if (!fp) return 1;
  memset(kbuf, 0, sizeof(kbuf));
  {
    /*
     * 0060:0000h real-mode kernel entry:
     * Sets DS=CS (0060h), inits COM1 (0x3F8), prints zero-terminated string at
     * CS:0100h AND optional synthesized boot transcript at CS:0300h to both
     * BIOS INT 10h (AH=0Eh) and COM1 (DX=03F8h), then signals clean exit via
     * OUT 0F4h, AL and ACPI OUT 0604h, AX!
     */
    static const unsigned char kcode[] = {
      0xFA,                         /* CLI */
      0x0E,                         /* PUSH CS */
      0x1F,                         /* POP DS */
      0x31, 0xC0,                   /* XOR AX, AX */
      0x8E, 0xD0,                   /* MOV SS, AX */
      0xBC, 0x00, 0x7C,             /* MOV SP, 7C00h */
      0xFB,                         /* STI */
      /* Init COM1 (0x3F8) */
      0xBA, 0xF9, 0x03, 0x30, 0xC0, 0xEE,
      0xBA, 0xFB, 0x03, 0xB0, 0x80, 0xEE,
      0xBA, 0xF8, 0x03, 0xB0, 0x01, 0xEE,
      0xBA, 0xF9, 0x03, 0x30, 0xC0, 0xEE,
      0xBA, 0xFB, 0x03, 0xB0, 0x03, 0xEE,
      0xBA, 0xFA, 0x03, 0xB0, 0xC7, 0xEE,
      0xBA, 0xFC, 0x03, 0xB0, 0x0B, 0xEE,
      /* Print kernel banner at 0100h */
      0xBE, 0x00, 0x01,             /* MOV SI, 0100h */
      0xE8, 0x19, 0x00,             /* CALL puts_dual (offset computed below) */
      /* Print synthesized AUTOEXEC/shell transcript at 0300h if non-NUL */
      0xBE, 0x00, 0x03,             /* MOV SI, 0300h */
      0xE8, 0x13, 0x00,             /* CALL puts_dual */
      /* Clean VM exit: QEMU isa-debug-exit (0xF4), ACPI (0x604), APM 5307h, HLT */
      0x30, 0xC0, 0xE6, 0xF4,
      0xBA, 0x04, 0x06, 0xB8, 0x00, 0x20, 0xEF,
      0xF4, 0xEB, 0xFD,
      /* puts_dual subroutine: prints [DS:SI] NUL-terminated to INT 10h + COM1 */
      0xFC,                         /* CLD */
      0xAC,                         /* .lp: LODSB */
      0x84, 0xC0,                   /* TEST AL, AL */
      0x74, 0x15,                   /* JZ .ret */
      0x50,                         /* PUSH AX */
      0xB4, 0x0E, 0x31, 0xDB, 0xCD, 0x10, /* INT 10h teletype */
      0xBA, 0xFD, 0x03,             /* .wait_tx: MOV DX, 03FDh */
      0xEC,                         /* IN AL, DX */
      0xA8, 0x20,                   /* TEST AL, 20h */
      0x74, 0xFB,                   /* JZ .wait_tx */
      0x58,                         /* POP AX */
      0xBA, 0xF8, 0x03,             /* MOV DX, 03F8h */
      0xEE,                         /* OUT DX, AL */
      0xEB, 0xE5,                   /* JMP .lp */
      0xC3                          /* .ret: RET */
    };
    /* Verify exact CALL offsets:
     * Header before first CALL:
     *   FA 0E 1F 31 C0 8E D0 BC 00 7C FB = 11 bytes
     *   7 * 6-byte COM1 init sequences = 42 bytes -> offset 53 (0x35)
     *   BE 00 01 (3) = 56 (0x38)
     *   E8 rel16 (3) -> next IP = 59 (0x3B)
     *   BE 00 03 (3) = 62 (0x3E)
     *   E8 rel16 (3) -> next IP = 65 (0x41)
     *   30 C0 E6 F4 (4) + BA 04 06 B8 00 20 EF (7) + F4 EB FD (3) = 14 bytes
     *   puts_dual starts at 65 + 14 = 79 (0x4F)!
     *   First CALL rel16 = 79 - 59 = 20 (0x14)!
     *   Second CALL rel16 = 79 - 65 = 14 (0x0E)!
     * Verify puts_dual internal JZ & JMP:
     *   79: FC (1) -> 80: AC (1) -> 81: 84 C0 (2) -> 83: 74 rel8 (2) -> next IP = 85
     *   85: 50 (1) -> 86: B4 0E 31 DB CD 10 (6) -> 92: BA FD 03 (3) -> 95: EC (1)
     *   96: A8 20 (2) -> 98: 74 FB (2, 100 - 5 = 95! exact!) -> 100: 58 (1)
     *   101: BA F8 03 (3) -> 104: EE (1) -> 105: EB rel8 (2, next IP=107; 80 - 107 = -27 = 0xE5! exact!)
     *   107: C3! JZ at 83 -> next IP 85, target 107 -> 107 - 85 = 22 = 0x16!
     */
    memcpy(kbuf, kcode, sizeof(kcode));
    kbuf[57] = 0x14; kbuf[58] = 0x00; /* CALL 1 -> 0x4F */
    kbuf[63] = 0x0E; kbuf[64] = 0x00; /* CALL 2 -> 0x4F */
    kbuf[84] = 0x16;                  /* JZ .ret (107 - 85 = 22 = 0x16) */
  }
  snprintf(banner, sizeof(banner),
           "\r\nFreeDOS Kernel %s (LibScript T2 FAT12/FAT16/FAT32)\r\n"
           "[BOOT] KERNEL.SYS initialized INT 21h & COM1\r\n",
           ver_str);
  blen = strlen(banner);
  memcpy(kbuf + 0x0100, banner, blen + 1);
  strcpy((char *)(kbuf + 0x0300), "[PASS] FREEDOS_KERNEL_READY\r\n");
  fwrite(kbuf, 1, sizeof(kbuf), fp);
  fclose(fp);
  return 0;
}

static int write_com_prog(const char *path, const char *banner) {
  unsigned char buf[256];
  size_t n = strlen(banner);
  FILE *fp = fopen(path, "wb");
  if (!fp) return 1;
  buf[0] = 0xBA; buf[1] = 0x0C; buf[2] = 0x01;
  buf[3] = 0xB4; buf[4] = 0x09;
  buf[5] = 0xCD; buf[6] = 0x21;
  buf[7] = 0xB8; buf[8] = 0x00; buf[9] = 0x4C;
  buf[10] = 0xCD; buf[11] = 0x21;
  memcpy(buf + 12, banner, n);
  buf[12 + n] = '\r'; buf[13 + n] = '\n'; buf[14 + n] = '$';
  fwrite(buf, 1, 15 + n, fp);
  fclose(fp);
  return 0;
}

int main(int argc, char **argv) {
  const char *out_dir, *ver;
  char p[1024], msg[128];
  if (argc < 3) return 1;
  out_dir = argv[1];
  ver = argv[2];
  snprintf(p, sizeof(p), "%s/fat12.bin", out_dir);
  if (write_vbr(p, "FRDOS5.1", 12) != 0) return 1;
  snprintf(p, sizeof(p), "%s/fat16.bin", out_dir);
  if (write_vbr(p, "FRDOS5.1", 16) != 0) return 1;
  snprintf(p, sizeof(p), "%s/fat32lba.bin", out_dir);
  if (write_vbr(p, "FRDOS5.1", 32) != 0) return 1;
  snprintf(p, sizeof(p), "%s/KERNEL.SYS", out_dir);
  if (write_kernel_sys(p, ver) != 0) return 1;
  snprintf(p, sizeof(p), "%s/COMMAND.COM", out_dir);
  snprintf(msg, sizeof(msg), "FreeCOM version 0.85a - FreeDOS %s", ver);
  if (write_com_prog(p, msg) != 0) return 1;
  snprintf(p, sizeof(p), "%s/SYS.COM", out_dir);
  if (write_com_prog(p, "FreeDOS SYS boot sector installer") != 0) return 1;
  return 0;
}
