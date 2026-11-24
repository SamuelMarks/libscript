/**
 * ## Overview
 * Pure C11 zero-dependency UEFI PE32/PE32+ Unified Kernel Image (UKI) bundler and
 * Authenticode WIN_CERTIFICATE (Data Directory #4) Secure Boot signature injector.
 *
 * ## Usage
 * uki_c_packer <out.efi> <arch> <osrel_file> <cmdline_file> <kernel_file> <initrd_file> [sig_file]
 */

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define FILE_ALIGN 0x200U
#define SECT_ALIGN 0x1000U
#define EFI_SUBSYSTEM_APPLICATION 10U

static uint32_t align_up(uint32_t val, uint32_t align) {
    return (val + align - 1U) & ~(align - 1U);
}

static void put_le16(uint8_t *p, uint16_t v) {
    p[0] = (uint8_t)(v & 0xffU);
    p[1] = (uint8_t)((v >> 8U) & 0xffU);
}

static void put_le32(uint8_t *p, uint32_t v) {
    p[0] = (uint8_t)(v & 0xffU);
    p[1] = (uint8_t)((v >> 8U) & 0xffU);
    p[2] = (uint8_t)((v >> 16U) & 0xffU);
    p[3] = (uint8_t)((v >> 24U) & 0xffU);
}

static void put_le64(uint8_t *p, uint64_t v) {
    put_le32(p, (uint32_t)(v & 0xffffffffULL));
    put_le32(p + 4, (uint32_t)((v >> 32U) & 0xffffffffULL));
}

static uint8_t *slurp_file(const char *path, uint32_t *out_len) {
    FILE *fp = fopen(path, "rb");
    if (fp == NULL) {
        *out_len = 0U;
        return NULL;
    }
    if (fseek(fp, 0, SEEK_END) != 0) {
        fclose(fp);
        *out_len = 0U;
        return NULL;
    }
    long sz = ftell(fp);
    if (sz < 0) {
        fclose(fp);
        *out_len = 0U;
        return NULL;
    }
    if (fseek(fp, 0, SEEK_SET) != 0) {
        fclose(fp);
        *out_len = 0U;
        return NULL;
    }
    size_t alloc_sz = (sz == 0) ? 1U : (size_t)sz;
    uint8_t *buf = (uint8_t *)calloc(1U, alloc_sz);
    if (buf == NULL) {
        fclose(fp);
        *out_len = 0U;
        return NULL;
    }
    if (sz > 0) {
        size_t got = fread(buf, 1U, (size_t)sz, fp);
        *out_len = (uint32_t)got;
    } else {
        *out_len = 0U;
    }
    fclose(fp);
    return buf;
}

typedef struct {
    char name[8];
    uint8_t *data;
    uint32_t raw_len;
    uint32_t aligned_raw_len;
    uint32_t file_off;
    uint32_t rva;
    uint32_t vsize;
} uki_sect_t;

