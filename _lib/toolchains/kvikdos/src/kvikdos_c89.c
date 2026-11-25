/*
 * kvikdos_c89.c - Zero-dependency portable C89 8086 real-mode CPU and DOS
 * INT 20h/21h (FCB 1.25 + Handle 2.0+) headless CLI runner for LibScript.
 */
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
#include <direct.h>
#include <io.h>
#define MKDIR_HOST(p) _mkdir(p)
#else
#include <dirent.h>
#include <sys/stat.h>
#include <unistd.h>
#define MKDIR_HOST(p) mkdir((p), 0755)
#endif

#define MEM_SIZE 0x110000UL
#define MAX_HANDLES 32

typedef unsigned char u8;
typedef unsigned short u16;
typedef signed char s8;
typedef signed short s16;
typedef unsigned long u32;

typedef struct {
  u16 ax, cx, dx, bx, sp, bp, si, di;
  u16 es, cs, ss, ds, ip, flags;
  int halted;
  int exit_code;
  u16 dta_seg, dta_off;
  u8 dos_major, dos_minor;
  char root_dir[512];
  char cwd_dos[128];
  FILE *handles[MAX_HANDLES];
  u8 *mem;
} Cpu8086;

enum {
  FL_CF = 0x0001,
  FL_PF = 0x0004,
  FL_AF = 0x0010,
  FL_ZF = 0x0040,
  FL_SF = 0x0080,
  FL_DF = 0x0400,
  FL_OF = 0x0800
};

static u32 lin_addr(u16 seg, u16 off) {
  return (((u32)seg << 4) + (u32)off) & 0xFFFFFUL;
}

static u8 rd8(Cpu8086 *c, u16 seg, u16 off) {
  return c->mem[lin_addr(seg, off)];
}

static u16 rd16(Cpu8086 *c, u16 seg, u16 off) {
  u32 a = lin_addr(seg, off);
  return (u16)((u16)c->mem[a] | ((u16)c->mem[(a + 1) & 0xFFFFFUL] << 8));
}

static void wr8(Cpu8086 *c, u16 seg, u16 off, u8 v) {
  c->mem[lin_addr(seg, off)] = v;
}

static void wr16(Cpu8086 *c, u16 seg, u16 off, u16 v) {
  u32 a = lin_addr(seg, off);
  c->mem[a] = (u8)(v & 0xFF);
  c->mem[(a + 1) & 0xFFFFFUL] = (u8)((v >> 8) & 0xFF);
}

static void push16(Cpu8086 *c, u16 v) {
  c->sp = (u16)(c->sp - 2);
  wr16(c, c->ss, c->sp, v);
}

static u16 pop16(Cpu8086 *c) {
  u16 v = rd16(c, c->ss, c->sp);
  c->sp = (u16)(c->sp + 2);
  return v;
}

static u8 fetch8(Cpu8086 *c) {
  u8 v = rd8(c, c->cs, c->ip);
  c->ip = (u16)(c->ip + 1);
  return v;
}

static u16 fetch16(Cpu8086 *c) {
  u16 lo = fetch8(c);
  u16 hi = fetch8(c);
  return (u16)(lo | (hi << 8));
}

static u16 *reg16_ptr(Cpu8086 *c, int r) {
  switch (r & 7) {
    case 0: return &c->ax;
    case 1: return &c->cx;
    case 2: return &c->dx;
    case 3: return &c->bx;
    case 4: return &c->sp;
    case 5: return &c->bp;
    case 6: return &c->si;
    default: return &c->di;
  }
}

static u8 get_reg8(Cpu8086 *c, int r) {
  u16 *p = reg16_ptr(c, r & 3);
  return (r & 4) ? (u8)((*p >> 8) & 0xFF) : (u8)(*p & 0xFF);
}

static void set_reg8(Cpu8086 *c, int r, u8 v) {
  u16 *p = reg16_ptr(c, r & 3);
  if (r & 4) {
    *p = (u16)((*p & 0x00FF) | ((u16)v << 8));
  } else {
    *p = (u16)((*p & 0xFF00) | (u16)v);
  }
}

static u16 *sreg_ptr(Cpu8086 *c, int sr) {
  switch (sr & 3) {
    case 0: return &c->es;
    case 1: return &c->cs;
    case 2: return &c->ss;
    default: return &c->ds;
  }
}

static void set_flag_bit(Cpu8086 *c, u16 mask, int cond) {
  if (cond) c->flags |= mask;
  else c->flags &= (u16)~mask;
}

static void update_pzs8(Cpu8086 *c, u8 v) {
  u8 p = v ^ (v >> 4);
  p ^= (p >> 2);
  p ^= (p >> 1);
  set_flag_bit(c, FL_PF, (p & 1) == 0);
  set_flag_bit(c, FL_ZF, v == 0);
  set_flag_bit(c, FL_SF, (v & 0x80) != 0);
}

static void update_pzs16(Cpu8086 *c, u16 v) {
  u8 p = (u8)(v & 0xFF);
  p ^= (p >> 4);
  p ^= (p >> 2);
  p ^= (p >> 1);
  set_flag_bit(c, FL_PF, (p & 1) == 0);
  set_flag_bit(c, FL_ZF, v == 0);
  set_flag_bit(c, FL_SF, (v & 0x8000) != 0);
}

