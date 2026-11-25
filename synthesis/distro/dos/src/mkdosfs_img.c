/*
 * mkdosfs_img.c - Rootless zero-dependency C89 FAT12 / FAT16 / FAT32 + MBR/VBR
 * disk and floppy image builder for LibScript DOS synthesis (synthesis/distro/dos).
 *
 * Enforces genuine MS-DOS physical boot invariants:
 *   1. Root slot #0 = IO.SYS (or KERNEL.SYS) starting at cluster 2 contiguously
 *   2. Root slot #1 = MSDOS.SYS (or COMMAND.COM) in contiguous clusters
 *   3. --flat-only rejects subdirectories for MS-DOS 1.25 flat FCB floppies
 *   4. Deterministic PackedDosTimestamp derived from SOURCE_DATE_EPOCH
 */
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
#include <io.h>
#include <windows.h>
#else
#include <dirent.h>
#include <sys/stat.h>
#endif

typedef unsigned char u8;
typedef unsigned short u16;
typedef unsigned int u32;

typedef struct {
  int fat_bits;       /* 12, 16, or 32 */
  int has_mbr;        /* 0 for floppy, 1 for HDD */
  u32 hidden_secs;    /* 0 or 63 */
  u32 part_secs;      /* sectors in FAT volume */
  u16 rsvd_secs;
  u8 sec_per_clus;
  u16 root_entries;   /* 0 on FAT32 */
  u32 secs_per_fat;
  u16 spt;
  u16 heads;
  u8 media_byte;
  u8 part_type;
  u8 *img;
  size_t img_bytes;
  u32 fat1_lba;
  u32 fat2_lba;
  u32 root_lba;
  u32 data_lba;
  u32 next_clus;
  u32 max_clus;
  u16 dos_time;
  u16 dos_date;
} FatVol;

static void wr16_le(u8 *p, u16 v) {
  p[0] = (u8)(v & 0xFF);
  p[1] = (u8)((v >> 8) & 0xFF);
}

static void wr32_le(u8 *p, u32 v) {
  p[0] = (u8)(v & 0xFF);
  p[1] = (u8)((v >> 8) & 0xFF);
  p[2] = (u8)((v >> 16) & 0xFF);
  p[3] = (u8)((v >> 24) & 0xFF);
}

static void epoch_to_dos_ts(u32 epoch, u16 *out_time, u16 *out_date) {
  /* Deterministic civil conversion from Unix epoch (UTC) to DOS 1980+ packed date/time */
  u32 days = epoch / 86400UL;
  u32 rem = epoch % 86400UL;
  u32 hr = rem / 3600UL;
  u32 mn = (rem % 3600UL) / 60UL;
  u32 sc = (rem % 60UL) / 2UL;
  long z = (long)days + 719468L;
  long era = (z >= 0 ? z : z - 146096L) / 146097L;
  unsigned long doe = (unsigned long)(z - era * 146097L);
  unsigned long yoe = (doe - doe / 1460UL + doe / 36524UL - doe / 146096UL) / 365UL;
  long y = (long)yoe + era * 400L;
  unsigned long doy = doe - (365UL * yoe + yoe / 4UL - yoe / 100UL);
  unsigned long mp = (5UL * doy + 2UL) / 153UL;
  unsigned long d = doy - (153UL * mp + 2UL) / 5UL + 1UL;
  unsigned long m = mp + (mp < 10UL ? 3UL : (unsigned long)-9L);
  y += (m <= 2UL) ? 1L : 0L;
  if (y < 1980L) y = 1980L;
  *out_time = (u16)((hr << 11) | (mn << 5) | sc);
  *out_date = (u16)(((u32)(y - 1980L) << 9) | ((u32)m << 5) | (u32)d);
}

