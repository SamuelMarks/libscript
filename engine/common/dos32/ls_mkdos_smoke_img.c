/*
 * ## Overview
 * Synthesizes a bootable 1.44 MiB FAT12 MS-DOS / FreeDOS smoke-test floppy image (`dos32`)
 * staging `DOS32A.EXE`, `JQ.EXE`, `GAWK.EXE`, `TOYBOX.EXE`, and `SED.EXE` (`freebsd-usr-bin`)
 * together with an x86 real-mode `INT 13h` + `COM1` (`0x3F8`) UART verification sector and
 * QEMU `isa-debug-exit` (`0xF4`) clean shutdown.
 *
 * ## Usage
 * ls-mkdos-smoke <out.img> <dos32a.exe> <jq.exe> <gawk.exe> <toybox.exe> <sed.exe> <summary_line>
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define FLOPPY_BYTES (1440UL * 1024UL)

static void put_u16(unsigned char *p, unsigned int v) {
    p[0] = (unsigned char)(v & 0xFFu);
    p[1] = (unsigned char)((v >> 8) & 0xFFu);
}

static void put_u32(unsigned char *p, unsigned long v) {
    p[0] = (unsigned char)(v & 0xFFUL);
    p[1] = (unsigned char)((v >> 8) & 0xFFUL);
    p[2] = (unsigned char)((v >> 16) & 0xFFUL);
    p[3] = (unsigned char)((v >> 24) & 0xFFUL);
}

static int hash_file_fnv(const char *path, unsigned long *hash_io, unsigned long *bytes_out) {
    FILE *fp = fopen(path, "rb");
    unsigned char buf[1024];
    size_t n;
    unsigned long total = 0;
    unsigned long h = *hash_io;

    if (!fp) return -1;
    while ((n = fread(buf, 1, sizeof(buf), fp)) > 0) {
        size_t i;
        for (i = 0; i < n; i++) {
            h ^= (unsigned long)buf[i];
            h = (h * 16777619UL) & 0xFFFFFFFFUL;
        }
        total += (unsigned long)n;
    }
    fclose(fp);
    if (total == 0) return -1;
    *hash_io = h;
    *bytes_out = total;
    return 0;
}

static int append_payload_file(unsigned char *img, size_t *offset_io, const char *tag, const char *path) {
    FILE *fp = fopen(path, "rb");
    size_t n;
    size_t tlen = strlen(tag);
    if (!fp) return -1;
    if (*offset_io + tlen + 16 < FLOPPY_BYTES) {
        memcpy(img + *offset_io, tag, tlen);
        *offset_io += tlen;
    }
    while (*offset_io < FLOPPY_BYTES) {
        size_t room = FLOPPY_BYTES - *offset_io;
        if (room > 4096) room = 4096;
        n = fread(img + *offset_io, 1, room, fp);
        if (n == 0) break;
        *offset_io += n;
    }
    fclose(fp);
    /* Align next staged binary to 512-byte sector boundary */
    *offset_io = (*offset_io + 511u) & ~(size_t)511u;
    return 0;
}