static u8 alu8(Cpu8086 *c, int op, u8 a, u8 b) {
  u16 r = 0;
  int cf = (c->flags & FL_CF) ? 1 : 0;
  switch (op & 7) {
    case 0: r = (u16)a + (u16)b;
      set_flag_bit(c, FL_CF, r > 0xFF);
      set_flag_bit(c, FL_OF, ((~(a ^ b) & (a ^ (u8)r)) & 0x80) != 0);
      break;
    case 1: r = (u16)(a | b); set_flag_bit(c, FL_CF | FL_OF, 0); break;
    case 2: r = (u16)a + (u16)b + (u16)cf;
      set_flag_bit(c, FL_CF, r > 0xFF);
      set_flag_bit(c, FL_OF, ((~(a ^ b) & (a ^ (u8)r)) & 0x80) != 0);
      break;
    case 3: r = (u16)a - (u16)b - (u16)cf;
      set_flag_bit(c, FL_CF, (u16)a < (u16)b + (u16)cf);
      set_flag_bit(c, FL_OF, (((a ^ b) & (a ^ (u8)r)) & 0x80) != 0);
      break;
    case 4: r = (u16)(a & b); set_flag_bit(c, FL_CF | FL_OF, 0); break;
    case 5:
    case 7: r = (u16)a - (u16)b;
      set_flag_bit(c, FL_CF, a < b);
      set_flag_bit(c, FL_OF, (((a ^ b) & (a ^ (u8)r)) & 0x80) != 0);
      break;
    case 6: r = (u16)(a ^ b); set_flag_bit(c, FL_CF | FL_OF, 0); break;
  }
  update_pzs8(c, (u8)r);
  return ((op & 7) == 7) ? a : (u8)r;
}

static u16 alu16(Cpu8086 *c, int op, u16 a, u16 b) {
  u32 r = 0;
  u32 cf = (c->flags & FL_CF) ? 1UL : 0UL;
  switch (op & 7) {
    case 0: r = (u32)a + (u32)b;
      set_flag_bit(c, FL_CF, r > 0xFFFFUL);
      set_flag_bit(c, FL_OF, ((~(a ^ b) & (a ^ (u16)r)) & 0x8000) != 0);
      break;
    case 1: r = (u32)(a | b); set_flag_bit(c, FL_CF | FL_OF, 0); break;
    case 2: r = (u32)a + (u32)b + cf;
      set_flag_bit(c, FL_CF, r > 0xFFFFUL);
      set_flag_bit(c, FL_OF, ((~(a ^ b) & (a ^ (u16)r)) & 0x8000) != 0);
      break;
    case 3: r = (u32)a - (u32)b - cf;
      set_flag_bit(c, FL_CF, (u32)a < (u32)b + cf);
      set_flag_bit(c, FL_OF, (((a ^ b) & (a ^ (u16)r)) & 0x8000) != 0);
      break;
    case 4: r = (u32)(a & b); set_flag_bit(c, FL_CF | FL_OF, 0); break;
    case 5:
    case 7: r = (u32)a - (u32)b;
      set_flag_bit(c, FL_CF, a < b);
      set_flag_bit(c, FL_OF, (((a ^ b) & (a ^ (u16)r)) & 0x8000) != 0);
      break;
    case 6: r = (u32)(a ^ b); set_flag_bit(c, FL_CF | FL_OF, 0); break;
  }
  update_pzs16(c, (u16)r);
  return ((op & 7) == 7) ? a : (u16)r;
}

static void map_dos_path(Cpu8086 *c, const char *dos_in, char *out, size_t cap) {
  char rel[256];
  size_t i = 0, j = 0;
  if (dos_in[0] && dos_in[1] == ':') i = 2;
  if (dos_in[i] == '\\' || dos_in[i] == '/') {
    i++;
  } else if (c->cwd_dos[0]) {
    size_t cl = strlen(c->cwd_dos);
    if (cl < sizeof(rel) - 2) {
      memcpy(rel, c->cwd_dos, cl);
      j = cl;
      if (j > 0 && rel[j - 1] != '/') rel[j++] = '/';
    }
  }
  while (dos_in[i] && j + 1 < sizeof(rel)) {
    char ch = dos_in[i++];
    if (ch == '\\') ch = '/';
    rel[j++] = ch;
  }
  rel[j] = '\0';
  snprintf(out, cap, "%s/%s", c->root_dir, rel);
}

static void fcb_to_filename(Cpu8086 *c, u16 seg, u16 off, char *out) {
  int i, p = 0;
  for (i = 1; i <= 8; i++) {
    u8 ch = rd8(c, seg, (u16)(off + i));
    if (ch == ' ' || ch == 0) break;
    out[p++] = (char)ch;
  }
  if (rd8(c, seg, (u16)(off + 9)) != ' ' && rd8(c, seg, (u16)(off + 9)) != 0) {
    out[p++] = '.';
    for (i = 9; i <= 11; i++) {
      u8 ch = rd8(c, seg, (u16)(off + i));
      if (ch == ' ' || ch == 0) break;
      out[p++] = (char)ch;
    }
  }
  out[p] = '\0';
}

static int alloc_handle(Cpu8086 *c, FILE *fp) {
  int i;
  for (i = 5; i < MAX_HANDLES; i++) {
    if (!c->handles[i]) {
      c->handles[i] = fp;
      return i;
    }
  }
  return -1;
}

