#!/bin/sh
# ## Overview
# C89/C99 language conformance smoke test suite for the Custom C Compiler (custom-cc).
# Verifies struct/bitfield/union layout, function pointer tables, <stdarg.h> varargs,
# 64-bit integer shifts, IEEE-754 double arithmetic, and preprocessor token pasting.
#
# ## Usage
# ./_lib/languages/custom-cc/test.sh

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

if [ -f "${SCRIPT_DIR}/env.sh" ]; then
  SCRIPT_NAME="${SCRIPT_DIR}/env.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
fi

"${CC:-${SCRIPT_DIR}/cc_wrapper.sh}" --version

_tmp_dir="${TMPDIR:-/tmp}/libscript_custom_cc_test_$$"
mkdir -p "${_tmp_dir}"
cat <<'EOF' > "${_tmp_dir}/conformance.c"
#include <stdio.h>
#include <stdint.h>
#include <stdarg.h>

#define MAKE_FN_NAME(prefix, id) prefix##_##id

struct PackedHeader {
    unsigned int flags : 4;
    unsigned int version : 4;
    unsigned int length : 24;
    union {
        uint64_t u64;
        double f64;
    } payload;
};

typedef int (*op_fn)(int, int);

static int MAKE_FN_NAME(op, add)(int a, int b) { return a + b; }
static int MAKE_FN_NAME(op, xor)(int a, int b) { return a ^ b; }

static int sum_varargs(int count, ...) {
    va_list ap;
    int total = 0;
    int i;
    va_start(ap, count);
    for (i = 0; i < count; ++i) {
        total += va_arg(ap, int);
    }
    va_end(ap);
    return total;
}

int main(void) {
    struct PackedHeader hdr;
    op_fn table[2];
    uint64_t mask = (1ULL << 40) | 0x55AAULL;
    int vsum;

    hdr.flags = 0xA;
    hdr.version = 0x3;
    hdr.length = 65535U;
    hdr.payload.f64 = 3.5;

    table[0] = op_add;
    table[1] = op_xor;
    vsum = sum_varargs(4, 10, 20, 30, 40);

    if (hdr.flags == 0xA && hdr.version == 3 && hdr.length == 65535U &&
        hdr.payload.f64 > 3.4 && (mask >> 40) == 1ULL &&
        table[0](7, 8) == 15 && table[1](0xF0, 0x0F) == 0xFF && vsum == 100) {
        puts("CUSTOM_CC_CONFORMANCE_OK");
        return 0;
    }
    return 1;
}
EOF

"${CC:-${SCRIPT_DIR}/cc_wrapper.sh}" -O2 "${_tmp_dir}/conformance.c" -o "${_tmp_dir}/conformance"
_out="$("${_tmp_dir}/conformance")"
rm -rf "${_tmp_dir}"
[ "${_out}" = "CUSTOM_CC_CONFORMANCE_OK" ]