int main(int argc, char **argv) {
    if (argc < 7 || strcmp(argv[1], "--help") == 0 || strcmp(argv[1], "-h") == 0) {
        fprintf((argc >= 2 && (strcmp(argv[1], "--help") == 0 || strcmp(argv[1], "-h") == 0)) ? stdout : stderr,
                "Usage: %s <out.efi> <arch> <osrel> <cmdline> <linux> <initrd> [sig]\n", argv[0]);
        return (argc >= 2 && (strcmp(argv[1], "--help") == 0 || strcmp(argv[1], "-h") == 0)) ? 0 : 1;
    }

    const char *out_path = argv[1];
    const char *arch = argv[2];
    uint16_t machine = 0x8664U;
    int is_pe32_plus = 1;

    if (strcmp(arch, "aarch64") == 0 || strcmp(arch, "arm64") == 0) {
        machine = 0xaa64U;
    } else if (strcmp(arch, "riscv64") == 0) {
        machine = 0x5064U;
    } else if (strcmp(arch, "i686") == 0 || strcmp(arch, "i386") == 0 || strcmp(arch, "x86") == 0) {
        machine = 0x014cU;
        is_pe32_plus = 0;
    }

    uki_sect_t sects[4];
    memset(sects, 0, sizeof(sects));
    memcpy(sects[0].name, ".osrel\0\0", 8);
    memcpy(sects[1].name, ".cmdline", 8);
    memcpy(sects[2].name, ".linux\0\0", 8);
    memcpy(sects[3].name, ".initrd\0", 8);

    for (int i = 0; i < 4; i++) {
        sects[i].data = slurp_file(argv[3 + i], &sects[i].raw_len);
        if (sects[i].data == NULL) {
            fprintf(stderr, "Failed to read input section file: %s\n", argv[3 + i]);
            for (int j = 0; j < i; j++) {
                free(sects[j].data);
            }
            return 1;
        }
        uint32_t non_empty = (sects[i].raw_len == 0U) ? 1U : sects[i].raw_len;
        sects[i].aligned_raw_len = align_up(non_empty, FILE_ALIGN);
        sects[i].vsize = non_empty;
    }

    uint32_t sig_raw_len = 0U;
    uint8_t *sig_data = NULL;
    if (argc >= 8 && argv[7][0] != '\0') {
        sig_data = slurp_file(argv[7], &sig_raw_len);
    }

    uint16_t opt_hdr_size = is_pe32_plus ? 240U : 224U;
    uint32_t pe_off = 0x80U;
    uint32_t sect_tbl_off = pe_off + 4U + 20U + (uint32_t)opt_hdr_size;
    uint32_t hdrs_end = sect_tbl_off + (4U * 40U);
    uint32_t size_of_headers = align_up(hdrs_end, FILE_ALIGN);

    uint32_t cur_foff = size_of_headers;
    uint32_t cur_rva = SECT_ALIGN;
    for (int i = 0; i < 4; i++) {
        sects[i].file_off = cur_foff;
        sects[i].rva = cur_rva;
        cur_foff += sects[i].aligned_raw_len;
        cur_rva += align_up(sects[i].vsize, SECT_ALIGN);
    }
    uint32_t size_of_image = cur_rva;

    uint32_t cert_foff = 0U;
    uint32_t cert_total_len = 0U;
    if (sig_data != NULL && sig_raw_len > 0U) {
        cert_foff = align_up(cur_foff, 8U);
        cert_total_len = align_up(8U + sig_raw_len, 8U);
    }
    uint32_t total_file_size = (cert_total_len > 0U) ? (cert_foff + cert_total_len) : cur_foff;

    uint8_t *img = (uint8_t *)calloc(1U, total_file_size);
    if (img == NULL) {
        for (int i = 0; i < 4; i++) {
            free(sects[i].data);
        }
        free(sig_data);
        return 1;
    }

    img[0] = 'M';
    img[1] = 'Z';
    put_le32(img + 0x3cU, pe_off);

    img[pe_off + 0U] = 'P';
    img[pe_off + 1U] = 'E';
    img[pe_off + 2U] = 0U;
    img[pe_off + 3U] = 0U;

    uint8_t *coff = img + pe_off + 4U;
    put_le16(coff + 0U, machine);
    put_le16(coff + 2U, 4U);
    put_le32(coff + 4U, 0U);
    put_le32(coff + 8U, 0U);
    put_le32(coff + 12U, 0U);
    put_le16(coff + 16U, opt_hdr_size);
    put_le16(coff + 18U, is_pe32_plus ? 0x0222U : 0x0302U);

    uint8_t *opt = coff + 20U;
    put_le16(opt + 0U, is_pe32_plus ? 0x020bU : 0x010bU);
    opt[2] = 1U;
    opt[3] = 0U;
    put_le32(opt + 4U, sects[2].aligned_raw_len);
    put_le32(opt + 8U, sects[0].aligned_raw_len + sects[1].aligned_raw_len + sects[3].aligned_raw_len);
    put_le32(opt + 12U, 0U);
    put_le32(opt + 16U, sects[2].rva);
    put_le32(opt + 20U, sects[2].rva);

    uint8_t *ddir = NULL;
    if (is_pe32_plus) {
        put_le64(opt + 24U, 0x10000000ULL);
        put_le32(opt + 32U, SECT_ALIGN);
        put_le32(opt + 36U, FILE_ALIGN);
        put_le16(opt + 68U, EFI_SUBSYSTEM_APPLICATION);
        put_le32(opt + 56U, size_of_image);
        put_le32(opt + 60U, size_of_headers);
        put_le32(opt + 108U, 16U);
        ddir = opt + 112U;
    } else {
        put_le32(opt + 24U, sects[0].rva);
        put_le32(opt + 28U, 0x10000000U);
        put_le32(opt + 32U, SECT_ALIGN);
        put_le32(opt + 36U, FILE_ALIGN);
        put_le32(opt + 56U, size_of_image);
        put_le32(opt + 60U, size_of_headers);
        put_le16(opt + 68U, EFI_SUBSYSTEM_APPLICATION);
        put_le32(opt + 92U, 16U);
        ddir = opt + 96U;
    }

    if (cert_total_len > 0U) {
        put_le32(ddir + (4U * 8U), cert_foff);
        put_le32(ddir + (4U * 8U) + 4U, cert_total_len);
    }

    for (int i = 0; i < 4; i++) {
        uint8_t *sh = img + sect_tbl_off + ((uint32_t)i * 40U);
        memcpy(sh + 0U, sects[i].name, 8U);
        put_le32(sh + 8U, sects[i].vsize);
        put_le32(sh + 12U, sects[i].rva);
        put_le32(sh + 16U, sects[i].aligned_raw_len);
        put_le32(sh + 20U, sects[i].file_off);
        uint32_t chars = (i == 2) ? 0x60000020U : 0x40000040U;
        put_le32(sh + 36U, chars);
        if (sects[i].raw_len > 0U) {
            memcpy(img + sects[i].file_off, sects[i].data, sects[i].raw_len);
        }
    }

    if (cert_total_len > 0U) {
        uint8_t *wcert = img + cert_foff;
        put_le32(wcert + 0U, cert_total_len);
        put_le16(wcert + 4U, 0x0200U);
        put_le16(wcert + 6U, 0x0002U);
        memcpy(wcert + 8U, sig_data, sig_raw_len);
    }

    FILE *fout = fopen(out_path, "wb");
    int rc = 0;
    if (fout == NULL) {
        rc = 1;
    } else {
        if (fwrite(img, 1U, total_file_size, fout) != total_file_size) {
            rc = 1;
        }
        fclose(fout);
    }

    for (int i = 0; i < 4; i++) {
        free(sects[i].data);
    }
    free(sig_data);
    free(img);
    return rc;
}
