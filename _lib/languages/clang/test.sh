#!/bin/sh
# ## Overview
# Smoke test suite for the LLVM Clang component. Compiles and runs a small C99 program.
#
# ## Usage
# ./_lib/languages/clang/test.sh

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

"${CC:-clang}" --version

_tmp_dir="${TMPDIR:-/tmp}/libscript_clang_test_$$"
mkdir -p "${_tmp_dir}"
cat <<'EOF' > "${_tmp_dir}/hello.c"
#include <stdio.h>
int main(void) {
    puts("CLANG_SMOKE_OK");
    return 0;
}
EOF
"${CC:-clang}" -O2 "${_tmp_dir}/hello.c" -o "${_tmp_dir}/hello"
_out="$("${_tmp_dir}/hello")"
rm -rf "${_tmp_dir}"
[ "${_out}" = "CLANG_SMOKE_OK" ]
