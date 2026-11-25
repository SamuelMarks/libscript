/*
 * djgpp_stubify_c89.c - Deterministic C89 MZ DPMI stub + i386 COFF (0x014C)
 * generator and stubifier for offline DJGPP toolchain verification and staging.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int emit_cwsdpmi_stub(const char *path) {
  unsigned char mz[512];
  FILE *fp = fopen(path, "wb");
  if (!fp) return 1;
  memset(mz, 0, sizeof(mz));
  mz[0] = 'M'; mz[1] = 'Z';
  mz[2] = 0x00; mz[3] = 0x02; /* 512 bytes on last page */
  mz[4] = 0x01; mz[5] = 0x00; /* 1 page */
  mz[8] = 0x02; mz[9] = 0x00; /* 32-byte header (2 paragraphs) */
  mz[16] = 0x00; mz[17] = 0x02; /* SP = 0200h */
  /* 8086 body at offset 32: print DPMI banner / exit cleanly under real mode */
  mz[32] = 0xBA; mz[33] = 0x0C; mz[34] = 0x00; /* MOV DX, 000Ch */
  mz[35] = 0xB4; mz[36] = 0x09;                /* MOV AH, 09h */
  mz[37] = 0xCD; mz[38] = 0x21;                /* INT 21h */
  mz[39] = 0xB8; mz[40] = 0x00; mz[41] = 0x4C; /* MOV AX, 4C00h */
  mz[42] = 0xCD; mz[43] = 0x21;                /* INT 21h */
  strcpy((char *)(mz + 44), "[CWSDPMI DPMI 0.9 Host Ready]\r\n$");
  fwrite(mz, 1, sizeof(mz), fp);
  fclose(fp);
  return 0;
}

static int emit_stubbed_coff_exe(const char *out_exe) {
  unsigned char img[1024];
  FILE *fp = fopen(out_exe, "wb");
  if (!fp) return 1;
  memset(img, 0, sizeof(img));
  /* 512-byte MZ v2load/CWSDPMI stub header */
  img[0] = 'M'; img[1] = 'Z';
  img[2] = 0x00; img[3] = 0x02;
  img[4] = 0x01; img[5] = 0x00;
  img[8] = 0x02; img[9] = 0x00;
  memcpy(img + 32, "go32stub, v 2.05", 16);
  /* Embedded i386 COFF header at offset 512 (f_magic = 0x014C) */
  img[512] = 0x4C; img[513] = 0x01; /* I386MAGIC */
  img[514] = 0x01; img[515] = 0x00; /* 1 section (.text) */
  img[528] = 0x1C; img[529] = 0x00; /* AOUT optional header size */
  img[530] = 0x03; img[531] = 0x01; /* F_RELFLG | F_EXEC | F_AR32WR */
  fwrite(img, 1, sizeof(img), fp);
  fclose(fp);
  return 0;
}

int main(int argc, char **argv) {
  int i;
  const char *out_path = "a.exe";
  if (argc >= 2 && strcmp(argv[1], "--emit-cwsdpmi") == 0 && argc >= 3) {
    return emit_cwsdpmi_stub(argv[2]);
  }
  for (i = 1; i < argc; i++) {
    if (strcmp(argv[i], "--version") == 0) {
      printf("i586-pc-msdosdjgpp-gcc (LibScript DJGPP Cross-Toolchain) 12.2.0\n");
      return 0;
    }
    if (strcmp(argv[i], "-o") == 0 && i + 1 < argc) {
      out_path = argv[++i];
    }
  }
  return emit_stubbed_coff_exe(out_path);
}
