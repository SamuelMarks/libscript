/**
 * ## Overview
 * Pure C11 zero-dependency MCUboot v2 image header, SHA-256 TLV, and A/B slot trailer signer.
 *
 * ## Usage
 * mcuboot_c_signer <in.bin> <out.signed.bin> [header_size] [slot_size]
 */

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define IMAGE_MAGIC 0x96f3b83dU
#define IMAGE_TLV_INFO_MAGIC 0x6907U
#define IMAGE_TLV_SHA256 0x10U

static const uint32_t K256[64] = {
    0x428a2f98U, 0x71374491U, 0xb5c0fbcfU, 0xe9b5dba5U, 0x3956c25bU, 0x59f111f1U, 0x923f82a4U, 0xab1c5ed5U,
    0xd807aa98U, 0x12835b01U, 0x243185beU, 0x550c7dc3U, 0x72be5d74U, 0x80deb1feU, 0x9bdc06a7U, 0xc19bf174U,
    0xe49b69c1U, 0xefbe4786U, 0x0fc19dc6U, 0x240ca1ccU, 0x2de92c6fU, 0x4a7484aaU, 0x5cb0a9dcU, 0x76f988daU,
    0x983e5152U, 0xa831c66dU, 0xb00327c8U, 0xbf597fc7U, 0xc6e00bf3U, 0xd5a79147U, 0x06ca6351U, 0x14292967U,
    0x27b70a85U, 0x2e1b2138U, 0x4d2c6dfcU, 0x53380d13U, 0x650a7354U, 0x766a0abbU, 0x81c2c92eU, 0x92722c85U,
    0xa2bfe8a1U, 0xa81a664bU, 0xc24b8b70U, 0xc76c51a3U, 0xd192e819U, 0xd6990624U, 0xf40e3585U, 0x106aa070U,
    0x19a4c116U, 0x1e376c08U, 0x2748774cU, 0x34b0bcb5U, 0x391c0cb3U, 0x4ed8aa4aU, 0x5b9cca4fU, 0x682e6ff3U,
    0x748f82eeU, 0x78a5636fU, 0x84c87814U, 0x8cc70208U, 0x90befffaU, 0xa4506cebU, 0xbef9a3f7U, 0xc67178f2U
};

static uint32_t rotr32(uint32_t x, unsigned int n) {
    return (x >> n) | (x << (32U - n));
}

static void sha256_compute(const uint8_t *msg, size_t len, uint8_t out[32]) {
    uint32_t h[8] = {
        0x6a09e667U, 0xbb67ae85U, 0x3c6ef372U, 0xa54ff53aU,
        0x510e527fU, 0x9b05688cU, 0x1f83d9abU, 0x5be0cd19U
    };
    size_t padded_len = ((len + 9U + 63U) / 64U) * 64U;
    uint8_t *buf = (uint8_t *)calloc(1U, padded_len);
    if (buf == NULL) {
        memset(out, 0, 32U);
        return;
    }
    if (len > 0U) {
        memcpy(buf, msg, len);
    }
    buf[len] = 0x80U;
    uint64_t bit_len = (uint64_t)len * 8ULL;
    for (int i = 0; i < 8; i++) {
        buf[padded_len - 1U - (size_t)i] = (uint8_t)((bit_len >> (i * 8)) & 0xffU);
    }
    for (size_t off = 0; off < padded_len; off += 64U) {
        uint32_t w[64];
        for (int i = 0; i < 16; i++) {
            w[i] = ((uint32_t)buf[off + (size_t)i * 4U] << 24U) |
                   ((uint32_t)buf[off + (size_t)i * 4U + 1U] << 16U) |
                   ((uint32_t)buf[off + (size_t)i * 4U + 2U] << 8U) |
                   ((uint32_t)buf[off + (size_t)i * 4U + 3U]);
        }
        for (int i = 16; i < 64; i++) {
            uint32_t s0 = rotr32(w[i - 15], 7U) ^ rotr32(w[i - 15], 18U) ^ (w[i - 15] >> 3U);
            uint32_t s1 = rotr32(w[i - 2], 17U) ^ rotr32(w[i - 2], 19U) ^ (w[i - 2] >> 10U);
            w[i] = w[i - 16] + s0 + w[i - 7] + s1;
        }
        uint32_t a = h[0], b = h[1], c = h[2], d = h[3];
        uint32_t e = h[4], f = h[5], g = h[6], hh = h[7];
        for (int i = 0; i < 64; i++) {
            uint32_t s1 = rotr32(e, 6U) ^ rotr32(e, 11U) ^ rotr32(e, 25U);
            uint32_t ch = (e & f) ^ ((~e) & g);
            uint32_t t1 = hh + s1 + ch + K256[i] + w[i];
            uint32_t s0 = rotr32(a, 2U) ^ rotr32(a, 13U) ^ rotr32(a, 22U);
            uint32_t maj = (a & b) ^ (a & c) ^ (b & c);
            uint32_t t2 = s0 + maj;
            hh = g; g = f; f = e; e = d + t1;
            d = c; c = b; b = a; a = t1 + t2;
        }
        h[0] += a; h[1] += b; h[2] += c; h[3] += d;
        h[4] += e; h[5] += f; h[6] += g; h[7] += hh;
    }
    free(buf);
    for (int i = 0; i < 8; i++) {
        out[i * 4] = (uint8_t)((h[i] >> 24U) & 0xffU);
        out[i * 4 + 1] = (uint8_t)((h[i] >> 16U) & 0xffU);
        out[i * 4 + 2] = (uint8_t)((h[i] >> 8U) & 0xffU);
        out[i * 4 + 3] = (uint8_t)(h[i] & 0xffU);
    }
}

