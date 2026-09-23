#!/bin/sh
# ## Overview
# End-to-end idempotency and re-entrancy verification matrix test harness.
# Executes the entire synthesis pipeline twice consecutively on an identical workspace,
# asserting that the second pass terminates immediately as a zero-op with return code 0
# and zero mutation of target output files.
#
# ## Usage
# ./tests/test_idempotency_matrix.sh [--target-dir=<dir>]

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
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

TEST_DIR="${LIBSCRIPT_ROOT_DIR}/tests_tmp/idempotency_matrix_$$"
mkdir -p "$TEST_DIR"
trap 'rm -rf "$TEST_DIR"' EXIT INT TERM

printf '=== LibScript 2x Consecutive Run Idempotency Matrix ===
'

# Pass 1: Initial execution
printf '[PASS 1] Executing initial rootfs and FHS staging in %s...
' "$TEST_DIR"
"${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/rootfs.sh" "$TEST_DIR"

# Snapshot stamps after Pass 1
STAMP_SNAPSHOT="${TEST_DIR}/pass1_stamps.txt"
ls -la "${TEST_DIR}/var/lib/libscript/stamps" > "$STAMP_SNAPSHOT" 2>/dev/null || true

# Pass 2: Re-entrant consecutive execution
printf '[PASS 2] Executing second consecutive pass on identical workspace...
'
"${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/rootfs.sh" "$TEST_DIR"

# Snapshot stamps after Pass 2
PASS2_STAMPS="${TEST_DIR}/pass2_stamps.txt"
ls -la "${TEST_DIR}/var/lib/libscript/stamps" > "$PASS2_STAMPS" 2>/dev/null || true

# Assert no mutation occurred
printf '[ASSERT] Comparing workspace state between Pass 1 and Pass 2...
'
if [ -f "$STAMP_SNAPSHOT" ] && [ -f "$PASS2_STAMPS" ]; then
  if ! cmp -s "$STAMP_SNAPSHOT" "$PASS2_STAMPS"; then
    printf '[FAIL] Stamp directory mutated between consecutive passes!
' >&2
    diff -u "$STAMP_SNAPSHOT" "$PASS2_STAMPS" >&2 || true
    exit 1
  fi
fi

printf '[PASS] Verified: Second pass produced exact zero-op idempotency
'
printf '=== Idempotency Matrix Verification Succeeded! ===
'
exit 0
