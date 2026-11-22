/**
 * ## Overview
 * Pure C11 Microsoft UF2 (USB Flashing Format) 512-byte block synthesizer.
 * Converts raw .bin firmware into drag-and-drop .uf2 flash blocks with zero Python dependency.
 *
 * ## Usage
 * uf2_c_packer <in.bin> <out.uf2> [base_addr_hex] [family_id_hex]
 */

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define UF2_MAGIC_START0 0x0A324655U
#define UF2_MAGIC_START1 0x9E5D5157U
#define UF2_MAGIC_END    0x0AB16F30U
#define UF2_FLAG_FAMILY  0x00002000U

static void put_le32(uint8_t *p, uint32_t v) {
    p[0] = (uint8_t)(v & 0xffU);
    p[1] = (uint8_t)((v >> 8U) & 0xffU);
    p[2] = (uint8_t)((v >> 16U) & 0xffU);
    p[3] = (uint8_t)((v >> 24U) & 0xffU);
}

int main(int argc, char **argv) {
    if (argc < 3) {
        fprintf(stderr, "Usage: %s <in.bin> <out.uf2> [base_addr] [family_id]\n", argv[0]);
        return 1;
    }
    uint32_t base_addr = (argc >= 4) ? (uint32_t)strtoul(argv[3], NULL, 0) : 0x08000000U;
    uint32_t family_id = (argc >= 5) ? (uint32_t)strtoul(argv[4], NULL, 0) : 0xE48BFF56U;

    FILE *fin = fopen(argv[1], "rb");
    if (fin == NULL) {
        return 1;
    }
    fseek(fin, 0, SEEK_END);
    long fsz = ftell(fin);
    fseek(fin, 0, SEEK_SET);
    if (fsz < 0) {
        fclose(fin);
        return 1;
    }
    uint32_t total_len = (uint32_t)fsz;
    uint32_t num_blocks = (total_len == 0U) ? 1U : ((total_len + 255U) / 256U);

    FILE *fout = fopen(argv[2], "wb");
    if (fout == NULL) {
        fclose(fin);
        return 1;
    }

    for (uint32_t blk = 0U; blk < num_blocks; blk++) {
        uint8_t block[512];
        memset(block, 0, sizeof(block));
        size_t nread = fread(block + 32U, 1U, 256U, fin);
        put_le32(block + 0, UF2_MAGIC_START0);
        put_le32(block + 4, UF2_MAGIC_START1);
        put_le32(block + 8, UF2_FLAG_FAMILY);
        put_le32(block + 12, base_addr + blk * 256U);
        put_le32(block + 16, 256U);
        put_le32(block + 20, blk);
        put_le32(block + 24, num_blocks);
        put_le32(block + 28, family_id);
        (void)nread;
        put_le32(block + 508, UF2_MAGIC_END);
        if (fwrite(block, 1U, 512U, fout) != 512U) {
            fclose(fin);
            fclose(fout);
            return 1;
        }
    }
    fclose(fin);
    fclose(fout);
    return 0;
}