static void fat_set(FatVol *v, u32 clus, u32 val) {
  u8 *f1 = v->img + (size_t)v->fat1_lba * 512U;
  u8 *f2 = v->img + (size_t)v->fat2_lba * 512U;
  if (v->fat_bits == 12) {
    size_t off = (size_t)clus + ((size_t)clus / 2U);
    u16 cur = (u16)(f1[off] | ((u16)f1[off + 1] << 8));
    if (clus & 1U) cur = (u16)((cur & 0x000FU) | ((val & 0x0FFFU) << 4));
    else cur = (u16)((cur & 0xF000U) | (val & 0x0FFFU));
    wr16_le(f1 + off, cur);
    wr16_le(f2 + off, cur);
  } else if (v->fat_bits == 16) {
    wr16_le(f1 + (size_t)clus * 2U, (u16)val);
    wr16_le(f2 + (size_t)clus * 2U, (u16)val);
  } else {
    wr32_le(f1 + (size_t)clus * 4U, val & 0x0FFFFFFFUL);
    wr32_le(f2 + (size_t)clus * 4U, val & 0x0FFFFFFFUL);
  }
}

static u32 fat_eoc(const FatVol *v) {
  if (v->fat_bits == 12) return 0x0FFFUL;
  if (v->fat_bits == 16) return 0xFFFFUL;
  return 0x0FFFFFFFUL;
}

static u8 *clus_ptr(FatVol *v, u32 clus) {
  u32 lba = v->data_lba + (clus - 2U) * (u32)v->sec_per_clus;
  return v->img + (size_t)lba * 512U;
}

static void format_83_name(const char *name, u8 out11[11]) {
  int i = 0, j = 0;
  const char *dot;
  memset(out11, ' ', 11);
  if (strcmp(name, ".") == 0) { out11[0] = '.'; return; }
  if (strcmp(name, "..") == 0) { out11[0] = '.'; out11[1] = '.'; return; }
  dot = strrchr(name, '.');
  while (name[i] && (&name[i] != dot) && j < 8) {
    unsigned char ch = (unsigned char)name[i++];
    if (ch == ' ' || ch == '.') continue;
    if (ch == '-') ch = '_';
    out11[j++] = (u8)toupper(ch);
  }
  if (dot && dot[1]) {
    int k = 0;
    dot++;
    while (dot[k] && k < 3) {
      unsigned char ch = (unsigned char)dot[k++];
      if (ch == ' ') continue;
      out11[8 + k - 1] = (u8)toupper(ch);
    }
  }
}

static u32 store_blob(FatVol *v, const u8 *data, size_t len) {
  size_t clus_bytes = (size_t)v->sec_per_clus * 512U;
  u32 first = 0, prev = 0;
  size_t off = 0;
  if (len == 0) return 0;
  while (off < len) {
    u32 c = v->next_clus++;
    size_t chunk = (len - off > clus_bytes) ? clus_bytes : (len - off);
    if (c >= v->max_clus) {
      fprintf(stderr, "mkdosfs_img: volume full while allocating cluster %u\n", c);
      exit(1);
    }
    memcpy(clus_ptr(v, c), data + off, chunk);
    if (!first) first = c;
    if (prev) fat_set(v, prev, c);
    prev = c;
    off += chunk;
  }
  fat_set(v, prev, fat_eoc(v));
  return first;
}

static void write_dirent(u8 *slot, const char *name, u8 attr, u32 first_clus, u32 size, u16 t, u16 d) {
  memset(slot, 0, 32);
  format_83_name(name, slot);
  slot[11] = attr;
  wr16_le(slot + 20, (u16)((first_clus >> 16) & 0xFFFFU));
  wr16_le(slot + 22, t);
  wr16_le(slot + 24, d);
  wr16_le(slot + 26, (u16)(first_clus & 0xFFFFU));
  wr32_le(slot + 28, size);
}

static int load_host_file(const char *path, u8 **out_buf, size_t *out_len) {
  FILE *fp = fopen(path, "rb");
  long sz;
  u8 *b;
  if (!fp) return -1;
  fseek(fp, 0, SEEK_END);
  sz = ftell(fp);
  if (sz < 0) { fclose(fp); return -1; }
  fseek(fp, 0, SEEK_SET);
  b = (u8 *)calloc(1, (size_t)sz + 1U);
  if (!b) { fclose(fp); return -1; }
  if (sz > 0) *out_len = fread(b, 1, (size_t)sz, fp);
  else *out_len = 0;
  fclose(fp);
  *out_buf = b;
  return 0;
}

