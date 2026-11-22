#!/bin/sh
# ## Overview
# Zero-dependency ELF64 `.gnu.version_r` symbol version patcher compiled via host C compiler.
# ## Usage
# . "${LIBSCRIPT_ROOT_DIR}/engine/common/elf_verneed_patch.sh"; libscript_patch_elf_verneed <elf> <old=new>

set -feu
_evp_caller_this="${THIS_FILE:-}"
_evp_caller_dir="${SCRIPT_DIR:-}"
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi
case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    [ -n "$_evp_caller_this" ] && THIS_FILE="$_evp_caller_this"
    [ -n "$_evp_caller_dir" ] && SCRIPT_DIR="$_evp_caller_dir"
    unset SCRIPT_NAME || true
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s' "$d")}"

# ## libscript_patch_elf_verneed
# Rewrites ELF64 `.gnu.version_r` (`SHT_GNU_verneed`) version requirement entries
# in-place for one or more `OLD_VER=NEW_VER` pairs using a tiny compiled C11 helper.
libscript_patch_elf_verneed() {
  if [ "$#" -lt 2 ]; then
    return 1
  fi
  _evp_target="$1"
  shift
  [ -f "$_evp_target" ] || return 0

  _evp_cc="$(command -v gcc 2>/dev/null || command -v clang 2>/dev/null || command -v cc 2>/dev/null || true)"
  [ -n "$_evp_cc" ] || return 0

  _evp_src=$(mktemp "${TMPDIR:-/tmp}/ls_evp_src.XXXXXX")
  _evp_bin=$(mktemp "${TMPDIR:-/tmp}/ls_evp_bin.XXXXXX")
  cat << 'EOF_EVP_C' > "$_evp_src"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static uint16_t rd16(const uint8_t *p) {
    return (uint16_t)p[0] | ((uint16_t)p[1] << 8);
}
static uint32_t rd32(const uint8_t *p) {
    return (uint32_t)p[0] | ((uint32_t)p[1] << 8) | ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24);
}
static uint64_t rd64(const uint8_t *p) {
    return (uint64_t)rd32(p) | ((uint64_t)rd32(p + 4) << 32);
}
static void wr32(uint8_t *p, uint32_t v) {
    p[0] = (uint8_t)(v & 255u);
    p[1] = (uint8_t)((v >> 8) & 255u);
    p[2] = (uint8_t)((v >> 16) & 255u);
    p[3] = (uint8_t)((v >> 24) & 255u);
}
static uint32_t elf_hash(const char *s) {
    uint32_t h = 0, g;
    const unsigned char *u = (const unsigned char *)s;
    while (*u) {
        h = (h << 4) + *u++;
        g = h & 0xf0000000u;
        if (g) h ^= (g >> 24);
        h &= ~g;
    }
    return h;
}

struct str_off {
    const char *str;
    uint32_t off;
};

