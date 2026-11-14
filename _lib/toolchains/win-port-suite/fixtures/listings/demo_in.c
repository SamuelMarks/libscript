/* C99/GNU input listing for §3.4 cdd-c-transform C89 lowering gate */
int demo(int n, const char *src, char *dst) {
  int i;
  int acc = 0;
  char tag[16];
  if (n <= 0 || n > 64) return -1;
  strcpy(tag, "ok");
  acc = (int)sizeof(tag) + (src ? (int)strlen(src) : 0);
  for (i = 0; i < n; ++i) {
    acc += i;
  }
  if (dst != (char *)0) {
    dst[0] = tag[0];
    dst[1] = '\0';
  }
  return acc;
}