static void handle_int21(Cpu8086 *c) {
  u8 ah = (u8)((c->ax >> 8) & 0xFF);
  u8 al = (u8)(c->ax & 0xFF);
  set_flag_bit(c, FL_CF, 0);
  switch (ah) {
    case 0x00:
      c->halted = 1;
      c->exit_code = 0;
      break;
    case 0x01:
    case 0x07:
    case 0x08: {
      int ch = getchar();
      if (ch == EOF) ch = 0x1A;
      if (ah == 0x01) putchar(ch);
      set_reg8(c, 0, (u8)ch);
      break;
    }
    case 0x02:
    case 0x06: {
      u8 dl = (u8)(c->dx & 0xFF);
      if (ah == 0x06 && dl == 0xFF) {
        set_flag_bit(c, FL_ZF, 1);
        set_reg8(c, 0, 0);
      } else {
        putchar(dl);
        fflush(stdout);
        set_reg8(c, 0, dl);
      }
      break;
    }
    case 0x09: {
      u16 off = c->dx;
      for (;;) {
        u8 ch = rd8(c, c->ds, off++);
        if (ch == '$') break;
        putchar(ch);
      }
      fflush(stdout);
      break;
    }
    case 0x19:
      set_reg8(c, 0, 2); /* Drive C: */
      break;
    case 0x1A:
      c->dta_seg = c->ds;
      c->dta_off = c->dx;
      break;
    case 0x25: {
      u16 iv = (u16)(al * 4);
      wr16(c, 0, iv, c->dx);
      wr16(c, 0, (u16)(iv + 2), c->ds);
      break;
    }
    case 0x2A:
      c->cx = 2026;
      c->dx = (11 << 8) | 25;
      set_reg8(c, 0, 3);
      break;
    case 0x2C:
      c->cx = (12 << 8) | 0;
      c->dx = 0;
      break;
    case 0x30:
      c->ax = (u16)(((u16)c->dos_minor << 8) | c->dos_major);
      c->bx = 0;
      c->cx = 0;
      break;
    case 0x35: {
      u16 iv = (u16)(al * 4);
      c->bx = rd16(c, 0, iv);
      c->es = rd16(c, 0, (u16)(iv + 2));
      break;
    }
    case 0x0F:
    case 0x16: { /* FCB Open / Create (MS-DOS 1.25+) */
      char fname[32], hpath[768];
      FILE *fp;
      int h;
      fcb_to_filename(c, c->ds, c->dx, fname);
      map_dos_path(c, fname, hpath, sizeof(hpath));
      fp = fopen(hpath, (ah == 0x16) ? "w+b" : "r+b");
      if (!fp && ah == 0x0F) fp = fopen(hpath, "rb");
      if (!fp) {
        set_reg8(c, 0, 0xFF);
      } else {
        h = alloc_handle(c, fp);
        if (h < 0) {
          fclose(fp);
          set_reg8(c, 0, 0xFF);
        } else {
          wr16(c, c->ds, (u16)(c->dx + 14), 128); /* default record size */
          wr8(c, c->ds, (u16)(c->dx + 31), (u8)h);
          wr8(c, c->ds, (u16)(c->dx + 32), 0);
          set_reg8(c, 0, 0x00);
        }
      }
      break;
    }
    case 0x10: { /* FCB Close */
      u8 h = rd8(c, c->ds, (u16)(c->dx + 31));
      if (h >= 5 && h < MAX_HANDLES && c->handles[h]) {
        fclose(c->handles[h]);
        c->handles[h] = NULL;
      }
      set_reg8(c, 0, 0x00);
      break;
    }
    case 0x14: { /* FCB Sequential Read */
      u8 h = rd8(c, c->ds, (u16)(c->dx + 31));
      u16 rsz = rd16(c, c->ds, (u16)(c->dx + 14));
      if (rsz == 0) rsz = 128;
      if (h < 5 || h >= MAX_HANDLES || !c->handles[h]) {
        set_reg8(c, 0, 0x01);
      } else {
        size_t got = fread(&c->mem[lin_addr(c->dta_seg, c->dta_off)], 1, rsz, c->handles[h]);
        if (got == 0) set_reg8(c, 0, 0x01);
        else if (got < rsz) {
          memset(&c->mem[lin_addr(c->dta_seg, c->dta_off) + got], 0, rsz - got);
          set_reg8(c, 0, 0x03);
        } else set_reg8(c, 0, 0x00);
      }
      break;
    }
    case 0x15: { /* FCB Sequential Write */
      u8 h = rd8(c, c->ds, (u16)(c->dx + 31));
      u16 rsz = rd16(c, c->ds, (u16)(c->dx + 14));
      if (rsz == 0) rsz = 128;
      if (h < 5 || h >= MAX_HANDLES || !c->handles[h]) {
        set_reg8(c, 0, 0x01);
      } else {
        fwrite(&c->mem[lin_addr(c->dta_seg, c->dta_off)], 1, rsz, c->handles[h]);
        set_reg8(c, 0, 0x00);
      }
      break;
    }
    case 0x39: { /* MKDIR */
      char dpath[128], hpath[768];
      size_t k = 0;
      while (k + 1 < sizeof(dpath)) {
        u8 ch = rd8(c, c->ds, (u16)(c->dx + k));
        if (!ch) break;
        dpath[k++] = (char)ch;
      }
      dpath[k] = '\0';
      map_dos_path(c, dpath, hpath, sizeof(hpath));
      if (MKDIR_HOST(hpath) != 0) {
        set_flag_bit(c, FL_CF, 1);
        c->ax = 5;
      }
      break;
    }
    case 0x3C:
    case 0x3D: { /* Handle Create / Open */
      char dpath[256], hpath[768];
      size_t k = 0;
      FILE *fp;
      int h;
      while (k + 1 < sizeof(dpath)) {
        u8 ch = rd8(c, c->ds, (u16)(c->dx + k));
        if (!ch) break;
        dpath[k++] = (char)ch;
      }
      dpath[k] = '\0';
      map_dos_path(c, dpath, hpath, sizeof(hpath));
      if (ah == 0x3C) fp = fopen(hpath, "w+b");
      else if ((al & 3) == 0) fp = fopen(hpath, "rb");
      else fp = fopen(hpath, "r+b");
      if (!fp) {
        set_flag_bit(c, FL_CF, 1);
        c->ax = 2;
      } else {
        h = alloc_handle(c, fp);
        if (h < 0) {
          fclose(fp);
          set_flag_bit(c, FL_CF, 1);
          c->ax = 4;
        } else c->ax = (u16)h;
      }
      break;
    }
    case 0x3E: { /* Handle Close */
      if (c->bx >= 5 && c->bx < MAX_HANDLES && c->handles[c->bx]) {
        fclose(c->handles[c->bx]);
        c->handles[c->bx] = NULL;
      }
      break;
    }
    case 0x3F: { /* Handle Read */
      FILE *fp = NULL;
      if (c->bx == 0) fp = stdin;
      else if (c->bx < MAX_HANDLES) fp = c->handles[c->bx];
      if (!fp) {
        set_flag_bit(c, FL_CF, 1);
        c->ax = 6;
      } else {
        size_t n = fread(&c->mem[lin_addr(c->ds, c->dx)], 1, c->cx, fp);
        c->ax = (u16)n;
      }
      break;
    }
    case 0x40: { /* Handle Write */
      FILE *fp = NULL;
      if (c->bx == 1 || c->bx == 4) fp = stdout;
      else if (c->bx == 2) fp = stderr;
      else if (c->bx < MAX_HANDLES) fp = c->handles[c->bx];
      if (!fp) {
        set_flag_bit(c, FL_CF, 1);
        c->ax = 6;
      } else {
        size_t n = fwrite(&c->mem[lin_addr(c->ds, c->dx)], 1, c->cx, fp);
        fflush(fp);
        c->ax = (u16)n;
      }
      break;
    }
    case 0x42: { /* LSEEK */
      FILE *fp = (c->bx < MAX_HANDLES) ? c->handles[c->bx] : NULL;
      if (!fp) {
        set_flag_bit(c, FL_CF, 1);
        c->ax = 6;
      } else {
        long off = (long)(((u32)c->cx << 16) | (u32)c->dx);
        int wh = (al == 1) ? SEEK_CUR : (al == 2) ? SEEK_END : SEEK_SET;
        if (fseek(fp, off, wh) != 0) {
          set_flag_bit(c, FL_CF, 1);
          c->ax = 25;
        } else {
          long pos = ftell(fp);
          c->dx = (u16)((pos >> 16) & 0xFFFF);
          c->ax = (u16)(pos & 0xFFFF);
        }
      }
      break;
    }
    case 0x4A: /* Resize memory block */
      break;
    case 0x4C:
      c->halted = 1;
      c->exit_code = (int)al;
      break;
    default:
      break;
  }
}