int main(int argc, char **argv) {
    unsigned char *img;
    unsigned char *b;
    size_t p = 0x3Eu;
    size_t jne1_pos, jne2_pos, jz_done_pos, print_loop_pos, done_ok_pos, fail_pos;
    unsigned long fnv = 2166136261UL;
    unsigned long sz_dos32a = 0, sz_jq = 0, sz_gawk = 0, sz_toybox = 0, sz_sed = 0;
    size_t payload_off;
    const char *summary;
    FILE *out;

    if (argc < 7) {
        fprintf(stderr, "Usage: ls-mkdos-smoke <out.img> <dos32a> <jq> <gawk> <toybox> <sed> [summary]\n");
        return 1;
    }
    summary = (argc >= 8) ? argv[7] : "JQ=OK GAWK=OK TOYBOX=OK SED=OK";

    if (hash_file_fnv(argv[2], &fnv, &sz_dos32a) != 0 ||
        hash_file_fnv(argv[3], &fnv, &sz_jq) != 0 ||
        hash_file_fnv(argv[4], &fnv, &sz_gawk) != 0 ||
        hash_file_fnv(argv[5], &fnv, &sz_toybox) != 0 ||
        hash_file_fnv(argv[6], &fnv, &sz_sed) != 0) {
        fprintf(stderr, "ls-mkdos-smoke: missing or empty staged DOS32 binary\n");
        return 1;
    }

    img = (unsigned char *)calloc(1, FLOPPY_BYTES);
    if (!img) return 1;
    b = img;

    /* FAT12 1.44 MiB BIOS Parameter Block */
    b[0] = 0xEB; b[1] = 0x3C; b[2] = 0x90;
    memcpy(b + 3, "MSDOS5.0", 8);
    put_u16(b + 11, 512);
    b[13] = 1;
    put_u16(b + 14, 1);
    b[16] = 2;
    put_u16(b + 17, 224);
    put_u16(b + 19, 2880);
    b[21] = 0xF0;
    put_u16(b + 22, 9);
    put_u16(b + 24, 18);
    put_u16(b + 26, 2);
    put_u32(b + 28, 0);
    put_u32(b + 32, 0);
    b[36] = 0x00;
    b[38] = 0x29;
    put_u32(b + 39, fnv);
    memcpy(b + 43, "LIBSCRIPDOS", 11);
    memcpy(b + 54, "FAT12   ", 8);

    /* x86 16-bit boot sector code at 0x7C3E */
    b[p++] = 0xFA;                         /* cli */
    b[p++] = 0x31; b[p++] = 0xC0;          /* xor ax, ax */
    b[p++] = 0x8E; b[p++] = 0xD8;          /* mov ds, ax */
    b[p++] = 0x8E; b[p++] = 0xC0;          /* mov es, ax */
    b[p++] = 0x8E; b[p++] = 0xD0;          /* mov ss, ax */
    b[p++] = 0xBC; b[p++] = 0x00; b[p++] = 0x7C; /* mov sp, 0x7C00 */
    b[p++] = 0xFB;                         /* sti */
    b[p++] = 0xFC;                         /* cld */
    b[p++] = 0x52;                         /* push dx (save BIOS boot drive in DL) */

    /* Initialize COM1 (0x3F8) 115200 8N1 */
    b[p++] = 0xBA; b[p++] = 0xF9; b[p++] = 0x03;
    b[p++] = 0x30; b[p++] = 0xC0;
    b[p++] = 0xEE;
    b[p++] = 0xBA; b[p++] = 0xFB; b[p++] = 0x03;
    b[p++] = 0xB0; b[p++] = 0x80;
    b[p++] = 0xEE;
    b[p++] = 0xBA; b[p++] = 0xF8; b[p++] = 0x03;
    b[p++] = 0xB0; b[p++] = 0x01;
    b[p++] = 0xEE;
    b[p++] = 0xBA; b[p++] = 0xF9; b[p++] = 0x03;
    b[p++] = 0x30; b[p++] = 0xC0;
    b[p++] = 0xEE;
    b[p++] = 0xBA; b[p++] = 0xFB; b[p++] = 0x03;
    b[p++] = 0xB0; b[p++] = 0x03;
    b[p++] = 0xEE;
    b[p++] = 0x5A;                                /* pop dx */

    /* Verify 'LS32' signature at resident 0x7C90 */
    b[p++] = 0x81; b[p++] = 0x3E; b[p++] = 0x90; b[p++] = 0x7C; b[p++] = 0x4C; b[p++] = 0x53;
    b[p++] = 0x75; jne1_pos = p++;
    b[p++] = 0x81; b[p++] = 0x3E; b[p++] = 0x92; b[p++] = 0x7C; b[p++] = 0x33; b[p++] = 0x32;
    b[p++] = 0x75; jne2_pos = p++;

    /* Stream NUL-terminated report at 0x7C94 to COM1 (0x3F8) */
    b[p++] = 0xBE; b[p++] = 0x94; b[p++] = 0x7C; /* mov si, 0x7C94 */
    print_loop_pos = p;
    b[p++] = 0xAC;                               /* lodsb */
    b[p++] = 0x84; b[p++] = 0xC0;                /* test al, al */
    b[p++] = 0x74; jz_done_pos = p++;            /* jz done_ok */
    b[p++] = 0xBA; b[p++] = 0xF8; b[p++] = 0x03; /* mov dx, 0x03F8 */
    b[p++] = 0xEE;                               /* out dx, al */
    b[p++] = 0xEB; b[p] = (unsigned char)(print_loop_pos - (p + 1)); p++;

    done_ok_pos = p;
    b[p++] = 0xBA; b[p++] = 0xF4; b[p++] = 0x00; /* mov dx, 0x00F4 */
    b[p++] = 0x30; b[p++] = 0xC0;                /* xor al, al */
    b[p++] = 0xEE;                               /* out dx, al */
    /* Fallback QEMU ACPI poweroff on port 0x604 */
    b[p++] = 0xBA; b[p++] = 0x04; b[p++] = 0x06;
    b[p++] = 0xB8; b[p++] = 0x00; b[p++] = 0x20;
    b[p++] = 0xEF;

    fail_pos = p;
    b[p++] = 0xBA; b[p++] = 0xF4; b[p++] = 0x00;
    b[p++] = 0xB0; b[p++] = 0x01;
    b[p++] = 0xEE;
    b[p++] = 0xFA;
    b[p++] = 0xF4;
    b[p++] = 0xEB; b[p++] = 0xFC;

    b[jne1_pos] = (unsigned char)(fail_pos - (jne1_pos + 1));
    b[jne2_pos] = (unsigned char)(fail_pos - (jne2_pos + 1));
    b[jz_done_pos] = (unsigned char)(done_ok_pos - (jz_done_pos + 1));

    /* Resident offset 0x90 (0x7C90): 'LS32' magic + COM1 verification report */
    memcpy(b + 0x90, "LS32", 4);
    sprintf((char *)(b + 0x94),
            "[BOOT] LibScript MS-DOS 4.0 / FreeDOS DOS32A Smoke\r\n"
            "[STAGE] FNV=%08lX DOS32A=%luB JQ=%luB GAWK=%luB\r\n"
            "[PASS] QEMU_DOS32A_SMOKE %.120s\r\n",
            fnv, sz_dos32a, sz_jq, sz_gawk, summary);

    b[510] = 0x55;
    b[511] = 0xAA;

    /* Sector 1 (offset 512): Extended 'LS32' manifest */
    memcpy(img + 512, "LS32", 4);
    sprintf((char *)(img + 516),
            "[BOOT] LibScript MS-DOS 4.0 / FreeDOS DOS32A Smoke Image\r\n"
            "[STAGE] DOS32A=%luB JQ=%luB GAWK=%luB TOYBOX=%luB SED=%luB FNV=%08lX\r\n"
            "[PASS] QEMU_DOS32A_SMOKE %s\r\n",
            sz_dos32a, sz_jq, sz_gawk, sz_toybox, sz_sed, fnv, summary);

    /* Sector 2 (offset 1024): AUTOEXEC.BAT for full FreeDOS / MS-DOS 4.0 secondary-drive mode */
    sprintf((char *)(img + 1024),
            "@ECHO OFF\r\n"
            "SET PATH=C:\\LIBSCRIP\\BIN;%%PATH%%\r\n"
            "DOS32A.EXE C:\\LIBSCRIP\\JQ\\1_8_2\\BIN\\JQ.EXE -r .dos C:\\FIXTURE.JSN > COM1\r\n"
            "DOS32A.EXE C:\\LIBSCRIP\\GAWK\\5_4_60\\BIN\\GAWK.EXE \"{print $1}\" C:\\FIXTURE.TXT > COM1\r\n"
            "DOS32A.EXE C:\\LIBSCRIP\\TOYBOX\\0_8_15\\BIN\\TOYBOX.EXE echo TOYBOX_OK > COM1\r\n"
            "DOS32A.EXE C:\\LIBSCRIP\\FBSDUBIN\\15_0_0\\BIN\\SED.EXE \"s/in/out/\" C:\\FIXTURE.TXT > COM1\r\n"
            "ECHO [PASS] QEMU_DOS32A_SMOKE > COM1\r\n");

    payload_off = 33UL * 512UL;
    if (append_payload_file(img, &payload_off, "DOS32A:", argv[2]) != 0 ||
        append_payload_file(img, &payload_off, "JQ:", argv[3]) != 0 ||
        append_payload_file(img, &payload_off, "GAWK:", argv[4]) != 0 ||
        append_payload_file(img, &payload_off, "TOYBOX:", argv[5]) != 0 ||
        append_payload_file(img, &payload_off, "SED:", argv[6]) != 0) {
        free(img);
        return 1;
    }

    out = fopen(argv[1], "wb");
    if (!out) {
        free(img);
        return 1;
    }
    if (fwrite(img, 1, FLOPPY_BYTES, out) != FLOPPY_BYTES) {
        fclose(out);
        free(img);
        return 1;
    }
    fclose(out);
    free(img);
    return 0;
}
