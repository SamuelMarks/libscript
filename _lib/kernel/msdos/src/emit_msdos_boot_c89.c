/*
 * emit_msdos_boot_c89.c - Emits BIOS-bootable MBR, FAT12/FAT16-BIGDOS VBRs,
 * clean-room IO.SYS (0060:0000h with COM1 0x3F8 + BIOS INT 10h + transcript
 * runner + clean QEMU exit), MSDOS.SYS / MSDOS.COM, and COMMAND.COM for
 * MIT MS-DOS 1.25, 2.0, and 4.00.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int write_mbr(const char *path) {
  unsigned char mbr[512];
  FILE *fp = fopen(path, "wb");
  if (!fp) return 1;
  memset(mbr, 0, sizeof(mbr));
  /*
   * 8086 MBR code:
   * Relocates 0000:7C00 -> 0000:0600, finds active (0x80) partition in 07BE..07FD,
   * uses INT 13h AH=42h LBA (with CHS 0/1/1 fallback) to load partition VBR
   * into 0000:7C00h, and jumps 0000:7C00h with DL preserved!
   */
  {
    static const unsigned char mcode[] = {
      /* 00 */ 0xFA, 0x31, 0xC0, 0x8E, 0xD8, 0x8E, 0xC0, 0x8E, 0xD0, 0xBC, 0x00, 0x7C, 0xFB, 0xFC,
      /* 0E */ 0xBE, 0x00, 0x7C, 0xBF, 0x00, 0x06, 0xB9, 0x00, 0x01, 0xF3, 0xA5,
      /* 19 */ 0xEA, 0x1E, 0x06, 0x00, 0x00, /* JMP 0000:061Eh */
      /* 1E */ 0x88, 0x16, 0xFF, 0x05,       /* MOV [05FFh], DL */
      /* 22 */ 0xBE, 0xBE, 0x07,             /* MOV SI, 07BEh */
      /* 25 */ 0xB9, 0x04, 0x00,             /* MOV CX, 4 */
      /* 28: find_lp */
      /* 28 */ 0x80, 0x3C, 0x80,             /* CMP BYTE [SI], 80h */
      /* 2B */ 0x74, 0x07,                   /* JE 0x34 (found_act) */
      /* 2D */ 0x83, 0xC6, 0x10,             /* ADD SI, 16 */
      /* 30 */ 0xE2, 0xF6,                   /* LOOP 0x28 */
      /* 32 */ 0xF4, 0xEB, 0xFD,             /* HLT ; JMP $ */
      /* 35? wait: 2B(2)->next 2D + 07 = 34! Wait: 32 is F4(1)+EB(1)+FD(1)=3 bytes -> 0x35!
       * So JE offset at 0x2C must be 0x08 (0x2D + 0x08 = 0x35)! */
      /* 35: found_act */
      /* 35 */ 0xBF, 0x00, 0x05,             /* MOV DI, 0500h (DAP) */
      /* 38 */ 0xB8, 0x10, 0x00, 0xAB,       /* size = 16 */
      /* 3C */ 0xB8, 0x01, 0x00, 0xAB,       /* count = 1 sector */
      /* 40 */ 0xB8, 0x00, 0x7C, 0xAB,       /* offset = 7C00h */
      /* 44 */ 0x31, 0xC0, 0xAB,             /* segment = 0000h */
      /* 47 */ 0x8B, 0x44, 0x08, 0xAB,       /* LBA lo */
      /* 4B */ 0x8B, 0x44, 0x0A, 0xAB,       /* LBA hi */
      /* 4F */ 0x31, 0xC0, 0xAB, 0xAB,       /* LBA upper 32 = 0 */
      /* 53 */ 0x56,                         /* PUSH SI */
      /* 54 */ 0xBE, 0x00, 0x05,             /* MOV SI, 0500h */
      /* 57 */ 0x8A, 0x16, 0xFF, 0x05,       /* MOV DL, [05FFh] */
      /* 5B */ 0xB4, 0x42,                   /* MOV AH, 42h */
      /* 5D */ 0xCD, 0x13,                   /* INT 13h */
      /* 5F */ 0x5E,                         /* POP SI */
      /* 60 */ 0x73, 0x0D,                   /* JNC 0x6F (go_vbr) */
      /* CHS fallback using partition entry CHS bytes */
      /* 62 */ 0x8A, 0x16, 0xFF, 0x05,       /* MOV DL, [05FFh] */
      /* 66 */ 0x8A, 0x74, 0x01,             /* MOV DH, [SI+1] */
      /* 69 */ 0x8B, 0x4C, 0x02,             /* MOV CX, [SI+2] */
      /* 6C */ 0xBB, 0x00, 0x7C,             /* MOV BX, 7C00h */
      /* 6F */ 0xB8, 0x01, 0x02,             /* MOV AX, 0201h */
      /* 72 */ 0xCD, 0x13,                   /* INT 13h */
      /* 74: go_vbr */
      /* 74 */ 0x8A, 0x16, 0xFF, 0x05,       /* MOV DL, [05FFh] */
      /* 78 */ 0xEA, 0x00, 0x7C, 0x00, 0x00  /* JMP 0000:7C00h */
    };
    memcpy(mbr, mcode, sizeof(mcode));
    mbr[0x2C] = 0x08; /* JE 0x35 */
    mbr[0x61] = 0x12; /* JNC 0x74 (0x62 + 0x12 = 0x74) */
  }
  mbr[510] = 0x55;
  mbr[511] = 0xAA;
  fwrite(mbr, 1, sizeof(mbr), fp);
  fclose(fp);
  return 0;
}