static void decode_rm(Cpu8086 *c, u8 modrm, int seg_ovr, u16 *ea_seg, u16 *ea_off) {
  int mod = (modrm >> 6) & 3;
  int rm = modrm & 7;
  u16 disp = 0;
  u16 def_seg = c->ds;
  if (mod == 1) disp = (u16)(s16)(s8)fetch8(c);
  else if (mod == 2) disp = fetch16(c);
  switch (rm) {
    case 0: *ea_off = (u16)(c->bx + c->si + disp); break;
    case 1: *ea_off = (u16)(c->bx + c->di + disp); break;
    case 2: *ea_off = (u16)(c->bp + c->si + disp); def_seg = c->ss; break;
    case 3: *ea_off = (u16)(c->bp + c->di + disp); def_seg = c->ss; break;
    case 4: *ea_off = (u16)(c->si + disp); break;
    case 5: *ea_off = (u16)(c->di + disp); break;
    case 6:
      if (mod == 0) { *ea_off = fetch16(c); }
      else { *ea_off = (u16)(c->bp + disp); def_seg = c->ss; }
      break;
    default: *ea_off = (u16)(c->bx + disp); break;
  }
  *ea_seg = (seg_ovr >= 0) ? *sreg_ptr(c, seg_ovr) : def_seg;
}

static int cond_true(Cpu8086 *c, int cc) {
  int cf = (c->flags & FL_CF) != 0;
  int zf = (c->flags & FL_ZF) != 0;
  int sf = (c->flags & FL_SF) != 0;
  int of = (c->flags & FL_OF) != 0;
  int pf = (c->flags & FL_PF) != 0;
  switch (cc & 15) {
    case 0: return of;
    case 1: return !of;
    case 2: return cf;
    case 3: return !cf;
    case 4: return zf;
    case 5: return !zf;
    case 6: return cf || zf;
    case 7: return !cf && !zf;
    case 8: return sf;
    case 9: return !sf;
    case 10: return pf;
    case 11: return !pf;
    case 12: return sf != of;
    case 13: return sf == of;
    case 14: return zf || (sf != of);
    default: return !zf && (sf == of);
  }
}

