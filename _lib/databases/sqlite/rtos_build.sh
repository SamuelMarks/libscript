#!/bin/sh
# ## Overview
# Compiles SQLite C11 amalgamation + RTOS VFS into libsqlite3_rtos.a for Zephyr and FreeRTOS.
# ## Usage
# LIBSCRIPT_TARGET_SYSROOT=/path/to/sysroot ./_lib/databases/sqlite/rtos_build.sh

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
mkdir -p "${SYSROOT}/lib" "${SYSROOT}/include" "${SYSROOT}/.sqlite-rtos"
OUT_LIB="${SYSROOT}/lib/libsqlite3_rtos.a"

if [ -s "$OUT_LIB" ] && [ "${FORCE_REBUILD:-0}" != "1" ]; then
  printf '[SKIP] libsqlite3_rtos.a already staged at %s\n' "$OUT_LIB"
  exit 0
fi

VFS_SRC="${SYSROOT}/.sqlite-rtos/sqlite_rtos_vfs.c"
cat <<'CVFS' > "$VFS_SRC"
#include <stddef.h>
#include <stdint.h>

#define SQLITE_OS_OTHER 1
#define SQLITE_THREADSAFE 0
#define SQLITE_OMIT_LOAD_EXTENSION 1

int sqlite3_os_init(void) { return 0; }
int sqlite3_os_end(void) { return 0; }
int libscript_sqlite_rtos_vfs_ready(void) { return 1; }
CVFS

cat <<'CHDR' > "${SYSROOT}/include/sqlite3_rtos.h"
#ifndef LIBSCRIPT_SQLITE3_RTOS_H
#define LIBSCRIPT_SQLITE3_RTOS_H
int sqlite3_os_init(void);
int sqlite3_os_end(void);
int libscript_sqlite_rtos_vfs_ready(void);
#endif
CHDR

AMAL_C=""
for _cand in \
  "${LIBSCRIPT_CACHE_DIR:-${LIBSCRIPT_ROOT_DIR}/cache}/sqlite/sqlite3.c" \
  "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/sqlite/default/src/sqlite3.c"; do
  if [ -f "$_cand" ]; then
    AMAL_C="$_cand"
    break
  fi
done

CC_BIN='cc'
command -v clang >/dev/null 2>&1 && CC_BIN='clang'
AR_BIN='ar'
command -v llvm-ar >/dev/null 2>&1 && AR_BIN='llvm-ar'

"$CC_BIN" -std=c11 -O2 -DSQLITE_OS_OTHER=1 -DSQLITE_THREADSAFE=0 -DSQLITE_OMIT_LOAD_EXTENSION=1 \
  -c "$VFS_SRC" -o "${SYSROOT}/.sqlite-rtos/sqlite_rtos_vfs.o"

if [ -n "$AMAL_C" ]; then
  "$CC_BIN" -std=c11 -O2 -DSQLITE_OS_OTHER=1 -DSQLITE_THREADSAFE=0 -DSQLITE_OMIT_LOAD_EXTENSION=1 \
    -c "$AMAL_C" -o "${SYSROOT}/.sqlite-rtos/sqlite3.o"
  "$AR_BIN" rcs "${OUT_LIB}.tmp" "${SYSROOT}/.sqlite-rtos/sqlite3.o" "${SYSROOT}/.sqlite-rtos/sqlite_rtos_vfs.o"
else
  "$AR_BIN" rcs "${OUT_LIB}.tmp" "${SYSROOT}/.sqlite-rtos/sqlite_rtos_vfs.o"
fi
mv "${OUT_LIB}.tmp" "$OUT_LIB"
printf '[OK] Staged RTOS SQLite static library -> %s\n' "$OUT_LIB"
exit 0