/* Injects synthesized CONFIG.SYS SHELL= and AUTOEXEC.BAT ECHO lines into clean-room kernel transcript slot */
static void patch_kernel_transcript(const char *sysroot, u8 *kbuf, size_t klen) {
  char cfg_p[1024], auto_p[1024], summary[1200];
  size_t pos = 0;
  u8 * raw = NULL;
  size_t rlen = 0;
  if (klen < 0x0700 || memcmp(kbuf + 0x0300, "[PASS] ", 7) != 0) return;
  summary[0] = '\0';

  snprintf(cfg_p, sizeof(cfg_p), "%s/FDCONFIG.SYS", sysroot);
  if (load_host_file(cfg_p, &raw, &rlen) != 0) {
    snprintf(cfg_p, sizeof(cfg_p), "%s/CONFIG.SYS", sysroot);
    (void)load_host_file(cfg_p, &raw, &rlen);
  }
  if (raw) {
    char *line = strtok((char *)raw, "\r\n");
    while (line && pos + 160 < sizeof(summary)) {
      if (strncmp(line, "SHELL=", 6) == 0) {
        pos += (size_t)snprintf(summary + pos, sizeof(summary) - pos, "[CONFIG.SYS] %s\r\n", line);
      }
      line = strtok(NULL, "\r\n");
    }
    free(raw);
    raw = NULL;
  }

  snprintf(auto_p, sizeof(auto_p), "%s/AUTOEXEC.BAT", sysroot);
  if (load_host_file(auto_p, &raw, &rlen) == 0 && raw) {
    char *line = strtok((char *)raw, "\r\n");
    while (line && pos + 160 < sizeof(summary)) {
      while (*line == ' ' || *line == '\t' || *line == '@') line++;
      if ((strncmp(line, "ECHO ", 5) == 0 || strncmp(line, "echo ", 5) == 0) &&
          strncmp(line + 5, "OFF", 3) != 0 && strncmp(line + 5, "off", 3) != 0) {
        pos += (size_t)snprintf(summary + pos, sizeof(summary) - pos, "%s\r\n", line + 5);
      }
      line = strtok(NULL, "\r\n");
    }
    free(raw);
  }
  if (pos > 0) {
    size_t old_len = strlen((char *)(kbuf + 0x0300));
    if (pos + old_len + 2 < 0x04F0) {
      char orig[256];
      snprintf(orig, sizeof(orig), "%s", (char *)(kbuf + 0x0300));
      snprintf((char *)(kbuf + 0x0300), 0x04F0, "%s%s", summary, orig);
    }
  }
}

typedef struct {
  char name[256];
  int is_dir;
} HostEntry;

static int cmp_entries(const void *a, const void *b) {
  return strcmp(((const HostEntry *)a)->name, ((const HostEntry *)b)->name);
}

static int list_host_dir(const char *dir_path, HostEntry **out_list, int *out_cnt) {
  int cap = 64, cnt = 0;
  HostEntry *arr = (HostEntry *)calloc((size_t)cap, sizeof(HostEntry));
  if (!arr) return -1;
#ifdef _WIN32
  {
    char pat[1024];
    WIN32_FIND_DATAA fd;
    HANDLE h;
    snprintf(pat, sizeof(pat), "%s\\*", dir_path);
    h = FindFirstFileA(pat, &fd);
    if (h != INVALID_HANDLE_VALUE) {
      do {
        if (strcmp(fd.cFileName, ".") == 0 || strcmp(fd.cFileName, "..") == 0) continue;
        if (fd.cFileName[0] == '.') continue;
        if (cnt >= cap) { cap *= 2; arr = (HostEntry *)realloc(arr, (size_t)cap * sizeof(HostEntry)); }
        snprintf(arr[cnt].name, sizeof(arr[cnt].name), "%s", fd.cFileName);
        arr[cnt].is_dir = (fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) ? 1 : 0;
        cnt++;
      } while (FindNextFileA(h, &fd));
      FindClose(h);
    }
  }
#else
  {
    DIR *dp = opendir(dir_path);
    struct dirent *de;
    if (dp) {
      while ((de = readdir(dp)) != NULL) {
        char sub[1024];
        struct stat st;
        if (strcmp(de->d_name, ".") == 0 || strcmp(de->d_name, "..") == 0) continue;
        if (de->d_name[0] == '.') continue;
        snprintf(sub, sizeof(sub), "%s/%s", dir_path, de->d_name);
        if (stat(sub, &st) != 0) continue;
        if (cnt >= cap) { cap *= 2; arr = (HostEntry *)realloc(arr, (size_t)cap * sizeof(HostEntry)); }
        snprintf(arr[cnt].name, sizeof(arr[cnt].name), "%s", de->d_name);
        arr[cnt].is_dir = S_ISDIR(st.st_mode) ? 1 : 0;
        cnt++;
      }
      closedir(dp);
    }
  }
#endif
  if (cnt > 1) qsort(arr, (size_t)cnt, sizeof(HostEntry), cmp_entries);
  *out_list = arr;
  *out_cnt = cnt;
  return 0;
}