static void step_cpu(Cpu8086 *c) {
  int seg_ovr = -1;
  int rep_mode = 0; /* 1=REP/REPE, 2=REPNE */
  u8 op;
  for (;;) {
    op = fetch8(c);
    if (op == 0x26) { seg_ovr = 0; continue; }
    if (op == 0x2E) { seg_ovr = 1; continue; }
    if (op == 0x36) { seg_ovr = 2; continue; }
    if (op == 0x3E) { seg_ovr = 3; continue; }
    if (op == 0xF3) { rep_mode = 1; continue; }
    if (op == 0xF2) { rep_mode = 2; continue; }
    if (op == 0xF0) { continue; }
    break;
  }

  if ((op & 0xC0) == 0x00 && (op & 7) < 6) { /* Standard ALU reg/mem & AL/AX imm */
    int alu_op = (op >> 3) & 7;
    if ((op & 7) == 4) {
      set_reg8(c, 0, alu8(c, alu_op, get_reg8(c, 0), fetch8(c)));
    } else if ((op & 7) == 5) {
      c->ax = alu16(c, alu_op, c->ax, fetch16(c));
    } else {
      u8 mrm = fetch8(c);
      int reg = (mrm >> 3) & 7;
      int w = op & 1;
      int d = (op >> 1) & 1;
      if (((mrm >> 6) & 3) == 3) {
        if (!w) {
          u8 r1 = get_reg8(c, d ? reg : (mrm & 7));
          u8 r2 = get_reg8(c, d ? (mrm & 7) : reg);
          u8 res = alu8(c, alu_op, r1, r2);
          if (alu_op != 7) set_reg8(c, d ? reg : (mrm & 7), res);
        } else {
          u16 *p1 = reg16_ptr(c, d ? reg : (mrm & 7));
          u16 *p2 = reg16_ptr(c, d ? (mrm & 7) : reg);
          u16 res = alu16(c, alu_op, *p1, *p2);
          if (alu_op != 7) *p1 = res;
        }
      } else {
        u16 es, eo;
        decode_rm(c, mrm, seg_ovr, &es, &eo);
        if (!w) {
          u8 mv = rd8(c, es, eo), rv = get_reg8(c, reg);
          u8 res = d ? alu8(c, alu_op, rv, mv) : alu8(c, alu_op, mv, rv);
          if (alu_op != 7) {
            if (d) set_reg8(c, reg, res); else wr8(c, es, eo, res);
          }
        } else {
          u16 mv = rd16(c, es, eo), rv = *reg16_ptr(c, reg);
          u16 res = d ? alu16(c, alu_op, rv, mv) : alu16(c, alu_op, mv, rv);
          if (alu_op != 7) {
            if (d) *reg16_ptr(c, reg) = res; else wr16(c, es, eo, res);
          }
        }
      }
    }
    return;
  }

  if (op >= 0x40 && op <= 0x47) {
    u16 *p = reg16_ptr(c, op & 7);
    int old_cf = (c->flags & FL_CF) != 0;
    *p = alu16(c, 0, *p, 1);
    set_flag_bit(c, FL_CF, old_cf);
    return;
  }
  if (op >= 0x48 && op <= 0x4F) {
    u16 *p = reg16_ptr(c, op & 7);
    int old_cf = (c->flags & FL_CF) != 0;
    *p = alu16(c, 5, *p, 1);
    set_flag_bit(c, FL_CF, old_cf);
    return;
  }
  if (op >= 0x50 && op <= 0x57) { push16(c, *reg16_ptr(c, op & 7)); return; }
  if (op >= 0x58 && op <= 0x5F) { *reg16_ptr(c, op & 7) = pop16(c); return; }
  if (op >= 0x70 && op <= 0x7F) {
    s8 rel = (s8)fetch8(c);
    if (cond_true(c, op & 15)) c->ip = (u16)(c->ip + (s16)rel);
    return;
  }
  if (op >= 0xB0 && op <= 0xB7) { set_reg8(c, op & 7, fetch8(c)); return; }
  if (op >= 0xB8 && op <= 0xBF) { *reg16_ptr(c, op & 7) = fetch16(c); return; }

  switch (op) {
    case 0x06: case 0x0E: case 0x16: case 0x1E:
      push16(c, *sreg_ptr(c, (op >> 3) & 3)); break;
    case 0x07: case 0x17: case 0x1F:
      *sreg_ptr(c, (op >> 3) & 3) = pop16(c); break;
    case 0x80: case 0x81: case 0x82: case 0x83: {
      u8 mrm = fetch8(c);
      int sub = (mrm >> 3) & 7;
      int w = op & 1;
      if (((mrm >> 6) & 3) == 3) {
        if (!w) {
          u8 imm = fetch8(c);
          u8 res = alu8(c, sub, get_reg8(c, mrm & 7), imm);
          if (sub != 7) set_reg8(c, mrm & 7, res);
        } else {
          u16 imm = (op == 0x83) ? (u16)(s16)(s8)fetch8(c) : fetch16(c);
          u16 *p = reg16_ptr(c, mrm & 7);
          u16 res = alu16(c, sub, *p, imm);
          if (sub != 7) *p = res;
        }
      } else {
        u16 es, eo;
        decode_rm(c, mrm, seg_ovr, &es, &eo);
        if (!w) {
          u8 imm = fetch8(c);
          u8 res = alu8(c, sub, rd8(c, es, eo), imm);
          if (sub != 7) wr8(c, es, eo, res);
        } else {
          u16 imm = (op == 0x83) ? (u16)(s16)(s8)fetch8(c) : fetch16(c);
          u16 res = alu16(c, sub, rd16(c, es, eo), imm);
          if (sub != 7) wr16(c, es, eo, res);
        }
      }
      break;
    }
    case 0x84: case 0x85: {
      u8 mrm = fetch8(c);
      int reg = (mrm >> 3) & 7;
      if (((mrm >> 6) & 3) == 3) {
        if (op == 0x84) (void)alu8(c, 4, get_reg8(c, mrm & 7), get_reg8(c, reg));
        else (void)alu16(c, 4, *reg16_ptr(c, mrm & 7), *reg16_ptr(c, reg));
      } else {
        u16 es, eo;
        decode_rm(c, mrm, seg_ovr, &es, &eo);
        if (op == 0x84) (void)alu8(c, 4, rd8(c, es, eo), get_reg8(c, reg));
        else (void)alu16(c, 4, rd16(c, es, eo), *reg16_ptr(c, reg));
      }
      break;
    }
    case 0x88: case 0x89: case 0x8A: case 0x8B: {
      u8 mrm = fetch8(c);
      int reg = (mrm >> 3) & 7;
      int w = op & 1;
      int d = (op >> 1) & 1;
      if (((mrm >> 6) & 3) == 3) {
        if (!w) {
          if (d) set_reg8(c, reg, get_reg8(c, mrm & 7));
          else set_reg8(c, mrm & 7, get_reg8(c, reg));
        } else {
          if (d) *reg16_ptr(c, reg) = *reg16_ptr(c, mrm & 7);
          else *reg16_ptr(c, mrm & 7) = *reg16_ptr(c, reg);
        }
      } else {
        u16 es, eo;
        decode_rm(c, mrm, seg_ovr, &es, &eo);
        if (!w) {
          if (d) set_reg8(c, reg, rd8(c, es, eo)); else wr8(c, es, eo, get_reg8(c, reg));
        } else {
          if (d) *reg16_ptr(c, reg) = rd16(c, es, eo); else wr16(c, es, eo, *reg16_ptr(c, reg));
        }
      }
      break;
    }
    case 0x8C: case 0x8E: {
      u8 mrm = fetch8(c);
      int sr = (mrm >> 3) & 3;
      if (((mrm >> 6) & 3) == 3) {
        if (op == 0x8C) *reg16_ptr(c, mrm & 7) = *sreg_ptr(c, sr);
        else *sreg_ptr(c, sr) = *reg16_ptr(c, mrm & 7);
      } else {
        u16 es, eo;
        decode_rm(c, mrm, seg_ovr, &es, &eo);
        if (op == 0x8C) wr16(c, es, eo, *sreg_ptr(c, sr));
        else *sreg_ptr(c, sr) = rd16(c, es, eo);
      }
      break;
    }
    case 0x8D: {
      u8 mrm = fetch8(c);
      u16 es, eo;
      decode_rm(c, mrm, seg_ovr, &es, &eo);
      *reg16_ptr(c, (mrm >> 3) & 7) = eo;
      break;
    }
    case 0x90: break;
    case 0x91: case 0x92: case 0x93: case 0x94: case 0x95: case 0x96: case 0x97: {
      u16 *p = reg16_ptr(c, op & 7);
      u16 t = c->ax; c->ax = *p; *p = t;
      break;
    }
    case 0x98: c->ax = (u16)(s16)(s8)(c->ax & 0xFF); break;
    case 0x99: c->dx = (c->ax & 0x8000) ? 0xFFFF : 0x0000; break;
    case 0x9C: push16(c, (u16)(c->flags | 0xF002)); break;
    case 0x9D: c->flags = pop16(c); break;
    case 0xA0: set_reg8(c, 0, rd8(c, (seg_ovr >= 0) ? *sreg_ptr(c, seg_ovr) : c->ds, fetch16(c))); break;
    case 0xA1: c->ax = rd16(c, (seg_ovr >= 0) ? *sreg_ptr(c, seg_ovr) : c->ds, fetch16(c)); break;
    case 0xA2: wr8(c, (seg_ovr >= 0) ? *sreg_ptr(c, seg_ovr) : c->ds, fetch16(c), get_reg8(c, 0)); break;
    case 0xA3: wr16(c, (seg_ovr >= 0) ? *sreg_ptr(c, seg_ovr) : c->ds, fetch16(c), c->ax); break;
    case 0xA4: case 0xAA: case 0xAC: case 0xA6: case 0xAE: {
      int step = (c->flags & FL_DF) ? -1 : 1;
      u16 sseg = (seg_ovr >= 0) ? *sreg_ptr(c, seg_ovr) : c->ds;
      do {
        if (rep_mode && c->cx == 0) break;
        if (op == 0xA4) { wr8(c, c->es, c->di, rd8(c, sseg, c->si)); c->si = (u16)(c->si + step); c->di = (u16)(c->di + step); }
        else if (op == 0xAA) { wr8(c, c->es, c->di, get_reg8(c, 0)); c->di = (u16)(c->di + step); }
        else if (op == 0xAC) { set_reg8(c, 0, rd8(c, sseg, c->si)); c->si = (u16)(c->si + step); }
        else if (op == 0xA6) { (void)alu8(c, 7, rd8(c, sseg, c->si), rd8(c, c->es, c->di)); c->si = (u16)(c->si + step); c->di = (u16)(c->di + step); }
        else if (op == 0xAE) { (void)alu8(c, 7, get_reg8(c, 0), rd8(c, c->es, c->di)); c->di = (u16)(c->di + step); }
        if (rep_mode) {
          c->cx = (u16)(c->cx - 1);
          if ((op == 0xA6 || op == 0xAE) && ((rep_mode == 1 && !(c->flags & FL_ZF)) || (rep_mode == 2 && (c->flags & FL_ZF)))) break;
        }
      } while (rep_mode && c->cx != 0);
      break;
    }
    case 0xA8: (void)alu8(c, 4, get_reg8(c, 0), fetch8(c)); break;
    case 0xA9: (void)alu16(c, 4, c->ax, fetch16(c)); break;
    case 0xC2: { u16 n = fetch16(c); c->ip = pop16(c); c->sp = (u16)(c->sp + n); break; }
    case 0xC3:
      if (c->sp == 0xFFFE) { c->halted = 1; c->exit_code = 0; }
      else c->ip = pop16(c);
      break;
    case 0xC6: case 0xC7: {
      u8 mrm = fetch8(c);
      if (((mrm >> 6) & 3) == 3) {
        if (op == 0xC6) set_reg8(c, mrm & 7, fetch8(c));
        else *reg16_ptr(c, mrm & 7) = fetch16(c);
      } else {
        u16 es, eo;
        decode_rm(c, mrm, seg_ovr, &es, &eo);
        if (op == 0xC6) wr8(c, es, eo, fetch8(c));
        else wr16(c, es, eo, fetch16(c));
      }
      break;
    }
    case 0xCB: c->ip = pop16(c); c->cs = pop16(c); break;
    case 0xCD: {
      u8 iv = fetch8(c);
      if (iv == 0x20) { c->halted = 1; c->exit_code = 0; }
      else if (iv == 0x21) handle_int21(c);
      else if (iv == 0x10 && ((c->ax >> 8) & 0xFF) == 0x0E) { putchar(c->ax & 0xFF); fflush(stdout); }
      break;
    }
    case 0xD0: case 0xD1: case 0xD2: case 0xD3: {
      u8 mrm = fetch8(c);
      int sub = (mrm >> 3) & 7;
      int cnt = (op & 2) ? (c->cx & 0x1F) : 1;
      if (((mrm >> 6) & 3) == 3 && cnt > 0) {
        if (!(op & 1)) {
          u8 v = get_reg8(c, mrm & 7);
          if (sub == 4) { set_flag_bit(c, FL_CF, ((v << (cnt - 1)) & 0x80) != 0); v = (u8)(v << cnt); update_pzs8(c, v); }
          else if (sub == 5) { set_flag_bit(c, FL_CF, ((v >> (cnt - 1)) & 1) != 0); v = (u8)(v >> cnt); update_pzs8(c, v); }
          set_reg8(c, mrm & 7, v);
        } else {
          u16 *p = reg16_ptr(c, mrm & 7), v = *p;
          if (sub == 4) { set_flag_bit(c, FL_CF, ((v << (cnt - 1)) & 0x8000) != 0); v = (u16)(v << cnt); update_pzs16(c, v); }
          else if (sub == 5) { set_flag_bit(c, FL_CF, ((v >> (cnt - 1)) & 1) != 0); v = (u16)(v >> cnt); update_pzs16(c, v); }
          *p = v;
        }
      }
      break;
    }
    case 0xE0: { s8 rel = (s8)fetch8(c); c->cx = (u16)(c->cx - 1); if (c->cx != 0 && !(c->flags & FL_ZF)) c->ip = (u16)(c->ip + (s16)rel); break; }
    case 0xE1: { s8 rel = (s8)fetch8(c); c->cx = (u16)(c->cx - 1); if (c->cx != 0 && (c->flags & FL_ZF)) c->ip = (u16)(c->ip + (s16)rel); break; }
    case 0xE2: { s8 rel = (s8)fetch8(c); c->cx = (u16)(c->cx - 1); if (c->cx != 0) c->ip = (u16)(c->ip + (s16)rel); break; }
    case 0xE3: { s8 rel = (s8)fetch8(c); if (c->cx == 0) c->ip = (u16)(c->ip + (s16)rel); break; }
    case 0xE4: case 0xE5: (void)fetch8(c); c->ax = 0; break;
    case 0xE6: case 0xE7: { u8 port = fetch8(c); if (port == 0xF4) { c->halted = 1; c->exit_code = 0; } break; }
    case 0xEC: case 0xED: c->ax = 0; break;
    case 0xEE: case 0xEF: if (c->dx == 0x0604) { c->halted = 1; c->exit_code = 0; } break;
    case 0xE8: { s16 rel = (s16)fetch16(c); push16(c, c->ip); c->ip = (u16)(c->ip + rel); break; }
    case 0xE9: { s16 rel = (s16)fetch16(c); c->ip = (u16)(c->ip + rel); break; }
    case 0xEB: { s8 rel = (s8)fetch8(c); c->ip = (u16)(c->ip + (s16)rel); break; }
    case 0xF4: c->halted = 1; break;
    case 0xF6: case 0xF7: {
      u8 mrm = fetch8(c);
      int sub = (mrm >> 3) & 7;
      if (((mrm >> 6) & 3) == 3) {
        if (op == 0xF6) {
          u8 v = get_reg8(c, mrm & 7);
          if (sub == 0) (void)alu8(c, 4, v, fetch8(c));
          else if (sub == 2) set_reg8(c, mrm & 7, (u8)~v);
          else if (sub == 3) set_reg8(c, mrm & 7, alu8(c, 5, 0, v));
          else if (sub == 4) c->ax = (u16)((u16)get_reg8(c, 0) * (u16)v);
          else if (sub == 6 && v) c->ax = (u16)(((c->ax % v) << 8) | ((c->ax / v) & 0xFF));
        } else {
          u16 *p = reg16_ptr(c, mrm & 7), v = *p;
          if (sub == 0) (void)alu16(c, 4, v, fetch16(c));
          else if (sub == 2) *p = (u16)~v;
          else if (sub == 3) *p = alu16(c, 5, 0, v);
          else if (sub == 4) { u32 pr = (u32)c->ax * (u32)v; c->ax = (u16)pr; c->dx = (u16)(pr >> 16); }
          else if (sub == 6 && v) { u32 dv = ((u32)c->dx << 16) | c->ax; c->ax = (u16)(dv / v); c->dx = (u16)(dv % v); }
        }
      }
      break;
    }
    case 0xF8: set_flag_bit(c, FL_CF, 0); break;
    case 0xF9: set_flag_bit(c, FL_CF, 1); break;
    case 0xFA: case 0xFB: break;
    case 0xFC: set_flag_bit(c, FL_DF, 0); break;
    case 0xFD: set_flag_bit(c, FL_DF, 1); break;
    case 0xFE: case 0xFF: {
      u8 mrm = fetch8(c);
      int sub = (mrm >> 3) & 7;
      if (((mrm >> 6) & 3) == 3) {
        if (op == 0xFE) {
          u8 v = get_reg8(c, mrm & 7);
          if (sub == 0) set_reg8(c, mrm & 7, alu8(c, 0, v, 1));
          else if (sub == 1) set_reg8(c, mrm & 7, alu8(c, 5, v, 1));
        } else {
          u16 *p = reg16_ptr(c, mrm & 7);
          if (sub == 0) *p = alu16(c, 0, *p, 1);
          else if (sub == 1) *p = alu16(c, 5, *p, 1);
          else if (sub == 2) { push16(c, c->ip); c->ip = *p; }
          else if (sub == 4) { c->ip = *p; }
          else if (sub == 6) { push16(c, *p); }
        }
      } else if (op == 0xFF) {
        u16 es, eo;
        decode_rm(c, mrm, seg_ovr, &es, &eo);
        if (sub == 0) wr16(c, es, eo, alu16(c, 0, rd16(c, es, eo), 1));
        else if (sub == 1) wr16(c, es, eo, alu16(c, 5, rd16(c, es, eo), 1));
        else if (sub == 2) { push16(c, c->ip); c->ip = rd16(c, es, eo); }
        else if (sub == 4) { c->ip = rd16(c, es, eo); }
        else if (sub == 6) { push16(c, rd16(c, es, eo)); }
      }
      break;
    }
    default:
      fprintf(stderr, "[kvikdos] Unsupported 8086 opcode 0x%02X at %04X:%04X\n", op, c->cs, (u16)(c->ip - 1));
      c->halted = 1;
      c->exit_code = 127;
      break;
  }
}

