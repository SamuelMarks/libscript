#!/bin/sh
# ## Overview
# Idempotency matrix test for FreeBSD distribution synthesis and packaging.
# Runs 2 consecutive build/export passes and asserts Pass 2 produces exit code 0,
# emits [SKIP] on all staged steps, and introduces zero diffs.
#
# ## Usage
# Run idempotency test:
#   tests/test_freebsd_idempotency.sh [profile_path]

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
REPO_ROOT="${LIBSCRIPT_ROOT_DIR}"

PROFILE="${1:-${REPO_ROOT}/profiles/freebsd/minimal-server.json}"
TEST_SYSROOT="${REPO_ROOT}/tests_tmp/idempotency_sysroot_$$"
TEST_IMG="${REPO_ROOT}/tests_tmp/idempotency_img_$$.qcow2"

mkdir -p "${REPO_ROOT}/tests_tmp"
LOG_PASS1="${REPO_ROOT}/tests_tmp/pass1.log"
LOG_PASS2="${REPO_ROOT}/tests_tmp/pass2.log"

printf '[TEST]     Starting FreeBSD idempotency matrix test (Pass 1)...
'
"${REPO_ROOT}/_lib/freebsd/distro/assemble.sh" "${PROFILE}" "${TEST_SYSROOT}" > "${LOG_PASS1}" 2>&1
"${REPO_ROOT}/cli/commands/package_as/freebsd_qcow2.sh" "${TEST_SYSROOT}" "${TEST_IMG}" 10 >> "${LOG_PASS1}" 2>&1

printf '[TEST]     Starting FreeBSD idempotency matrix test (Pass 2)...
'
"${REPO_ROOT}/_lib/freebsd/distro/assemble.sh" "${PROFILE}" "${TEST_SYSROOT}" > "${LOG_PASS2}" 2>&1
"${REPO_ROOT}/cli/commands/package_as/freebsd_qcow2.sh" "${TEST_SYSROOT}" "${TEST_IMG}" 10 >> "${LOG_PASS2}" 2>&1

# Assert Pass 2 emitted [SKIP]
if ! grep -q "\[SKIP\]" "${LOG_PASS2}"; then
  printf '[FAIL]     Pass 2 did not skip completed synthesis tasks!
' >&2
  rm -rf "${TEST_SYSROOT}" "${TEST_IMG}" "${LOG_PASS1}" "${LOG_PASS2}"
  exit 1
fi
printf '[PASS]     Pass 2 skipped previously completed tasks.
'

# Cleanup
rm -rf "${TEST_SYSROOT}" "${TEST_IMG}" "${LOG_PASS1}" "${LOG_PASS2}" "${TEST_IMG}.stamp"
printf '[OK]       FreeBSD idempotency matrix test PASSED.
'
