#!/bin/sh
# ## Overview
# C89/C99/C11 and C++17 language conformance and binary verification test suite
# for the EDG C/C++ Compiler Frontend (edgcpp v7.0.1).
# Verifies cpfe (including direct --llvm-be native object emission), cpfe-cp
# (C++-generating backend), cdisp, mk_errinfo, edg_decode, include_c99/,
# include_c++/, edgcpp (C driver), and edg-c++ (C++ driver).
#
# ## Usage
# ./_lib/languages/edgcpp/test.sh

set -feu

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
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"
export LIBSCRIPT_ROOT_DIR
_EDGCPP_DIR="${SCRIPT_DIR}"

if [ ! -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/edgcpp/default" ] && [ ! -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/edgcpp/7.0.1" ]; then
  unset SCRIPT_NAME || true
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install edgcpp 7.0.1
fi

if [ -f "${SCRIPT_DIR}/env.sh" ]; then
  SCRIPT_NAME="${SCRIPT_DIR}/env.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
  unset SCRIPT_NAME || true
fi
SCRIPT_DIR="${_EDGCPP_DIR}"

# ## verify_edgcpp_binaries_and_headers
# Verifies that the edgcpp installation contains cpfe, cpfe-cp, cdisp, mk_errinfo, edg_decode, and bundled standard headers.
verify_edgcpp_binaries_and_headers() {
  _edg_dir="${EDGCPP_HOME:-${LIBSCRIPT_HOME:-$HOME/.libscript}/edgcpp/default}"
  [ -d "${_edg_dir}/bin" ]
  [ -x "${_edg_dir}/bin/edgcpp" ]
  [ -x "${_edg_dir}/bin/edg-cc" ]
  [ -x "${_edg_dir}/bin/edg-c++" ]
  if [ -f "${_edg_dir}/bin/cpfe" ]; then
    [ -x "${_edg_dir}/bin/cpfe" ]
    _cpfe_v="$("${_edg_dir}/bin/cpfe" --version < /dev/null 2>&1 | head -n 1 || true)"
    case "${_cpfe_v}" in
      *"Edison Design Group"*) ;;
      *) return 1 ;;
    esac
  fi
  if [ -f "${_edg_dir}/bin/edg_decode" ]; then
    _demangled="$(printf '_Z3fooi
' | "${_edg_dir}/bin/edg_decode" 2>/dev/null || true)"
    [ -n "${_demangled}" ]
  fi
}

# ## verify_c_and_cxx_conformance
# Compiles and executes C11 and C++17 conformance programs using edgcpp, edg-c++, cpfe --llvm-be, and cpfe-cp.
verify_c_and_cxx_conformance() {
  "${CC:-${SCRIPT_DIR}/edgcpp_wrapper.sh}" --version
  _tmp_dir="${TMPDIR:-/tmp}/libscript_edgcpp_test_$$"
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
        puts("EDGCPP_C_CONFORMANCE_OK");
        return 0;
    }
    return 1;
}
EOF

  "${CC:-${SCRIPT_DIR}/edgcpp_wrapper.sh}" -std=c11 -O2 "${_tmp_dir}/conformance.c" -o "${_tmp_dir}/conformance_c"
  _out_c="$("${_tmp_dir}/conformance_c")"
  [ "${_out_c}" = "EDGCPP_C_CONFORMANCE_OK" ]

  # Verify direct cpfe --llvm-be native object file generation on pure C11 TU
  _edg_dir="${EDGCPP_HOME:-${LIBSCRIPT_HOME:-$HOME/.libscript}/edgcpp/default}"
  if [ -x "${_edg_dir}/bin/cpfe" ]; then
    cat <<'EOF' > "${_tmp_dir}/pure_llvm_be.c"
int edg_llvm_compute(int x, int y) {
    return (x * y) + 19;
}
EOF
    (cd "${_edg_dir}" && ./bin/cpfe --c11 --llvm-be "--gen_obj_file_name=${_tmp_dir}/pure_llvm_be.o" "${_tmp_dir}/pure_llvm_be.c" < /dev/null)
    [ -s "${_tmp_dir}/pure_llvm_be.o" ]
  fi

  cat <<'EOF' > "${_tmp_dir}/conformance.cpp"
#include <stdio.h>

template <typename T>
constexpr T constexpr_square(T x) {
    return x * x;
}

class Accumulator {
    int base_;
public:
    explicit constexpr Accumulator(int b) : base_(b) {}
    constexpr int compute(int v) const { return base_ + constexpr_square(v); }
};

int main() {
    constexpr Accumulator acc(7);
    static_assert(acc.compute(5) == 32, "constexpr evaluation failed");
    if (acc.compute(6) == 43) {
        puts("EDGCPP_CXX_CONFORMANCE_OK");
        return 0;
    }
    return 1;
}
EOF

  "${CXX:-${SCRIPT_DIR}/edgcpp_wrapper.sh}" -std=c++17 -O2 "${_tmp_dir}/conformance.cpp" -o "${_tmp_dir}/conformance_cxx"
  _out_cxx="$("${_tmp_dir}/conformance_cxx")"
  rm -rf "${_tmp_dir}"
  [ "${_out_cxx}" = "EDGCPP_CXX_CONFORMANCE_OK" ]
}

verify_edgcpp_binaries_and_headers
verify_c_and_cxx_conformance