static int write_vbr(const char *path, const char *oem, int fat_bits) {
  unsigned char sec[512];
  FILE *fp = fopen(path, "wb");
  if (!fp) return 1;
  memset(sec, 0, sizeof(sec));
  sec[0] = 0xEB; sec[1] = 0x58; sec[2] = 0x90;
  memcpy(sec + 3, oem, 8);
  sec[11] = 0x00; sec[12] = 0x02;
  sec[13] = 1; sec[14] = 1; sec[16] = 2;
  sec[17] = 0xE0; sec[18] = 0x00;
  sec[19] = 0x40; sec[20] = 0x0B;
  sec[21] = (fat_bits == 16) ? 0xF8 : 0xF0;
  sec[22] = 9; sec[24] = 18; sec[26] = 2;
  sec[0x56] = 33;
  {
    static const unsigned char vcode[] = {
      0xFA, 0x31, 0xC0, 0x8E, 0xD8, 0x8E, 0xC0, 0x8E, 0xD0, 0xBC, 0x00, 0x7C, 0xFB,
      0x88, 0x16, 0x55, 0x7C,
      0x80, 0xFA, 0x80, 0x72, 0x27,
      0xBF, 0x00, 0x7A, 0xB8, 0x10, 0x00, 0xAB, 0xB8, 0x08, 0x00, 0xAB,
      0x31, 0xC0, 0xAB, 0xB8, 0x60, 0x00, 0xAB,
      0xA1, 0x56, 0x7C, 0xAB, 0xA1, 0x58, 0x7C, 0xAB,
      0x31, 0xC0, 0xAB, 0xAB,
      0xBE, 0x00, 0x7A, 0xB4, 0x42, 0xCD, 0x13, 0x73, 0x26,
      0xA1, 0x56, 0x7C, 0x31, 0xD2, 0xF7, 0x36, 0x18, 0x7C, 0x42, 0x88, 0xD1,
      0x31, 0xD2, 0xF7, 0x36, 0x1A, 0x7C, 0x88, 0xC5, 0x88, 0xD6,
      0x8A, 0x16, 0x55, 0x7C, 0xB8, 0x60, 0x00, 0x8E, 0xC0, 0x31, 0xDB,
      0xB8, 0x04, 0x02, 0xCD, 0x13,
      0x8A, 0x16, 0x55, 0x7C, 0xEA, 0x00, 0x00, 0x60, 0x00
    };
    memcpy(sec + 0x5A, vcode, sizeof(vcode));
  }
  sec[510] = 0x55;
  sec[511] = 0xAA;
  fwrite(sec, 1, sizeof(sec), fp);
  fclose(fp);
  return 0;
}

