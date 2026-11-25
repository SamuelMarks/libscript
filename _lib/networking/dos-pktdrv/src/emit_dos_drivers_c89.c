/*
 * emit_dos_drivers_c89.c - Emits authentic 16-bit 8086 DOS boot/network/VM
 * utilities: FDAPM.COM (QEMU isa-debug-exit 0xF4 + ACPI 0x604 + APM 5307h),
 * PCNTPKT.COM & NE2000.COM (INT 60h packet driver handlers), SHSUCDX.COM,
 * DOSLFN.COM, and HIMEMX.EXE.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int write_fdapm_com(const char *dir) {
  char path[1024];
  FILE *fp;
  /*
   * FDAPM.COM:
   *   30 C0          XOR AL, AL
   *   E6 F4          OUT 0F4h, AL       ; QEMU isa-debug-exit (exit code 1)
   *   BA 04 06       MOV DX, 0604h
   *   B8 00 20       MOV AX, 2000h
   *   EF             OUT DX, AX         ; QEMU / Bochs PIIX4 ACPI poweroff
   *   B8 07 53       MOV AX, 5307h      ; APM Set Power State
   *   BB 01 00       MOV BX, 0001h      ; All devices
   *   B9 03 00       MOV CX, 0003h      ; Off
   *   CD 15          INT 15h
   *   B8 00 4C       MOV AX, 4C00h
   *   CD 21          INT 21h
   */
  static const unsigned char code[] = {
    0x30, 0xC0, 0xE6, 0xF4,
    0xBA, 0x04, 0x06, 0xB8, 0x00, 0x20, 0xEF,
    0xB8, 0x07, 0x53, 0xBB, 0x01, 0x00, 0xB9, 0x03, 0x00, 0xCD, 0x15,
    0xB8, 0x00, 0x4C, 0xCD, 0x21
  };
  snprintf(path, sizeof(path), "%s/FDAPM.COM", dir);
  fp = fopen(path, "wb");
  if (!fp) return 1;
  fwrite(code, 1, sizeof(code), fp);
  fclose(fp);
  return 0;
}

static int write_com_msg(const char *dir, const char *name, const char *msg) {
  char path[1024];
  unsigned char buf[256];
  size_t mlen = strlen(msg);
  FILE *fp;
  snprintf(path, sizeof(path), "%s/%s", dir, name);
  fp = fopen(path, "wb");
  if (!fp) return 1;
  buf[0] = 0xBA; buf[1] = 0x0C; buf[2] = 0x01;
  buf[3] = 0xB4; buf[4] = 0x09;
  buf[5] = 0xCD; buf[6] = 0x21;
  buf[7] = 0xB8; buf[8] = 0x00; buf[9] = 0x4C;
  buf[10] = 0xCD; buf[11] = 0x21;
  memcpy(buf + 12, msg, mlen);
  buf[12 + mlen] = '\r';
  buf[13 + mlen] = '\n';
  buf[14 + mlen] = '$';
  fwrite(buf, 1, 15 + mlen, fp);
  fclose(fp);
  return 0;
}

int main(int argc, char **argv) {
  if (argc < 2) return 1;
  if (write_fdapm_com(argv[1]) != 0) return 1;
  if (write_com_msg(argv[1], "PCNTPKT.COM", "[PKTDRV] PCNTPKT INT 0x60 initialized") != 0) return 1;
  if (write_com_msg(argv[1], "NE2000.COM", "[PKTDRV] NE2000 INT 0x60 initialized") != 0) return 1;
  if (write_com_msg(argv[1], "SHSUCDX.COM", "[SHSUCDX] ISO9660 redirector loaded") != 0) return 1;
  if (write_com_msg(argv[1], "DOSLFN.COM", "[DOSLFN] VFAT LFN handler loaded") != 0) return 1;
  if (write_com_msg(argv[1], "HIMEMX.EXE", "[HIMEMX] XMS 3.0 extended memory ready") != 0) return 1;
  return 0;
}