static void write_le32(uint8_t *p, uint32_t v) {
    p[0] = (uint8_t)(v & 0xffU);
    p[1] = (uint8_t)((v >> 8U) & 0xffU);
    p[2] = (uint8_t)((v >> 16U) & 0xffU);
    p[3] = (uint8_t)((v >> 24U) & 0xffU);
}

static void write_le16(uint8_t *p, uint16_t v) {
    p[0] = (uint8_t)(v & 0xffU);
    p[1] = (uint8_t)((v >> 8U) & 0xffU);
}

int main(int argc, char **argv) {
    if (argc < 3) {
        fprintf(stderr, "Usage: %s <in.bin> <out.signed.bin> [header_size] [slot_size]\n", argv[0]);
        return 1;
    }
    size_t hdr_sz = (argc >= 4) ? (size_t)strtoul(argv[3], NULL, 0) : 0x200U;
    size_t slot_sz = (argc >= 5) ? (size_t)strtoul(argv[4], NULL, 0) : 0x40000U;
    if (hdr_sz < 32U) {
        hdr_sz = 0x200U;
    }

    FILE *fin = fopen(argv[1], "rb");
    if (fin == NULL) {
        fprintf(stderr, "Cannot open input binary: %s\n", argv[1]);
        return 1;
    }
    fseek(fin, 0, SEEK_END);
    long raw_len = ftell(fin);
    fseek(fin, 0, SEEK_SET);
    if (raw_len < 0) {
        fclose(fin);
        return 1;
    }
    size_t img_sz = (size_t)raw_len;
    size_t tlv_sz = 4U + 4U + 32U;
    size_t min_total = hdr_sz + img_sz + tlv_sz + 40U;
    if (slot_sz < min_total) {
        slot_sz = ((min_total + 4095U) / 4096U) * 4096U;
    }

    uint8_t *slot = (uint8_t *)malloc(slot_sz);
    if (slot == NULL) {
        fclose(fin);
        return 1;
    }
    memset(slot, 0xff, slot_sz);
    memset(slot, 0x00, hdr_sz);

    if (img_sz > 0U && fread(slot + hdr_sz, 1U, img_sz, fin) != img_sz) {
        free(slot);
        fclose(fin);
        return 1;
    }
    fclose(fin);

    write_le32(slot + 0, IMAGE_MAGIC);
    write_le32(slot + 4, 0U);
    write_le16(slot + 8, (uint16_t)hdr_sz);
    write_le16(slot + 10, 0U);
    write_le32(slot + 12, (uint32_t)img_sz);
    write_le32(slot + 16, 0U);
    slot[20] = 1U;
    slot[21] = 0U;
    write_le16(slot + 22, 0U);

    uint8_t digest[32];
    sha256_compute(slot, hdr_sz + img_sz, digest);

    size_t tlv_off = hdr_sz + img_sz;
    write_le16(slot + tlv_off, IMAGE_TLV_INFO_MAGIC);
    write_le16(slot + tlv_off + 2U, (uint16_t)tlv_sz);
    slot[tlv_off + 4U] = (uint8_t)IMAGE_TLV_SHA256;
    slot[tlv_off + 5U] = 0U;
    write_le16(slot + tlv_off + 6U, 32U);
    memcpy(slot + tlv_off + 8U, digest, 32U);

    /* MCUboot boot_img_magic trailer + image_ok=0x01 (--pad --confirm) */
    static const uint32_t BOOT_IMG_MAGIC[4] = {
        0xf395c277U, 0x7fefd260U, 0x0f505235U, 0x8079b62cU
    };
    size_t trailer_magic_off = slot_sz - 16U;
    for (int i = 0; i < 4; i++) {
        write_le32(slot + trailer_magic_off + (size_t)i * 4U, BOOT_IMG_MAGIC[i]);
    }
    slot[slot_sz - 24U] = 0x01U; /* image_ok confirmed */

    FILE *fout = fopen(argv[2], "wb");
    if (fout == NULL) {
        free(slot);
        return 1;
    }
    size_t written = fwrite(slot, 1U, slot_sz, fout);
    fclose(fout);
    free(slot);
    return (written == slot_sz) ? 0 : 1;
}
