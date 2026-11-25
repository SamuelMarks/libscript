#!/bin/sh
# ## Overview
# Compiles a portable zero-dependency C89 host utility using the active host C compiler
# (CC, cc, gcc, clang, or zig cc), bootstrapping zig via LibScript if no C compiler is present.
# ## Usage
# ./engine/common/dos32/compile_host_c89.sh <source.c> <output_bin>
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

SRC_C="${1:?Missing source.c}"
OUT_BIN="${2:?Missing output_bin}"
mkdir -p "$(dirname -- "${OUT_BIN}")"

# ## try_compile_with_candidates
# Attempts compilation using available CC, cc, gcc, clang, or OmniOS /opt/ooce gcc binaries.
try_compile_with_candidates() {
  for _cand in "${CC:-}" cc gcc clang /opt/ooce/bin/gcc /usr/sfw/bin/gcc; do
    [ -n "${_cand}" ] || continue
    if command -v "${_cand}" >/dev/null 2>&1 || [ -x "${_cand}" ]; then
      "${_cand}" -O2 "${SRC_C}" -o "${OUT_BIN}"
      chmod +x "${OUT_BIN}"
      return 0
    fi
  done
  for _ooce_gcc in /usr/gcc/14/bin/gcc /usr/gcc/13/bin/gcc /usr/gcc/12/bin/gcc /usr/gcc/11/bin/gcc /usr/gcc/10/bin/gcc /opt/ooce/gcc-14/bin/gcc /opt/ooce/gcc-13/bin/gcc /opt/ooce/gcc-12/bin/gcc /opt/ooce/gcc-11/bin/gcc; do
    if [ -x "${_ooce_gcc}" ]; then
      "${_ooce_gcc}" -O2 "${SRC_C}" -o "${OUT_BIN}"
      chmod +x "${OUT_BIN}"
      return 0
    fi
  done
  return 1
}

if try_compile_with_candidates; then
  exit 0
fi

STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install c latest >/dev/null 2>&1 || true
if try_compile_with_candidates; then
  exit 0
fi

if ! command -v zig >/dev/null 2>&1; then
  STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install zig 0.13.0 >/dev/null 2>&1 || true
fi
for _zb in zig "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/zig/0.13.0/zig" "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/zig/default/zig"; do
  if command -v "${_zb}" >/dev/null 2>&1 || [ -x "${_zb}" ]; then
    "${_zb}" cc -O2 "${SRC_C}" -o "${OUT_BIN}"
    chmod +x "${OUT_BIN}"
    exit 0
  fi
done

printf '[ERROR] Unable to locate or bootstrap a C89 compiler for %s
' "${SRC_C}" >&2
exit 1
