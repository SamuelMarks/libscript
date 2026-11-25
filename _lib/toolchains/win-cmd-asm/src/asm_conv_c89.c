/*
 * asm_conv_c89.c - Portable C89 multi-assembler dialect lowerer (NASM, JWasm,
 * FASM, and LLVM llvm-mc) for LibScript win-cmd-asm integration.
 */
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char **argv) {
  const char *target = "nasm";
  const char *in_path = NULL;
  const char *out_path = NULL;
  FILE *in_fp, *out_fp;
  char line[1024];
  int i;

  for (i = 1; i < argc; i++) {
    if (strcmp(argv[i], "--version") == 0) {
      printf("asm-conv 0.1.0 (win-cmd-asm multi-assembler dialect lowerer)\n");
      return 0;
    }
    if (strcmp(argv[i], "--help") == 0 || strcmp(argv[i], "-h") == 0) {
      printf("Usage: asm-conv [--to=nasm|jwasm|fasm|llvm-mc] <input.asm> [-o <output.asm>]\n");
      return 0;
    }
    if (strncmp(argv[i], "--to=", 5) == 0) {
      target = argv[i] + 5;
    } else if (strcmp(argv[i], "-o") == 0 && i + 1 < argc) {
      out_path = argv[++i];
    } else if (!in_path) {
      in_path = argv[i];
    }
  }

  if (!in_path) {
    fprintf(stderr, "asm-conv: missing input assembly file\n");
    return 1;
  }
  in_fp = fopen(in_path, "r");
  if (!in_fp) {
    fprintf(stderr, "asm-conv: cannot open '%s'\n", in_path);
    return 1;
  }
  out_fp = out_path ? fopen(out_path, "w") : stdout;
  if (!out_fp) {
    fclose(in_fp);
    return 1;
  }

  if (strcmp(target, "fasm") == 0) fprintf(out_fp, "use16\n");
  else if (strcmp(target, "jwasm") == 0) fprintf(out_fp, ".8086\n.model tiny\n.code\n");
  else if (strcmp(target, "llvm-mc") == 0) fprintf(out_fp, ".code16\n.intel_syntax noprefix\n");
  else fprintf(out_fp, "BITS 16\n");

  while (fgets(line, sizeof(line), in_fp)) {
    char *p = line;
    while (*p == ' ' || *p == '\t') p++;
    if (strncmp(p, "BITS ", 5) == 0 || strncmp(p, "use16", 5) == 0 || strncmp(p, ".8086", 5) == 0) {
      continue;
    }
    if (strcmp(target, "llvm-mc") == 0 && strncmp(p, "ORG ", 4) == 0) {
      fprintf(out_fp, "/* %s */\n", p);
      continue;
    }
    fputs(line, out_fp);
  }
  if (strcmp(target, "jwasm") == 0) fprintf(out_fp, "END\n");

  fclose(in_fp);
  if (out_path) fclose(out_fp);
  return 0;
}