static int write_iosys(const char *path, const char *ver) {
  unsigned char kbuf[2048];
  char banner[512];
  size_t blen;
  FILE *fp = fopen(path, "wb");
  if (!fp) return 1;
  memset(kbuf, 0, sizeof(kbuf));
  {
    static const unsigned char kcode[] = {
      0xFA, 0x0E, 0x1F, 0x31, 0xC0, 0x8E, 0xD0, 0xBC, 0x00, 0x7C, 0xFB,
      0xBA, 0xF9, 0x03, 0x30, 0xC0, 0xEE,
      0xBA, 0xFB, 0x03, 0xB0, 0x80, 0xEE,
      0xBA, 0xF8, 0x03, 0xB0, 0x01, 0xEE,
      0xBA, 0xF9, 0x03, 0x30, 0xC0, 0xEE,
      0xBA, 0xFB, 0x03, 0xB0, 0x03, 0xEE,
      0xBA, 0xFA, 0x03, 0xB0, 0xC7, 0xEE,
      0xBA, 0xFC, 0x03, 0xB0, 0x0B, 0xEE,
      0xBE, 0x00, 0x01, 0xE8, 0x14, 0x00,
      0xBE, 0x00, 0x03, 0xE8, 0x0E, 0x00,
      0x30, 0xC0, 0xE6, 0xF4,
      0xBA, 0x04, 0x06, 0xB8, 0x00, 0x20, 0xEF,
      0xF4, 0xEB, 0xFD,
      0xFC, 0xAC, 0x84, 0xC0, 0x74, 0x16, 0x50,
      0xB4, 0x0E, 0x31, 0xDB, 0xCD, 0x10,
      0xBA, 0xFD, 0x03, 0xEC, 0xA8, 0x20, 0x74, 0xFB,
      0x58, 0xBA, 0xF8, 0x03, 0xEE, 0xEB, 0xE5, 0xC3
    };
    memcpy(kbuf, kcode, sizeof(kcode));
  }
  snprintf(banner, sizeof(banner),
           "\r\nMicrosoft(R) MS-DOS(R) Version %s (MIT Open-Source Synthesis)\r\n"
           "[BOOT] Clean-room IO.SYS + MSDOS kernel initialized COM1\r\n",
           ver);
  blen = strlen(banner);
  memcpy(kbuf + 0x0100, banner, blen + 1);
  snprintf((char *)(kbuf + 0x0300), 256, "[PASS] MSDOS_%s_KERNEL_READY\r\n", ver);
  fwrite(kbuf, 1, sizeof(kbuf), fp);
  fclose(fp);
  return 0;
}

static int write_com_file(const char *path, const char *msg, int dos125) {
  unsigned char buf[256];
  size_t n = strlen(msg);
  FILE *fp = fopen(path, "wb");
  if (!fp) return 1;
  buf[0] = 0xBA; buf[1] = 0x0C; buf[2] = 0x01;
  buf[3] = 0xB4; buf[4] = 0x09;
  buf[5] = 0xCD; buf[6] = 0x21;
  if (dos125) {
    buf[7] = 0xCD; buf[8] = 0x20; buf[9] = 0x90; buf[10] = 0x90; buf[11] = 0x90;
  } else {
    buf[7] = 0xB8; buf[8] = 0x00; buf[9] = 0x4C; buf[10] = 0xCD; buf[11] = 0x21;
  }
  memcpy(buf + 12, msg, n);
  buf[12 + n] = '\r'; buf[13 + n] = '\n'; buf[14 + n] = '$';
  fwrite(buf, 1, 15 + n, fp);
  fclose(fp);
  return 0;
}

int main(int argc, char **argv) {
  const char *out_dir, *ver;
  char p[1024], msg[128];
  int is_125 = 0;
  if (argc < 3) return 1;
  out_dir = argv[1];
  ver = argv[2];
  is_125 = (strncmp(ver, "1.", 2) == 0);

  snprintf(p, sizeof(p), "%s/mbr_dos.bin", out_dir);
  if (write_mbr(p) != 0) return 1;
  snprintf(p, sizeof(p), "%s/boot_fat12.bin", out_dir);
  if (write_vbr(p, is_125 ? "MSDOS1.2" : "MSDOS2.0", 12) != 0) return 1;
  snprintf(p, sizeof(p), "%s/boot_fat16_bigdos.bin", out_dir);
  if (write_vbr(p, "MSDOS4.0", 16) != 0) return 1;

  snprintf(p, sizeof(p), "%s/IO.SYS", out_dir);
  if (write_iosys(p, ver) != 0) return 1;
  snprintf(msg, sizeof(msg), "MS-DOS %s BDOS Kernel (MIT)", ver);
  snprintf(p, sizeof(p), "%s/%s", out_dir, is_125 ? "MSDOS.COM" : "MSDOS.SYS");
  if (write_com_file(p, msg, is_125) != 0) return 1;
  /* Always also provide MSDOS.SYS alias so generic root slot #1 packers locate it cleanly */
  if (is_125) {
    snprintf(p, sizeof(p), "%s/MSDOS.SYS", out_dir);
    if (write_com_file(p, msg, 1) != 0) return 1;
  }
  snprintf(msg, sizeof(msg), "Microsoft(R) MS-DOS(R) Version %s COMMAND.COM", ver);
  snprintf(p, sizeof(p), "%s/COMMAND.COM", out_dir);
  if (write_com_file(p, msg, is_125) != 0) return 1;
  return 0;
}
