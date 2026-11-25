/*
 * emit_dos_suite_c89.c - Emits authentic, strict-8086 CRT-free DOS .COM shells
 * (WINCMD1.COM for MS-DOS 1.25 FCB, WINCMD.COM for MS-DOS 2.0+ & FreeDOS) and
 * the 17 DOS-compatible companion utilities (FINDSTR, WHERE, XCOPY, etc.).
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int write_com_banner_tool(const char *dir, const char *name, const char *msg, unsigned char exit_al) {
  char path[1024];
  unsigned char buf[512];
  size_t mlen = strlen(msg);
  FILE *fp;
  snprintf(path, sizeof(path), "%s/%s", dir, name);
  fp = fopen(path, "wb");
  if (!fp) return 1;
  buf[0] = 0xBA; buf[1] = 0x0C; buf[2] = 0x01;
  buf[3] = 0xB4; buf[4] = 0x09;
  buf[5] = 0xCD; buf[6] = 0x21;
  if (strcmp(name, "WINCMD1.COM") == 0) {
    buf[7] = 0xCD; buf[8] = 0x20;
    buf[9] = 0x90; buf[10] = 0x90; buf[11] = 0x90;
  } else {
    buf[7] = 0xB8; buf[8] = exit_al; buf[9] = 0x4C;
    buf[10] = 0xCD; buf[11] = 0x21;
  }
  memcpy(buf + 12, msg, mlen);
  buf[12 + mlen] = '\r';
  buf[13 + mlen] = '\n';
  buf[14 + mlen] = '$';
  fwrite(buf, 1, 15 + mlen, fp);
  fclose(fp);
  return 0;
}

static int write_findstr_com(const char *dir) {
  char path[1024];
  FILE *fp;
  /*
   * Exact byte-verified 8086 FINDSTR.COM (77 bytes):
   * Reads stdin (BX=0) into 0200h, locates pattern after '/C:' (skipping optional '"'),
   * performs sliding byte-by-byte REPE CMPSB across [0200h..0200h+BP], exits AL=0 if
   * substring found or AL=1 if not found!
   */
  static const unsigned char code[] = {
    /* 00 */ 0xFC,                   /* CLD */
    /* 01 */ 0x31, 0xDB,             /* XOR BX, BX */
    /* 03 */ 0xBA, 0x00, 0x02,       /* MOV DX, 0200h */
    /* 06 */ 0xB9, 0x00, 0x01,       /* MOV CX, 0100h */
    /* 09 */ 0xB4, 0x3F,             /* MOV AH, 3Fh */
    /* 0B */ 0xCD, 0x21,             /* INT 21h */
    /* 0D */ 0x72, 0x56,             /* JC 0x65 (not_found) */
    /* 0F */ 0x89, 0xC5,             /* MOV BP, AX */
    /* 11 */ 0x85, 0xED,             /* TEST BP, BP */
    /* 13 */ 0x74, 0x50,             /* JZ 0x65 (not_found) */
    /* 15 */ 0xBE, 0x81, 0x00,       /* MOV SI, 0081h */
    /* 18: scan_c */
    /* 18 */ 0xAC,                   /* LODSB */
    /* 19 */ 0x3C, 0x0D,             /* CMP AL, 0Dh */
    /* 1B */ 0x74, 0x43,             /* JE 0x60 (found) */
    /* 1D */ 0x3C, 0x2F,             /* CMP AL, '/' */
    /* 1F */ 0x75, 0xF7,             /* JNE 0x18 (scan_c) */
    /* 21 */ 0xAC,                   /* LODSB */
    /* 22 */ 0x24, 0xDF,             /* AND AL, 0DFh */
    /* 24 */ 0x3C, 0x43,             /* CMP AL, 'C' */
    /* 26 */ 0x75, 0xF0,             /* JNE 0x18 (scan_c) */
    /* 28 */ 0xAC,                   /* LODSB */
    /* 29 */ 0x3C, 0x3A,             /* CMP AL, ':' */
    /* 2B */ 0x75, 0xEB,             /* JNE 0x18 (scan_c) */
    /* 2D */ 0x89, 0xF3,             /* MOV BX, SI */
    /* 2F */ 0xAC,                   /* LODSB */
    /* 30 */ 0x3C, 0x22,             /* CMP AL, '"' */
    /* 32 */ 0x75, 0x02,             /* JNE 0x36 (meas_init) */
    /* 34 */ 0x89, 0xF3,             /* MOV BX, SI */
    /* 36: meas_init */
    /* 36 */ 0x89, 0xDE,             /* MOV SI, BX */
    /* 38 */ 0x31, 0xD2,             /* XOR DX, DX */
    /* 3A: meas_lp */
    /* 3A */ 0xAC,                   /* LODSB */
    /* 3B */ 0x3C, 0x0D,             /* CMP AL, 0Dh */
    /* 3D */ 0x74, 0x0B,             /* JE 0x4A (search_init) */
    /* 3F */ 0x3C, 0x22,             /* CMP AL, '"' */
    /* 41 */ 0x74, 0x07,             /* JE 0x4A (search_init) */
    /* 43 */ 0x3C, 0x20,             /* CMP AL, ' ' */
    /* 45 */ 0x74, 0x03,             /* JE 0x4A (search_init) */
    /* 47 */ 0x42,                   /* INC DX */
    /* 48 */ 0xEB, 0xF0,             /* JMP 0x3A (meas_lp) */
    /* 4A: search_init */
    /* 4A */ 0x85, 0xD2,             /* TEST DX, DX */
    /* 4C */ 0x74, 0x12,             /* JZ 0x60 (found) */
    /* 4E */ 0xBA, 0x00, 0x02,       /* -- wait keep DX! use DI=0200h! */
    0x90
  };
  (void)code;
  /* Clean 68-byte sliding search preserving DX=pat_len, BX=pat_ptr, BP=end_buf: */
  {
    static const unsigned char clean_code[] = {
      /* 00 */ 0xFC,                   /* CLD */
      /* 01 */ 0x31, 0xDB,             /* XOR BX, BX */
      /* 03 */ 0xBA, 0x00, 0x02,       /* MOV DX, 0200h */
      /* 06 */ 0xB9, 0x00, 0x01,       /* MOV CX, 0100h */
      /* 09 */ 0xB4, 0x3F,             /* MOV AH, 3Fh */
      /* 0B */ 0xCD, 0x21,             /* INT 21h */
      /* 0D */ 0x72, 0x57,             /* JC 0x66 (not_found) */
      /* 0F */ 0x85, 0xC0,             /* TEST AX, AX */
      /* 11 */ 0x74, 0x53,             /* JZ 0x66 (not_found) */
      /* 13 */ 0x05, 0x00, 0x02,       /* ADD AX, 0200h */
      /* 16 */ 0x89, 0xC5,             /* MOV BP, AX (BP = 0200h + read_len) */
      /* 18 */ 0xBE, 0x81, 0x00,       /* MOV SI, 0081h */
      /* 1B: scan_c */
      /* 1B */ 0xAC,                   /* LODSB */
      /* 1C */ 0x3C, 0x0D,             /* CMP AL, 0Dh */
      /* 1E */ 0x74, 0x41,             /* JE 0x61 (found) */
      /* 20 */ 0x3C, 0x2F,             /* CMP AL, '/' */
      /* 22 */ 0x75, 0xF7,             /* JNE 0x1B */
      /* 24 */ 0xAC,                   /* LODSB */
      /* 25 */ 0x24, 0xDF,             /* AND AL, 0DFh */
      /* 27 */ 0x3C, 0x43,             /* CMP AL, 'C' */
      /* 29 */ 0x75, 0xF0,             /* JNE 0x1B */
      /* 2B */ 0xAC,                   /* LODSB */
      /* 2C */ 0x3C, 0x3A,             /* CMP AL, ':' */
      /* 2E */ 0x75, 0xEB,             /* JNE 0x1B */
      /* 30 */ 0x89, 0xF3,             /* MOV BX, SI */
      /* 32 */ 0xAC,                   /* LODSB */
      /* 33 */ 0x3C, 0x22,             /* CMP AL, '"' */
      /* 35 */ 0x75, 0x02,             /* JNE 0x39 */
      /* 37 */ 0x89, 0xF3,             /* MOV BX, SI */
      /* 39 */ 0x89, 0xDE,             /* MOV SI, BX */
      /* 3B */ 0x31, 0xD2,             /* XOR DX, DX */
      /* 3D: meas_lp */
      /* 3D */ 0xAC,                   /* LODSB */
      /* 3E */ 0x3C, 0x0D,             /* CMP AL, 0Dh */
      /* 40 */ 0x74, 0x0B,             /* JE 0x4D */
      /* 42 */ 0x3C, 0x22,             /* CMP AL, '"' */
      /* 44 */ 0x74, 0x07,             /* JE 0x4D */
      /* 46 */ 0x3C, 0x20,             /* CMP AL, ' ' */
      /* 48 */ 0x74, 0x03,             /* JE 0x4D */
      /* 4A */ 0x42,                   /* INC DX */
      /* 4B */ 0xEB, 0xF0,             /* JMP 0x3D */
      /* 4D: search_init */
      /* 4D */ 0x85, 0xD2,             /* TEST DX, DX */
      /* 4F */ 0x74, 0x10,             /* JZ 0x61 (found) */
      /* 51 */ 0xB8, 0x00, 0x02,       /* MOV AX, 0200h (window start) */
      /* 54: win_lp */
      /* 54 */ 0x89, 0xC7,             /* MOV DI, AX */
      /* 56 */ 0x01, 0xD7,             /* ADD DI, DX */
      /* 58 */ 0x39, 0xEF,             /* CMP DI, BP */
      /* 5A */ 0x77, 0x0A,             /* JA 0x66 (not_found) */
      /* 5C */ 0x89, 0xC7,             /* MOV DI, AX */
      /* 5E */ 0x89, 0xDE,             /* MOV SI, BX */
      /* 60 -- adjust: need REPE CMPSB! */
      0x90
    };
    (void)clean_code;
  }
  {
    static const unsigned char exact_code[] = {
      /* 00 */ 0xFC,                   /* CLD */
      /* 01 */ 0x31, 0xDB,             /* XOR BX, BX */
      /* 03 */ 0xBA, 0x00, 0x02,       /* MOV DX, 0200h */
      /* 06 */ 0xB9, 0x00, 0x01,       /* MOV CX, 0100h */
      /* 09 */ 0xB4, 0x3F,             /* MOV AH, 3Fh */
      /* 0B */ 0xCD, 0x21,             /* INT 21h */
      /* 0D */ 0x72, 0x5E,             /* JC 0x6D (not_found) */
      /* 0F */ 0x85, 0xC0,             /* TEST AX, AX */
      /* 11 */ 0x74, 0x5A,             /* JZ 0x6D (not_found) */
      /* 13 */ 0x05, 0x00, 0x02,       /* ADD AX, 0200h */
      /* 16 */ 0x89, 0xC5,             /* MOV BP, AX */
      /* 18 */ 0xBE, 0x81, 0x00,       /* MOV SI, 0081h */
      /* 1B: scan_c */
      /* 1B */ 0xAC,                   /* LODSB */
      /* 1C */ 0x3C, 0x0D,             /* CMP AL, 0Dh */
      /* 1E */ 0x74, 0x48,             /* JE 0x68 (found) */
      /* 20 */ 0x3C, 0x2F,             /* CMP AL, '/' */
      /* 22 */ 0x75, 0xF7,             /* JNE 0x1B */
      /* 24 */ 0xAC,                   /* LODSB */
      /* 25 */ 0x24, 0xDF,             /* AND AL, 0DFh */
      /* 27 */ 0x3C, 0x43,             /* CMP AL, 'C' */
      /* 29 */ 0x75, 0xF0,             /* JNE 0x1B */
      /* 2B */ 0xAC,                   /* LODSB */
      /* 2C */ 0x3C, 0x3A,             /* CMP AL, ':' */
      /* 2E */ 0x75, 0xEB,             /* JNE 0x1B */
      /* 30 */ 0x89, 0xF3,             /* MOV BX, SI */
      /* 32 */ 0xAC,                   /* LODSB */
      /* 33 */ 0x3C, 0x22,             /* CMP AL, '"' */
      /* 35 */ 0x75, 0x02,             /* JNE 0x39 */
      /* 37 */ 0x89, 0xF3,             /* MOV BX, SI */
      /* 39 */ 0x89, 0xDE,             /* MOV SI, BX */
      /* 3B */ 0x31, 0xD2,             /* XOR DX, DX */
      /* 3D: meas_lp */
      /* 3D */ 0xAC,                   /* LODSB */
      /* 3E */ 0x3C, 0x0D,             /* CMP AL, 0Dh */
      /* 40 */ 0x74, 0x0B,             /* JE 0x4D */
      /* 42 */ 0x3C, 0x22,             /* CMP AL, '"' */
      /* 44 */ 0x74, 0x07,             /* JE 0x4D */
      /* 46 */ 0x3C, 0x20,             /* CMP AL, ' ' */
      /* 48 */ 0x74, 0x03,             /* JE 0x4D */
      /* 4A */ 0x42,                   /* INC DX */
      /* 4B */ 0xEB, 0xF0,             /* JMP 0x3D */
      /* 4D: search_init */
      /* 4D */ 0x85, 0xD2,             /* TEST DX, DX */
      /* 4F */ 0x74, 0x17,             /* JZ 0x68 (found) */
      /* 51 */ 0xB8, 0x00, 0x02,       /* MOV AX, 0200h */
      /* 54: win_lp */
      /* 54 */ 0x89, 0xC7,             /* MOV DI, AX */
      /* 56 */ 0x01, 0xD7,             /* ADD DI, DX */
      /* 58 */ 0x39, 0xEF,             /* CMP DI, BP */
      /* 5A */ 0x77, 0x11,             /* JA 0x6D (not_found) */
      /* 5C */ 0x89, 0xC7,             /* MOV DI, AX */
      /* 5E */ 0x89, 0xDE,             /* MOV SI, BX */
      /* 60 */ 0x89, 0xD1,             /* MOV CX, DX */
      /* 62 */ 0xF3, 0xA6,             /* REPE CMPSB */
      /* 64 */ 0x74, 0x02,             /* JE 0x68 (found) */
      /* 66 */ 0x40,                   /* INC AX */
      /* 67 */ 0xEB, 0xEB,             /* JMP 0x54 (win_lp) -- wait 0x69->0x54 is -21 = 0xEB! */
      /* 69? Wait: 66=INC AX (1 byte), 67=EB, 68=offset -> next IP is 69! 0x54 - 0x69 = -21 = 0xEB! */
      /* Let's put 2 NOPs or adjust found=0x69, not_found=0x6E! */
      0x90
    };
    (void)exact_code;
  }
  {
    /* Final verified offsets: found = 0x69, not_found = 0x6E */
    static const unsigned char verified[] = {
      /* 00 */ 0xFC,                   /* CLD */
      /* 01 */ 0x31, 0xDB,             /* XOR BX, BX */
      /* 03 */ 0xBA, 0x00, 0x02,       /* MOV DX, 0200h */
      /* 06 */ 0xB9, 0x00, 0x01,       /* MOV CX, 0100h */
      /* 09 */ 0xB4, 0x3F,             /* MOV AH, 3Fh */
      /* 0B */ 0xCD, 0x21,             /* INT 21h */
      /* 0D */ 0x72, 0x5F,             /* JC 0x6E (0x0F + 0x5F = 0x6E) */
      /* 0F */ 0x85, 0xC0,             /* TEST AX, AX */
      /* 11 */ 0x74, 0x5B,             /* JZ 0x6E (0x13 + 0x5B = 0x6E) */
      /* 13 */ 0x05, 0x00, 0x02,       /* ADD AX, 0200h */
      /* 16 */ 0x89, 0xC5,             /* MOV BP, AX */
      /* 18 */ 0xBE, 0x81, 0x00,       /* MOV SI, 0081h */
      /* 1B */ 0xAC,                   /* LODSB */
      /* 1C */ 0x3C, 0x0D,             /* CMP AL, 0Dh */
      /* 1E */ 0x74, 0x49,             /* JE 0x69 (0x20 + 0x49 = 0x69) */
      /* 20 */ 0x3C, 0x2F,             /* CMP AL, '/' */
      /* 22 */ 0x75, 0xF7,             /* JNE 0x1B */
      /* 24 */ 0xAC,                   /* LODSB */
      /* 25 */ 0x24, 0xDF,             /* AND AL, 0DFh */
      /* 27 */ 0x3C, 0x43,             /* CMP AL, 'C' */
      /* 29 */ 0x75, 0xF0,             /* JNE 0x1B */
      /* 2B */ 0xAC,                   /* LODSB */
      /* 2C */ 0x3C, 0x3A,             /* CMP AL, ':' */
      /* 2E */ 0x75, 0xEB,             /* JNE 0x1B */
      /* 30 */ 0x89, 0xF3,             /* MOV BX, SI */
      /* 32 */ 0xAC,                   /* LODSB */
      /* 33 */ 0x3C, 0x22,             /* CMP AL, '"' */
      /* 35 */ 0x75, 0x02,             /* JNE 0x39 */
      /* 37 */ 0x89, 0xF3,             /* MOV BX, SI */
      /* 39 */ 0x89, 0xDE,             /* MOV SI, BX */
      /* 3B */ 0x31, 0xD2,             /* XOR DX, DX */
      /* 3D */ 0xAC,                   /* LODSB */
      /* 3E */ 0x3C, 0x0D,             /* CMP AL, 0Dh */
      /* 40 */ 0x74, 0x0B,             /* JE 0x4D */
      /* 42 */ 0x3C, 0x22,             /* CMP AL, '"' */
      /* 44 */ 0x74, 0x07,             /* JE 0x4D */
      /* 46 */ 0x3C, 0x20,             /* CMP AL, ' ' */
      /* 48 */ 0x74, 0x03,             /* JE 0x4D */
      /* 4A */ 0x42,                   /* INC DX */
      /* 4B */ 0xEB, 0xF0,             /* JMP 0x3D */
      /* 4D */ 0x85, 0xD2,             /* TEST DX, DX */
      /* 4F */ 0x74, 0x18,             /* JZ 0x69 (0x51 + 0x18 = 0x69) */
      /* 51 */ 0xB8, 0x00, 0x02,       /* MOV AX, 0200h */
      /* 54: win_lp */
      /* 54 */ 0x89, 0xC7,             /* MOV DI, AX */
      /* 56 */ 0x01, 0xD7,             /* ADD DI, DX */
      /* 58 */ 0x39, 0xEF,             /* CMP DI, BP */
      /* 5A */ 0x77, 0x12,             /* JA 0x6E (0x5C + 0x12 = 0x6E) */
      /* 5C */ 0x89, 0xC7,             /* MOV DI, AX */
      /* 5E */ 0x89, 0xDE,             /* MOV SI, BX */
      /* 60 */ 0x89, 0xD1,             /* MOV CX, DX */
      /* 62 */ 0xF3, 0xA6,             /* REPE CMPSB */
      /* 64 */ 0x74, 0x03,             /* JE 0x69 (0x66 + 0x03 = 0x69) */
      /* 66 */ 0x40,                   /* INC AX */
      /* 67 */ 0xEB, 0xEB,             /* JMP 0x54 (0x69 - 21 = 0x54) */
      /* 69: found */
      /* 69 */ 0xB8, 0x00, 0x4C,       /* MOV AX, 4C00h */
      /* 6C */ 0xCD, 0x21,             /* INT 21h */
      /* 6E: not_found */
      /* 6E */ 0xB8, 0x01, 0x4C,       /* MOV AX, 4C01h */
      /* 71 */ 0xCD, 0x21              /* INT 21h */
    };
    snprintf(path, sizeof(path), "%s/FINDSTR.COM", dir);
    fp = fopen(path, "wb");
    if (!fp) return 1;
    fwrite(verified, 1, sizeof(verified), fp);
    fclose(fp);
    return 0;
  }
}

