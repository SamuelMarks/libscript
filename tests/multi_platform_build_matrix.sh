#!/bin/sh
# ## Overview
# Validates multi-platform host synthesis capabilities across Linux (Glibc/Musl),
# FreeBSD, macOS, and Windows hosts, verifying cross-target build matrix paths.
#
# ## Usage
# ./tests/multi_platform_build_matrix.sh [--quick]

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

printf '[MATRIX] Starting Multi-Platform Host Build Matrix Verification...\n'

TEST_TMP="${LIBSCRIPT_ROOT_DIR}/build/test_matrix"
mkdir -p "$TEST_TMP"

# 1. Verify Glibc Linux configuration and profile validation
printf '[MATRIX] Checking Glibc Linux target validation...\n'
"${LIBSCRIPT_ROOT_DIR}/libscript.sh" config os --validate="${LIBSCRIPT_ROOT_DIR}/profiles/linux-standard-server-glibc.json"

# 2. Verify Musl Linux configuration and profile validation
printf '[MATRIX] Checking Musl Linux target validation...\n'
"${LIBSCRIPT_ROOT_DIR}/libscript.sh" config os --validate="${LIBSCRIPT_ROOT_DIR}/profiles/linux-minimal-headless-musl.json"

# 3. Verify FreeBSD target configuration
printf '[MATRIX] Checking FreeBSD target validation...\n'
"${LIBSCRIPT_ROOT_DIR}/libscript.sh" config os --validate="${LIBSCRIPT_ROOT_DIR}/profiles/freebsd-server-standard.json"

# 4. Verify Unikernel microVM configuration
printf '[MATRIX] Checking Unikernel target validation...\n'
"${LIBSCRIPT_ROOT_DIR}/libscript.sh" config os --validate="${LIBSCRIPT_ROOT_DIR}/profiles/unikraft-nginx-redis.json"

# 5. Verify Windows batch parity scripts existence
printf '[MATRIX] Checking Windows batch parity across orchestration and packaging tools...\n'
MISSING_CMD=0
for sh_file in "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/distro"/*.sh "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/packagers"/*.sh "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/repogen"/*.sh "${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as"/*.sh; do
  [ -f "$sh_file" ] || continue
  cmd_file="${sh_file%.sh}.cmd"
  if [ ! -f "$cmd_file" ]; then
    printf '[FAIL] Missing Windows batch parity for: %s\n' "$sh_file" >&2
    MISSING_CMD=1
  fi
done

if [ "$MISSING_CMD" -ne 0 ]; then
  printf '[ERROR] Windows batch parity verification failed.\n' >&2
  exit 1
fi

rm -rf "$TEST_TMP"
printf '[OK] Multi-platform host build matrix verification passed successfully.\n'
exit 0
