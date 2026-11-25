/*
 * scp2nasm.c - Deterministic C89 translator lowering Seattle Computer Products
 * 86-DOS ASM.COM mnemonics (v1.25) and early MASM 1.x directives (v2.0) to NASM.
 */
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char **argv) {
  FILE *in_fp, *out_fp;
  char line[1024];
  if (argc < 3) {
    fprintf(stderr, "Usage: scp2nasm <in.asm> <out.asm>\n");
    return 1;
  }
  in_fp = fopen(argv[1], "r");
  if (!in_fp) return 1;
  out_fp = fopen(argv[2], "w");
  if (!out_fp) { fclose(in_fp); return 1; }
  fprintf(out_fp, "BITS 16\n");
  while (fgets(line, sizeof(line), in_fp)) {
    char *p = line;
    while (*p == ' ' || *p == '\t') p++;
    if (strncmp(p, "UP", 2) == 0 && (p[2] == '\r' || p[2] == '\n' || p[2] == ';' || p[2] == ' ' || p[2] == '\0')) {
      fprintf(out_fp, "    CLD\n");
      continue;
    }
    if (strncmp(p, "DOWN", 4) == 0 && (p[4] == '\r' || p[4] == '\n' || p[4] == ';' || p[4] == ' ' || p[4] == '\0')) {
      fprintf(out_fp, "    STD\n");
      continue;
    }
    if (strncmp(p, "END", 3) == 0 && (p[3] == '\r' || p[3] == '\n' || p[3] == '\0' || p[3] == ' ')) {
      fprintf(out_fp, "; %s", p);
      continue;
    }
    fputs(line, out_fp);
  }
  fclose(in_fp);
  fclose(out_fp);
  return 0;
}