int main(int argc, char **argv) {
    FILE *f;
    long file_len;
    size_t sz, i;
    uint8_t *data;
    uint64_t e_shoff, verneed_off = 0, dynstr_off = 0;
    uint16_t e_shentsize, e_shnum;
    uint32_t verneed_cnt = 0, verneed_link = 0;
    struct str_off known[256];
    size_t n_known = 0;

    if (argc < 3) return 1;
    f = fopen(argv[1], "rb");
    if (!f) return 1;
    if (fseek(f, 0, SEEK_END) != 0) { fclose(f); return 1; }
    file_len = ftell(f);
    if (file_len < 64) { fclose(f); return 0; }
    sz = (size_t)file_len;
    rewind(f);
    data = (uint8_t *)malloc(sz);
    if (!data) { fclose(f); return 1; }
    if (fread(data, 1, sz, f) != sz) { free(data); fclose(f); return 1; }
    fclose(f);

    if (memcmp(data, "\x7f""ELF", 4) != 0 || data[4] != 2 || data[5] != 1) {
        free(data);
        return 0;
    }
    e_shoff = rd64(data + 40);
    e_shentsize = rd16(data + 58);
    e_shnum = rd16(data + 60);
    for (i = 0; i < e_shnum; i++) {
        uint64_t sh = e_shoff + (uint64_t)i * e_shentsize;
        if (sh + 64 > sz) break;
        if (rd32(data + sh + 4) == 0x6ffffffe) {
            verneed_off = rd64(data + sh + 24);
            verneed_link = rd32(data + sh + 40);
            verneed_cnt = rd32(data + sh + 44);
        }
    }
    if (verneed_off == 0 || verneed_link >= e_shnum) {
        free(data);
        return 0;
    }
    dynstr_off = rd64(data + e_shoff + (uint64_t)verneed_link * e_shentsize + 24);

    {
        uint64_t pos = verneed_off;
        uint32_t v;
        for (v = 0; v < verneed_cnt && pos + 16 <= sz; v++) {
            uint16_t vn_cnt = rd16(data + pos + 2);
            uint32_t vn_aux = rd32(data + pos + 8);
            uint32_t vn_next = rd32(data + pos + 12);
            uint64_t apos = pos + vn_aux;
            uint16_t a;
            for (a = 0; a < vn_cnt && apos + 16 <= sz; a++) {
                uint32_t vna_name = rd32(data + apos + 8);
                uint32_t vna_next = rd32(data + apos + 12);
                if (dynstr_off + vna_name < sz && n_known < 256) {
                    known[n_known].str = (const char *)(data + dynstr_off + vna_name);
                    known[n_known].off = vna_name;
                    n_known++;
                }
                if (vna_next == 0) break;
                apos += vna_next;
            }
            if (vn_next == 0) break;
            pos += vn_next;
        }
    }

    {
        uint64_t pos = verneed_off;
        uint32_t v;
        for (v = 0; v < verneed_cnt && pos + 16 <= sz; v++) {
            uint16_t vn_cnt = rd16(data + pos + 2);
            uint32_t vn_aux = rd32(data + pos + 8);
            uint32_t vn_next = rd32(data + pos + 12);
            uint64_t apos = pos + vn_aux;
            uint16_t a;
            for (a = 0; a < vn_cnt && apos + 16 <= sz; a++) {
                uint32_t vna_name = rd32(data + apos + 8);
                uint32_t vna_next = rd32(data + apos + 12);
                if (dynstr_off + vna_name < sz) {
                    const char *name = (const char *)(data + dynstr_off + vna_name);
                    int idx;
                    for (idx = 2; idx < argc; idx++) {
                        const char *eq = strchr(argv[idx], '=');
                        size_t key_len, target_len;
                        if (!eq) continue;
                        key_len = (size_t)(eq - argv[idx]);
                        target_len = strlen(eq + 1);
                        if (strlen(name) == key_len && memcmp(name, argv[idx], key_len) == 0 && target_len <= key_len) {
                            const char *target = eq + 1;
                            uint32_t new_off = vna_name;
                            int found = 0;
                            size_t ki;
                            for (ki = 0; ki < n_known; ki++) {
                                if (strcmp(known[ki].str, target) == 0) {
                                    new_off = known[ki].off;
                                    found = 1;
                                    break;
                                }
                            }
                            if (!found && dynstr_off + vna_name + target_len + 1 <= sz) {
                                memcpy(data + dynstr_off + vna_name, target, target_len + 1);
                            }
                            wr32(data + apos, elf_hash(target));
                            wr32(data + apos + 8, new_off);
                            break;
                        }
                    }
                }
                if (vna_next == 0) break;
                apos += vna_next;
            }
            if (vn_next == 0) break;
            pos += vn_next;
        }
    }

    f = fopen(argv[1], "wb");
    if (!f) { free(data); return 1; }
    (void)fwrite(data, 1, sz, f);
    fclose(f);
    free(data);
    return 0;
}
EOF_EVP_C

  if "$_evp_cc" -O2 -x c "$_evp_src" -o "$_evp_bin" 2>/dev/null; then
    "$_evp_bin" "$_evp_target" "$@" 2>/dev/null || true
  fi
  rm -f "$_evp_src" "$_evp_bin"
}

STACK="${STACK%"${THIS_FILE}":}"
export STACK
[ -n "${_evp_caller_dir:-}" ] && SCRIPT_DIR="$_evp_caller_dir"
[ -n "${_evp_caller_this:-}" ] && THIS_FILE="$_evp_caller_this"
unset SCRIPT_NAME _evp_caller_this _evp_caller_dir || true
