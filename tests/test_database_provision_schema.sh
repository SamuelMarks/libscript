#!/bin/sh
# ## Overview
# Verification test suite for universal multi-tenant schema provisioning and deprovisioning.
#
# ## Usage
#   ./tests/test_database_provision_schema.sh

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
export DIR="${SCRIPT_DIR}"

PROVISION_SH="${LIBSCRIPT_ROOT_DIR}/_lib/databases/provision_schema.sh"
DEPROVISION_SH="${LIBSCRIPT_ROOT_DIR}/_lib/databases/deprovision_schema.sh"

printf '==> Running Universal Schema Provisioning Verification Tests...
'

TEST_SQLITE_DB="$(mktemp "${TMPDIR:-/tmp}/test_schema_XXXXXX.db")"
trap 'rm -f "$TEST_SQLITE_DB"' EXIT INT TERM

# 1. Test Idempotent SQLite Provisioning (Two passes)
printf '[TEST 1] Testing SQLite provisioning idempotency (Pass 1)...
'
"$PROVISION_SH" --engine sqlite --schema "$TEST_SQLITE_DB"
[ -f "$TEST_SQLITE_DB" ] || exit 1

printf '[TEST 1] Testing SQLite provisioning idempotency (Pass 2)...
'
"$PROVISION_SH" --engine sqlite --schema "$TEST_SQLITE_DB"
[ -f "$TEST_SQLITE_DB" ] || exit 1

# 2. Test Idempotent Deprovisioning
printf '[TEST 2] Testing SQLite deprovisioning...
'
"$DEPROVISION_SH" --engine sqlite --schema "$TEST_SQLITE_DB"
[ ! -f "$TEST_SQLITE_DB" ] || exit 1

printf '[SUCCESS] All Schema Provisioning Verification Tests Passed!
'
