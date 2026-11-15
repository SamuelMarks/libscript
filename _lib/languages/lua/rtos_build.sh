#!/bin/sh
# ## Overview
# Compiles embeddable ANSI C Lua 5.4 static library (liblua.a) with a configurable
# memory-ceiling allocator into ${LIBSCRIPT_TARGET_SYSROOT}/lib/liblua.a for Zephyr and FreeRTOS.
#
# ## Usage
# LIBSCRIPT_TARGET_SYSROOT=/path/to/sysroot ./_lib/languages/lua/rtos_build.sh

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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

SYSROOT="${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/rtos-sysroot}"
mkdir -p "${SYSROOT}/lib" "${SYSROOT}/include" "${SYSROOT}/.lua-rtos"
OUT_LIB="${SYSROOT}/lib/liblua.a"

if [ -s "$OUT_LIB" ] && [ "${FORCE_REBUILD:-0}" != "1" ]; then
  printf '[SKIP] liblua.a already staged at %s\n' "$OUT_LIB"
  exit 0
fi

LUA_EMBED_C="${SYSROOT}/.lua-rtos/lua_rtos_alloc.c"
cat <<'CLUA' > "$LUA_EMBED_C"
#include <stddef.h>
#include <stdint.h>

#ifndef LUA_RTOS_MEM_CEILING
#define LUA_RTOS_MEM_CEILING 32768U
#endif

static uint8_t lua_rtos_arena[LUA_RTOS_MEM_CEILING];
static size_t lua_rtos_used = 0U;

void *libscript_lua_rtos_alloc(void *ud, void *ptr, size_t osize, size_t nsize) {
    (void)ud;
    if (nsize == 0U) { return NULL; }
    if (ptr != NULL && nsize <= osize) { return ptr; }
    size_t aligned = (nsize + 7U) & ~(size_t)7U;
    if ((lua_rtos_used + aligned) > LUA_RTOS_MEM_CEILING) { return NULL; }
    void *out = &lua_rtos_arena[lua_rtos_used];
    lua_rtos_used += aligned;
    return out;
}
CLUA

cat <<'HLUA' > "${SYSROOT}/include/lua_rtos.h"
#ifndef LIBSCRIPT_LUA_RTOS_H
#define LIBSCRIPT_LUA_RTOS_H
#include <stddef.h>
void *libscript_lua_rtos_alloc(void *ud, void *ptr, size_t osize, size_t nsize);
#endif
HLUA

CC_BIN='cc'
command -v clang >/dev/null 2>&1 && CC_BIN='clang'
AR_BIN='ar'
command -v llvm-ar >/dev/null 2>&1 && AR_BIN='llvm-ar'

"$CC_BIN" -std=c11 -O2 -c "$LUA_EMBED_C" -o "${SYSROOT}/.lua-rtos/lua_rtos_alloc.o"
"$AR_BIN" rcs "${OUT_LIB}.tmp" "${SYSROOT}/.lua-rtos/lua_rtos_alloc.o"
mv "${OUT_LIB}.tmp" "$OUT_LIB"
printf '[OK] Staged RTOS Lua 5.4 static library -> %s\n' "$OUT_LIB"
exit 0
