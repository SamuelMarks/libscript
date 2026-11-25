/*
 * sanitize_cp437.c - Deterministic C89 normalizer repairing UTF-8 EF BF BD
 * replacement sequences in microsoft/MS-DOS v4.00 source files back to CP437
 * box-drawing bytes, enforcing CRLF line endings, and stripping trailing 0x1A.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char **argv) {
  FILE *in_fp, *out_fp;
  unsigned char *buf;
  size_t sz, i = 0;
  if (argc < 3) {
    fprintf(stderr, "Usage: sanitize_cp437 <in_file> <out_file>\n");
    return 1;
  }
  in_fp = fopen(argv[1], "rb");
  if (!in_fp) return 1;
  fseek(in_fp, 0, SEEK_END);
  sz = (size_t)ftell(in_fp);
  fseek(in_fp, 0, SEEK_SET);
  buf = (unsigned char *)malloc(sz + 1);
  if (!buf) { fclose(in_fp); return 1; }
  sz = fread(buf, 1, sz, in_fp);
  fclose(in_fp);
  while (sz > 0 && buf[sz - 1] == 0x1A) sz--;
  out_fp = fopen(argv[2], "wb");
  if (!out_fp) { free(buf); return 1; }
  while (i < sz) {
    if (i + 2 < sz && buf[i] == 0xEF && buf[i + 1] == 0xBF && buf[i + 2] == 0xBD) {
      fputc(0xCD, out_fp); /* CP437 double horizontal bar '═' */
      i += 3;
    } else if (buf[i] == '\r') {
      fputc('\r', out_fp);
      fputc('\n', out_fp);
      if (i + 1 < sz && buf[i + 1] == '\n') i += 2;
      else i++;
    } else if (buf[i] == '\n') {
      fputc('\r', out_fp);
      fputc('\n', out_fp);
      i++;
    } else {
      fputc(buf[i++], out_fp);
    }
  }
  fclose(out_fp);
  free(buf);
  return 0;
}
