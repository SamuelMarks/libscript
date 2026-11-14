/* Dispatch loop listing for §3.4 computed-goto / switch lowering gate */
int run_vm(const unsigned char *code, int len) {
  int pc = 0;
  int reg = 0;
  while (pc < len) {
    switch (code[pc++]) {
      case 0: return reg;
      case 1: reg += 1; break;
      case 2: reg *= 2; break;
      default: reg -= 1; break;
    }
  }
  return reg;
}