static void populate_fcb_arg(u8 *fcb, const char *tok) {
  int i = 0;
  memset(fcb, 0, 36);
  memset(fcb + 1, ' ', 11);
  if (!tok || !tok[0]) return;
  while (*tok && *tok != '.' && i < 8) {
    fcb[1 + i++] = (u8)toupper((unsigned char)*tok++);
  }
  if (*tok == '.') {
    int j = 0;
    tok++;
    while (*tok && j < 3) {
      fcb[9 + j++] = (u8)toupper((unsigned char)*tok++);
    }
  }
}

int main(int argc, char **argv) {
  Cpu8086 cpu;
  const char *prog_path = NULL;
  char cmd_tail[128];
  char arg1[64], arg2[64];
  int argi = 1, tail_len = 0;
  u32 max_steps = 50000000UL, steps = 0;
  FILE *fp;
  size_t fsz;
  u16 psp_seg = 0x1000;

  memset(&cpu, 0, sizeof(cpu));
  strcpy(cpu.root_dir, ".");
  cpu.dos_major = 4;
  cpu.dos_minor = 0;
  cmd_tail[0] = '\0';
  arg1[0] = '\0';
  arg2[0] = '\0';

  while (argi < argc) {
    if (strcmp(argv[argi], "--version") == 0) {
      printf("kvikdos 0.1.0 (LibScript C89 8086 + DOS INT 21h CLI Runner)\n");
      return 0;
    }
    if (strcmp(argv[argi], "--help") == 0 || strcmp(argv[argi], "-h") == 0) {
      printf("Usage: kvikdos [--root=<dir>] [--dos-ver=1.25|2.0|4.0] <program.com|program.exe> [args...]\n");
      return 0;
    }
    if (strncmp(argv[argi], "--root=", 7) == 0) {
      snprintf(cpu.root_dir, sizeof(cpu.root_dir), "%s", argv[argi] + 7);
      argi++;
      continue;
    }
    if (strncmp(argv[argi], "--dos-ver=", 10) == 0) {
      const char *v = argv[argi] + 10;
      if (strncmp(v, "1.", 2) == 0) { cpu.dos_major = 1; cpu.dos_minor = 25; }
      else if (strncmp(v, "2.", 2) == 0) { cpu.dos_major = 2; cpu.dos_minor = 0; }
      else { cpu.dos_major = 4; cpu.dos_minor = 0; }
      argi++;
      continue;
    }
    prog_path = argv[argi++];
    break;
  }

  if (!prog_path) {
    fprintf(stderr, "Error: missing 16-bit DOS .COM/.EXE path\n");
    return 1;
  }

  while (argi < argc) {
    if (!arg1[0]) snprintf(arg1, sizeof(arg1), "%s", argv[argi]);
    else if (!arg2[0]) snprintf(arg2, sizeof(arg2), "%s", argv[argi]);
    if (tail_len + (int)strlen(argv[argi]) + 2 < 126) {
      cmd_tail[tail_len++] = ' ';
      strcpy(cmd_tail + tail_len, argv[argi]);
      tail_len += (int)strlen(argv[argi]);
    }
    argi++;
  }

  fp = fopen(prog_path, "rb");
  if (!fp) {
    fprintf(stderr, "Error: cannot open DOS binary '%s'\n", prog_path);
    return 1;
  }

  cpu.mem = (u8 *)calloc(1, MEM_SIZE);
  if (!cpu.mem) {
    fclose(fp);
    return 1;
  }

  /* Build PSP at 1000:0000 and environment block at 0FE0:0000 */
  wr16(&cpu, 0x0FE0, 0x0000, 0x3D50); /* "P=\0\0" minimal env */
  wr16(&cpu, psp_seg, 0x0000, 0x20CD); /* INT 20h */
  wr16(&cpu, psp_seg, 0x0002, 0x9FFF); /* Top of conventional RAM */
  wr16(&cpu, psp_seg, 0x002C, 0x0FE0); /* Env segment */
  populate_fcb_arg(&cpu.mem[lin_addr(psp_seg, 0x005C)], arg1);
  populate_fcb_arg(&cpu.mem[lin_addr(psp_seg, 0x006C)], arg2);
  wr8(&cpu, psp_seg, 0x0080, (u8)tail_len);
  memcpy(&cpu.mem[lin_addr(psp_seg, 0x0081)], cmd_tail, (size_t)tail_len);
  wr8(&cpu, psp_seg, (u16)(0x0081 + tail_len), 0x0D);

  cpu.dta_seg = psp_seg;
  cpu.dta_off = 0x0080;

  fsz = fread(&cpu.mem[lin_addr(psp_seg, 0x0100)], 1, 0xFE00, fp);
  fclose(fp);

  if (fsz >= 28 && cpu.mem[lin_addr(psp_seg, 0x0100)] == 'M' && cpu.mem[lin_addr(psp_seg, 0x0101)] == 'Z') {
    /* Relocatable MZ .EXE loader */
    u8 *hdr = &cpu.mem[lin_addr(psp_seg, 0x0100)];
    u16 hdr_paras = (u16)(hdr[8] | (hdr[9] << 8));
    u16 reloc_cnt = (u16)(hdr[6] | (hdr[7] << 8));
    u16 reloc_off = (u16)(hdr[24] | (hdr[25] << 8));
    u16 init_ss = (u16)(hdr[14] | (hdr[15] << 8));
    u16 init_sp = (u16)(hdr[16] | (hdr[17] << 8));
    u16 init_ip = (u16)(hdr[20] | (hdr[21] << 8));
    u16 init_cs = (u16)(hdr[22] | (hdr[23] << 8));
    u16 load_seg = (u16)(psp_seg + 0x0010);
    size_t hdr_bytes = (size_t)hdr_paras * 16U;
    u16 r;
    if (fsz > hdr_bytes) {
      memmove(&cpu.mem[lin_addr(load_seg, 0)], hdr + hdr_bytes, fsz - hdr_bytes);
    }
    for (r = 0; r < reloc_cnt; r++) {
      u16 ro = (u16)(hdr[reloc_off + r * 4] | (hdr[reloc_off + r * 4 + 1] << 8));
      u16 rs = (u16)(hdr[reloc_off + r * 4 + 2] | (hdr[reloc_off + r * 4 + 3] << 8));
      u16 cur = rd16(&cpu, (u16)(load_seg + rs), ro);
      wr16(&cpu, (u16)(load_seg + rs), ro, (u16)(cur + load_seg));
    }
    cpu.ds = psp_seg;
    cpu.es = psp_seg;
    cpu.ss = (u16)(load_seg + init_ss);
    cpu.sp = init_sp;
    cpu.cs = (u16)(load_seg + init_cs);
    cpu.ip = init_ip;
  } else {
    /* Tiny .COM loader */
    cpu.cs = psp_seg;
    cpu.ds = psp_seg;
    cpu.es = psp_seg;
    cpu.ss = psp_seg;
    cpu.sp = 0xFFFE;
    wr16(&cpu, psp_seg, 0xFFFE, 0x0000); /* RET -> PSP:0000 INT 20h */
    cpu.ip = 0x0100;
  }
  cpu.flags = 0x0202;

  while (!cpu.halted && steps < max_steps) {
    step_cpu(&cpu);
    steps++;
  }

  free(cpu.mem);
  return cpu.exit_code;
}