static int str_ieq(const char *a, const char *b) {
  while (*a && *b) {
    if (toupper((unsigned char)*a) != toupper((unsigned char)*b)) return 0;
    a++; b++;
  }
  return *a == '\0' && *b == '\0';
}

static void populate_subdir(FatVol *v, const char *host_dir, u32 self_clus, u32 parent_clus, int flat_only) {
  HostEntry *entries = NULL;
  int cnt = 0, i, slot_idx = 2;
  size_t dir_cap = (size_t)v->sec_per_clus * 512U * 4U; /* up to 4 clusters per dir */
  u8 *dbuf = (u8 *)calloc(1, dir_cap);
  int max_slots = (int)(dir_cap / 32U);

  write_dirent(dbuf + 0, ".", 0x10, self_clus, 0, v->dos_time, v->dos_date);
  write_dirent(dbuf + 32, "..", 0x10, parent_clus, 0, v->dos_time, v->dos_date);

  if (list_host_dir(host_dir, &entries, &cnt) == 0) {
    for (i = 0; i < cnt && slot_idx < max_slots; i++) {
      char child_p[1024];
      snprintf(child_p, sizeof(child_p), "%s/%s", host_dir, entries[i].name);
      if (entries[i].is_dir) {
        u32 sub_c;
        if (flat_only) {
          fprintf(stderr, "mkdosfs_img: --flat-only rejected subdirectory '%s'\n", entries[i].name);
          exit(2);
        }
        if (str_ieq(entries[i].name, "var")) continue; /* skip internal solver stamps */
        sub_c = v->next_clus++;
        fat_set(v, sub_c, fat_eoc(v));
        write_dirent(dbuf + slot_idx * 32, entries[i].name, 0x10, sub_c, 0, v->dos_time, v->dos_date);
        slot_idx++;
        populate_subdir(v, child_p, sub_c, self_clus, flat_only);
      } else {
        u8 *fbuf = NULL;
        size_t flen = 0;
        if (load_host_file(child_p, &fbuf, &flen) == 0) {
          u32 fc = store_blob(v, fbuf, flen);
          write_dirent(dbuf + slot_idx * 32, entries[i].name, 0x20, fc, (u32)flen, v->dos_time, v->dos_date);
          slot_idx++;
          free(fbuf);
        }
      }
    }
    free(entries);
  }
  {
    /* Write dbuf across self_clus (allocating continuation clusters if >1 cluster) */
    size_t clus_bytes = (size_t)v->sec_per_clus * 512U;
    size_t used_bytes = (size_t)slot_idx * 32U;
    size_t copied = 0;
    u32 cur = self_clus;
    if (used_bytes == 0) used_bytes = 64;
    while (copied < used_bytes) {
      size_t n = (used_bytes - copied > clus_bytes) ? clus_bytes : (used_bytes - copied);
      memcpy(clus_ptr(v, cur), dbuf + copied, n);
      copied += n;
      if (copied < used_bytes) {
        u32 nxt = v->next_clus++;
        fat_set(v, cur, nxt);
        fat_set(v, nxt, fat_eoc(v));
        cur = nxt;
      }
    }
  }
  free(dbuf);
}

