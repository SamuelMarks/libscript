/*
 * ## Overview
 * Portable 40-line ANSI C89 Portable Executable (PE) COFF Machine header inspector.
 * Replaces PowerShell [IO.File]::ReadAllBytes PE inspection in ReactOS/Windows packaging.
 *
 * ## Usage
 * ls-pe-arch <binary_path> [expected_arch]
 */

#include <stdio.h>
#include <string.h>

static const char *normalize_arch(const char *a) {
    if (a == NULL || a[0] == '\0') return "";
    if (strcmp(a, "amd64") == 0 || strcmp(a, "x86_64") == 0 || strcmp(a, "X64") == 0) return "x86_64";
    if (strcmp(a, "i686") == 0 || strcmp(a, "i386") == 0 || strcmp(a, "x86") == 0 || strcmp(a, "X86") == 0) return "i686";
    if (strcmp(a, "arm64") == 0 || strcmp(a, "aarch64") == 0 || strcmp(a, "ARM64") == 0) return "arm64";
    return a;
}

int main(int argc, char **argv) {
    unsigned char mz[64];
    unsigned char pe[6];
    unsigned long pe_off;
    unsigned int machine;
    const char *detected = "non-pe";
    FILE *fp;

    if (argc < 2) return 2;
    fp = fopen(argv[1], "rb");
    if (fp == NULL) return 2;
    if (fread(mz, 1, 64, fp) == 64 && mz[0] == 0x4D && mz[1] == 0x5A) {
        pe_off = (unsigned long)mz[0x3C]
               | ((unsigned long)mz[0x3D] << 8)
               | ((unsigned long)mz[0x3E] << 16)
               | ((unsigned long)mz[0x3F] << 24);
        if (fseek(fp, (long)pe_off, SEEK_SET) == 0 && fread(pe, 1, 6, fp) == 6 &&
            pe[0] == 0x50 && pe[1] == 0x45 && pe[2] == 0x00 && pe[3] == 0x00) {
            machine = (unsigned int)pe[4] | ((unsigned int)pe[5] << 8);
            if (machine == 0x014CU) detected = "i686";
            else if (machine == 0x8664U) detected = "x86_64";
            else if (machine == 0xAA64U) detected = "arm64";
            else detected = "other";
        }
    }
    fclose(fp);
    printf("%s\n", detected);
    if (argc >= 3 && argv[2][0] != '\0' && strcmp(detected, "non-pe") != 0) {
        return (strcmp(detected, normalize_arch(argv[2])) == 0) ? 0 : 1;
    }
    return 0;
}
