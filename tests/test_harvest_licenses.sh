#!/bin/sh
# ## Overview
# Automated unit and integration tests for universal dependency license harvesting.
# Verifies license extraction from leaf packages and composite application stacks,
# RTF and plain-text output validation, metadata manifest generation, and idempotency.
#
# ## Usage
# ./tests/test_harvest_licenses.sh

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

TEST_TMP_DIR="${LIBSCRIPT_ROOT_DIR}/tests_tmp/test_harvest_licenses_$$"
mkdir -p "$TEST_TMP_DIR"

# shellcheck disable=SC2329
cleanup() {
  rm -rf "$TEST_TMP_DIR"
}
trap cleanup EXIT INT TERM

printf '=== Testing Universal Dependency License Harvester ===
'

# Test 1: Single leaf component harvesting (caches/redis)
printf '[TEST 1] Harvesting single leaf component (_lib/caches/redis)...
'
OUT_REDIS="${TEST_TMP_DIR}/redis_licenses"
"${LIBSCRIPT_ROOT_DIR}/packaging/harvest_licenses.sh" "${LIBSCRIPT_ROOT_DIR}/_lib/caches/redis" --out-dir "$OUT_REDIS" --force

if [ ! -f "$OUT_REDIS/licenses_manifest.json" ]; then
  printf '[FAIL] Expected licenses_manifest.json not found in %s
' "$OUT_REDIS" >&2
  exit 1
fi

_redis_count=$(jq '.count' "$OUT_REDIS/licenses_manifest.json")
if [ "$_redis_count" -lt 1 ]; then
  printf '[FAIL] Expected at least 1 license, got %s
' "$_redis_count" >&2
  exit 1
fi

_redis_spdx=$(jq -r '.licenses[0].spdx' "$OUT_REDIS/licenses_manifest.json")
printf '[PASS] Leaf component harvested: %s (%s)
' "$(jq -r '.licenses[0].name' "$OUT_REDIS/licenses_manifest.json")" "$_redis_spdx"

if [ ! -f "$OUT_REDIS/redis_license.rtf" ] || [ ! -f "$OUT_REDIS/redis_license.txt" ]; then
  printf '[FAIL] Missing expected RTF or TXT output file in %s
' "$OUT_REDIS" >&2
  exit 1
fi

# Verify RTF structure
if ! head -n 1 "$OUT_REDIS/redis_license.rtf" | grep -q 'rtf1'; then
  printf '[FAIL] Invalid RTF header in %s\n' "$OUT_REDIS/redis_license.rtf" >&2
  exit 1
fi
printf '[PASS] Verified RTF file structure for redis
'

# Test 2: Composite stack harvesting (stacks/cms/openedx)
printf '[TEST 2] Harvesting composite stack (stacks/cms/openedx)...
'
OUT_OPENEDX="${TEST_TMP_DIR}/openedx_licenses"
"${LIBSCRIPT_ROOT_DIR}/packaging/harvest_licenses.sh" "${LIBSCRIPT_ROOT_DIR}/stacks/cms/openedx" --out-dir "$OUT_OPENEDX" --force

if [ ! -f "$OUT_OPENEDX/licenses_manifest.json" ]; then
  printf '[FAIL] Missing licenses_manifest.json for Open edX
' >&2
  exit 1
fi

_openedx_count=$(jq '.count' "$OUT_OPENEDX/licenses_manifest.json")
if [ "$_openedx_count" -lt 9 ]; then
  printf '[FAIL] Expected at least 9 bundled licenses for Open edX, got %s
' "$_openedx_count" >&2
  exit 1
fi
printf '[PASS] Composite stack harvested %s licenses successfully
' "$_openedx_count"

# Verify all key bundled components are present in the manifest
for comp in openedx mysql redis mongodb python nodejs meilisearch; do
  _found=$(jq --arg c "$comp" '[.licenses[] | select(.name == $c)] | length' "$OUT_OPENEDX/licenses_manifest.json")
  if [ "$_found" -ne 1 ]; then
    printf '[FAIL] Bundled component %s was not found in manifest
' "$comp" >&2
    exit 1
  fi
  printf '[PASS] Verified component in bundle manifest: %s
' "$comp"
done

# Test 3: Idempotency verification
printf '[TEST 3] Testing idempotency of license harvester...
'
_stamp_before=$(stat -f %m "$OUT_OPENEDX/.stamp.licenses_harvested" 2>/dev/null || stat -c %Y "$OUT_OPENEDX/.stamp.licenses_harvested")
sleep 1
"${LIBSCRIPT_ROOT_DIR}/packaging/harvest_licenses.sh" "${LIBSCRIPT_ROOT_DIR}/stacks/cms/openedx" --out-dir "$OUT_OPENEDX"
_stamp_after=$(stat -f %m "$OUT_OPENEDX/.stamp.licenses_harvested" 2>/dev/null || stat -c %Y "$OUT_OPENEDX/.stamp.licenses_harvested")

if [ "$_stamp_before" != "$_stamp_after" ]; then
  printf '[FAIL] Harvester modified stamp without --force; not idempotent!
' >&2
  exit 1
fi
printf '[PASS] Idempotency confirmed: stamp unchanged on subsequent execution
'

printf '=== All license harvester tests completed successfully! ===
'
exit 0