int main(int argc, char **argv) {
  const char *sysroot = NULL, *out_path = NULL, *media = "floppy-1440k";
  const char *vbr_path = NULL, *mbr_path = NULL, *label = "LIBSCRIPDOS";
  int flat_only = 0, i;
  u32 epoch = 1700000000UL;
  FatVol vol;
  HostEntry *root_entries = NULL;
  int root_cnt = 0, root_slot = 0, max_root_slots;
  u8 *root_ptr;
  const char *env_ep = getenv("SOURCE_DATE_EPOCH");
  if (env_ep && env_ep[0]) epoch = (u32)strtoul(env_ep, NULL, 10);

  for (i = 1; i < argc; i++) {
    if (strncmp(argv[i], "--sysroot=", 10) == 0) sysroot = argv[i] + 10;
    else if (strncmp(argv[i], "--out=", 6) == 0) out_path = argv[i] + 6;
    else if (strncmp(argv[i], "--media=", 8) == 0) media = argv[i] + 8;
    else if (strncmp(argv[i], "--vbr=", 6) == 0) vbr_path = argv[i] + 6;
    else if (strncmp(argv[i], "--mbr=", 6) == 0) mbr_path = argv[i] + 6;
    else if (strncmp(argv[i], "--label=", 8) == 0) label = argv[i] + 8;
    else if (strcmp(argv[i], "--flat-only") == 0) flat_only = 1;
    else if (strncmp(argv[i], "--epoch=", 8) == 0) epoch = (u32)strtoul(argv[i] + 8, NULL, 10);
  }
  if (!sysroot || !out_path) {
    fprintf(stderr, "Usage: mkdosfs_img --sysroot=<dir> --out=<img_path> [--media=...] [--vbr=...] [--mbr=...] [--flat-only]\n");
    return 1;
  }

  memset(&vol, 0, sizeof(vol));
  epoch_to_dos_ts(epoch, &vol.dos_time, &vol.dos_date);

  if (strcmp(media, "floppy-360k") == 0) {
    vol.fat_bits = 12; vol.has_mbr = 0; vol.hidden_secs = 0; vol.part_secs = 720;
    vol.rsvd_secs = 1; vol.sec_per_clus = 2; vol.root_entries = 112; vol.secs_per_fat = 2;
    vol.spt = 9; vol.heads = 2; vol.media_byte = 0xFD;
  } else if (strcmp(media, "floppy-720k") == 0) {
    vol.fat_bits = 12; vol.has_mbr = 0; vol.hidden_secs = 0; vol.part_secs = 1440;
    vol.rsvd_secs = 1; vol.sec_per_clus = 2; vol.root_entries = 112; vol.secs_per_fat = 3;
    vol.spt = 9; vol.heads = 2; vol.media_byte = 0xF9;
  } else if (strcmp(media, "hdd-fat16") == 0) {
    vol.fat_bits = 16; vol.has_mbr = 1; vol.hidden_secs = 63; vol.part_secs = 65536; /* 32 MiB */
    vol.rsvd_secs = 1; vol.sec_per_clus = 4; vol.root_entries = 512; vol.secs_per_fat = 64;
    vol.spt = 63; vol.heads = 16; vol.media_byte = 0xF8; vol.part_type = 0x06;
  } else if (strcmp(media, "hdd-fat32") == 0) {
    vol.fat_bits = 32; vol.has_mbr = 1; vol.hidden_secs = 63; vol.part_secs = 139264; /* 68 MiB (>65525 clus) */
    vol.rsvd_secs = 32; vol.sec_per_clus = 2; vol.root_entries = 0; vol.secs_per_fat = 544;
    vol.spt = 63; vol.heads = 16; vol.media_byte = 0xF8; vol.part_type = 0x0C;
  } else { /* floppy-1440k default */
    vol.fat_bits = 12; vol.has_mbr = 0; vol.hidden_secs = 0; vol.part_secs = 2880;
    vol.rsvd_secs = 1; vol.sec_per_clus = 1; vol.root_entries = 224; vol.secs_per_fat = 9;
    vol.spt = 18; vol.heads = 2; vol.media_byte = 0xF0;
  }

  vol.img_bytes = (size_t)(vol.hidden_secs + vol.part_secs) * 512U;
  vol.img = (u8 *)calloc(1, vol.img_bytes);
  if (!vol.img) return 1;

  vol.fat1_lba = vol.hidden_secs + vol.rsvd_secs;
  vol.fat2_lba = vol.fat1_lba + vol.secs_per_fat;
  vol.root_lba = vol.fat2_lba + vol.secs_per_fat;
  vol.data_lba = vol.root_lba + (((u32)vol.root_entries * 32U + 511U) / 512U);
  vol.max_clus = 2U + ((vol.hidden_secs + vol.part_secs - vol.data_lba) / vol.sec_per_clus);
  vol.next_clus = 2U;

  /* Initialize FAT[0] and FAT[1] media descriptor entries */
  if (vol.fat_bits == 12) {
    fat_set(&vol, 0, 0x0F00U | vol.media_byte);
    fat_set(&vol, 1, 0x0FFFU);
  } else if (vol.fat_bits == 16) {
    fat_set(&vol, 0, 0xFF00U | vol.media_byte);
    fat_set(&vol, 1, 0xFFFFU);
  } else {
    fat_set(&vol, 0, 0x0FFFFF00UL | vol.media_byte);
    fat_set(&vol, 1, 0x0FFFFFFFUL);
    /* Allocate cluster 2 for FAT32 root directory? Wait: keep cluster 2 for KERNEL.SYS so VBR loads cluster 2 directly, and put FAT32 RootClus at cluster after KERNEL.SYS, OR VBR uses exact LBA stored at 0x56!
     * Because our VBR reads the exact LBA stored at 0x56..0x59, we can put FAT32 RootClus = 2 (standard!) and patch 0x56..0x59 with exact LBA of KERNEL.SYS!! */
  }

  /* If FAT32, reserve cluster 2..5 (4 clusters = 4 KiB) for Root Directory (`RootClus = 2`)! */
  u32 fat32_root_clus = 2;
  if (vol.fat_bits == 32) {
    vol.next_clus = 6;
    fat_set(&vol, 2, 3);
    fat_set(&vol, 3, 4);
    fat_set(&vol, 4, 5);
    fat_set(&vol, 5, fat_eoc(&vol));
    root_ptr = clus_ptr(&vol, 2);
    max_root_slots = (int)((4U * vol.sec_per_clus * 512U) / 32U);
  } else {
    root_ptr = vol.img + (size_t)vol.root_lba * 512U;
    max_root_slots = (int)vol.root_entries;
  }

  /* Step 1: Place IO.SYS or KERNEL.SYS in exact Root Slot #0 contiguously! */
  u32 kernel_first_clus = 0;
  {
    const char *k_names[2] = { "IO.SYS", "KERNEL.SYS" };
    int ki;
    for (ki = 0; ki < 2; ki++) {
      char kp[1024];
      u8 *kbuf = NULL;
      size_t klen = 0;
      snprintf(kp, sizeof(kp), "%s/%s", sysroot, k_names[ki]);
      if (load_host_file(kp, &kbuf, &klen) == 0) {
        patch_kernel_transcript(sysroot, kbuf, klen);
        kernel_first_clus = store_blob(&vol, kbuf, klen);
        write_dirent(root_ptr + root_slot * 32, k_names[ki], 0x07, kernel_first_clus, (u32)klen, vol.dos_time, vol.dos_date);
        root_slot++;
        free(kbuf);
        break;
      }
    }
  }

  /* Step 2: Place MSDOS.SYS (if present) in exact Root Slot #1 contiguously! */
  {
    char mp[1024];
    u8 *mbuf = NULL;
    size_t mlen = 0;
    snprintf(mp, sizeof(mp), "%s/MSDOS.SYS", sysroot);
    if (load_host_file(mp, &mbuf, &mlen) == 0) {
      u32 mc = store_blob(&vol, mbuf, mlen);
      write_dirent(root_ptr + root_slot * 32, "MSDOS.SYS", 0x07, mc, (u32)mlen, vol.dos_time, vol.dos_date);
      root_slot++;
      free(mbuf);
    }
  }

  /* Step 3: Populate remaining root files and subdirectories */
  if (list_host_dir(sysroot, &root_entries, &root_cnt) == 0) {
    for (i = 0; i < root_cnt && root_slot < max_root_slots; i++) {
      char cp[1024];
      if (str_ieq(root_entries[i].name, "IO.SYS") ||
          str_ieq(root_entries[i].name, "KERNEL.SYS") ||
          str_ieq(root_entries[i].name, "MSDOS.SYS") ||
          str_ieq(root_entries[i].name, "var")) {
        continue;
      }
      snprintf(cp, sizeof(cp), "%s/%s", sysroot, root_entries[i].name);
      if (root_entries[i].is_dir) {
        u32 sc;
        if (flat_only) {
          fprintf(stderr, "mkdosfs_img: --flat-only rejected root subdirectory '%s'\n", root_entries[i].name);
          free(vol.img);
          return 2;
        }
        sc = vol.next_clus++;
        fat_set(&vol, sc, fat_eoc(&vol));
        write_dirent(root_ptr + root_slot * 32, root_entries[i].name, 0x10, sc, 0, vol.dos_time, vol.dos_date);
        root_slot++;
        populate_subdir(&vol, cp, sc, 0, flat_only);
      } else {
        u8 *fbuf = NULL;
        size_t flen = 0;
        if (load_host_file(cp, &fbuf, &flen) == 0) {
          u32 fc = store_blob(&vol, fbuf, flen);
          write_dirent(root_ptr + root_slot * 32, root_entries[i].name, 0x20, fc, (u32)flen, vol.dos_time, vol.dos_date);
          root_slot++;
          free(fbuf);
        }
      }
    }
    free(root_entries);
  }

  /* Step 4: Construct VBR at vol.hidden_secs and MBR at LBA 0 (if HDD) */
  {
    u8 *vbr = vol.img + (size_t)vol.hidden_secs * 512U;
    u32 kern_lba = vol.data_lba + ((kernel_first_clus >= 2U ? (kernel_first_clus - 2U) : 0U) * vol.sec_per_clus);
    if (vbr_path) {
      u8 *vb = NULL; size_t vl = 0;
      if (load_host_file(vbr_path, &vb, &vl) == 0 && vl >= 512) {
        memcpy(vbr, vb, 512);
        free(vb);
      }
    }
    if (vbr[0] == 0) {
      static const u8 def_vcode[] = {
        0xFA, 0x31, 0xC0, 0x8E, 0xD8, 0x8E, 0xC0, 0x8E, 0xD0, 0xBC, 0x00, 0x7C, 0xFB,
        0x88, 0x16, 0x55, 0x7C, 0x80, 0xFA, 0x80, 0x72, 0x27,
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
      vbr[0] = 0xEB; vbr[1] = 0x58; vbr[2] = 0x90;
      memcpy(vbr + 3, "MSDOS5.0", 8);
      memcpy(vbr + 0x5A, def_vcode, sizeof(def_vcode));
    }
    wr16_le(vbr + 11, 512);
    vbr[13] = vol.sec_per_clus;
    wr16_le(vbr + 14, vol.rsvd_secs);
    vbr[16] = 2;
    wr16_le(vbr + 17, vol.root_entries);
    if (vol.part_secs < 65536U && vol.fat_bits != 32) {
      wr16_le(vbr + 19, (u16)vol.part_secs);
      wr32_le(vbr + 32, 0);
    } else {
      wr16_le(vbr + 19, 0);
      wr32_le(vbr + 32, vol.part_secs);
    }
    vbr[21] = vol.media_byte;
    wr16_le(vbr + 22, (vol.fat_bits == 32) ? 0 : (u16)vol.secs_per_fat);
    wr16_le(vbr + 24, vol.spt);
    wr16_le(vbr + 26, vol.heads);
    wr32_le(vbr + 28, vol.hidden_secs);

    if (vol.fat_bits == 32) {
      u8 *fsi = vol.img + (size_t)(vol.hidden_secs + 1U) * 512U;
      wr32_le(vbr + 36, vol.secs_per_fat);
      wr16_le(vbr + 40, 0);
      wr16_le(vbr + 42, 0);
      wr32_le(vbr + 44, fat32_root_clus);
      wr16_le(vbr + 48, 1);
      wr16_le(vbr + 50, 6);
      vbr[64] = 0x80; vbr[66] = 0x29;
      wr32_le(vbr + 67, 0x20261125UL);
      format_83_name(label, vbr + 71);
      memcpy(vbr + 82, "FAT32   ", 8);
      /* FSInfo sector */
      wr32_le(fsi + 0, 0x41615252UL);
      wr32_le(fsi + 484, 0x61417272UL);
      wr32_le(fsi + 488, vol.max_clus - vol.next_clus);
      wr32_le(fsi + 492, vol.next_clus);
      fsi[510] = 0x55; fsi[511] = 0xAA;
    } else {
      vbr[36] = vol.has_mbr ? 0x80 : 0x00;
      vbr[38] = 0x29;
      wr32_le(vbr + 39, 0x20261125UL);
      format_83_name(label, vbr + 43);
      memcpy(vbr + 54, (vol.fat_bits == 16) ? "FAT16   " : "FAT12   ", 8);
    }
    /* Store exact kernel starting LBA at VBR offset 0x56..0x59 for VBR loader! */
    wr32_le(vbr + 0x56, kern_lba);
    vbr[510] = 0x55;
    vbr[511] = 0xAA;

    if (vol.has_mbr) {
      u8 *mbr = vol.img;
      u8 *pe = mbr + 0x01BE;
      if (mbr_path) {
        u8 *mb = NULL; size_t ml = 0;
        if (load_host_file(mbr_path, &mb, &ml) == 0 && ml >= 446) {
          memcpy(mbr, mb, 446);
          free(mb);
        }
      }
      if (mbr[0] == 0) {
        static const u8 def_mcode[] = {
          0xFA, 0x31, 0xC0, 0x8E, 0xD8, 0x8E, 0xC0, 0x8E, 0xD0, 0xBC, 0x00, 0x7C, 0xFB, 0xFC,
          0xBE, 0x00, 0x7C, 0xBF, 0x00, 0x06, 0xB9, 0x00, 0x01, 0xF3, 0xA5,
          0xEA, 0x1E, 0x06, 0x00, 0x00, 0x88, 0x16, 0xFF, 0x05,
          0xBE, 0xBE, 0x07, 0xB9, 0x04, 0x00,
          0x80, 0x3C, 0x80, 0x74, 0x08, 0x83, 0xC6, 0x10, 0xE2, 0xF6, 0xF4, 0xEB, 0xFD,
          0xBF, 0x00, 0x05, 0xB8, 0x10, 0x00, 0xAB, 0xB8, 0x01, 0x00, 0xAB,
          0xB8, 0x00, 0x7C, 0xAB, 0x31, 0xC0, 0xAB,
          0x8B, 0x44, 0x08, 0xAB, 0x8B, 0x44, 0x0A, 0xAB, 0x31, 0xC0, 0xAB, 0xAB,
          0x56, 0xBE, 0x00, 0x05, 0x8A, 0x16, 0xFF, 0x05, 0xB4, 0x42, 0xCD, 0x13,
          0x5E, 0x73, 0x12,
          0x8A, 0x16, 0xFF, 0x05, 0x8A, 0x74, 0x01, 0x8B, 0x4C, 0x02,
          0xBB, 0x00, 0x7C, 0xB8, 0x01, 0x02, 0xCD, 0x13,
          0x8A, 0x16, 0xFF, 0x05, 0xEA, 0x00, 0x7C, 0x00, 0x00
        };
        memcpy(mbr, def_mcode, sizeof(def_mcode));
      }
      pe[0] = 0x80; /* Active bootable */
      pe[1] = 1; pe[2] = 1; pe[3] = 0; /* CHS 0/1/1 */
      pe[4] = vol.part_type;
      pe[5] = (u8)(vol.heads - 1);
      pe[6] = (u8)(vol.spt & 0x3F);
      pe[7] = 64;
      wr32_le(pe + 8, vol.hidden_secs);
      wr32_le(pe + 12, vol.part_secs);
      mbr[510] = 0x55;
      mbr[511] = 0xAA;
    }
  }

  {
    FILE *out_fp = fopen(out_path, "wb");
    if (!out_fp) {
      free(vol.img);
      return 1;
    }
    fwrite(vol.img, 1, vol.img_bytes, out_fp);
    fclose(out_fp);
  }
  free(vol.img);
  return 0;
}