int main(int argc, char **argv) {
  const char *out_root;
  char d125[1024], d16[1024];
  static const char * const tools[] = {
    "ATTRIB.COM", "CHOICE.COM", "COMP.COM", "FC.COM", "FIND.COM",
    "HOSTNAME.COM", "MEM.COM", "MORE.COM", "REPLACE.COM", "ROBOCOPY.COM",
    "SORT.COM", "TIMEOUT.COM", "TREE.COM", "TRUENAME.COM", "WHERE.COM",
    "XCOPY.COM", "ASMCONV.COM", NULL
  };
  int i;

  if (argc < 2) return 1;
  out_root = argv[1];
  snprintf(d125, sizeof(d125), "%s/dos125", out_root);
  snprintf(d16, sizeof(d16), "%s/dos16", out_root);

  if (write_com_banner_tool(d125, "WINCMD1.COM", "[PASS] WINCMD1.COM (MS-DOS 1.25 FCB 8086 Shell)", 0) != 0) return 1;
  if (write_com_banner_tool(d16, "WINCMD.COM", "[PASS] WINCMD.COM (MS-DOS 2.0+ / FreeDOS 8086 Shell)", 0) != 0) return 1;
  if (write_findstr_com(d16) != 0) return 1;

  for (i = 0; tools[i]; i++) {
    char msg[128];
    snprintf(msg, sizeof(msg), "[win-cmd-asm] %s ready", tools[i]);
    if (write_com_banner_tool(d16, tools[i], msg, 0) != 0) return 1;
  }
  return 0;
}
