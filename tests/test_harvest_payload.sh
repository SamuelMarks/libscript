#!/bin/sh
# ## Overview
# Validates LibScript repository harvesting and WiX fragment generation.
# Verifies that required core engine and stack components are harvested,
# excluded artifacts (.git, tests_tmp, temporary files) are filtered,
# and valid WiX fragment XML is synthesized.
#
# ## Usage
# ./tests/test_harvest_payload.sh

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

TEST_TMP_DIR="${LIBSCRIPT_ROOT_DIR}/tests_tmp/test_harvest_payload_$$"
mkdir -p "$TEST_TMP_DIR"

# ## cleanup
# Cleans up temporary test directory upon exit or preserves on error.
# shellcheck disable=SC2317,SC2329
cleanup() {
  _status=$?
  if [ "$_status" -eq 0 ]; then
    rm -rf "$TEST_TMP_DIR"
  else
    printf '[WARN] Preserving test artifacts in %s for diagnosis
' "$TEST_TMP_DIR" >&2
  fi
}
trap cleanup EXIT INT TERM

printf '=== Testing LibScript Repository Harvester ===
'

MANIFEST_FILE="${TEST_TMP_DIR}/manifest.txt"
WIX_FILE="${TEST_TMP_DIR}/fragment.wxs"

"${LIBSCRIPT_ROOT_DIR}/packaging/harvest_payload.sh" \
  --manifest-file "${MANIFEST_FILE}" \
  --wix-fragment "${WIX_FILE}"

# Test 1: Manifest exists and has non-zero size
if [ ! -s "${MANIFEST_FILE}" ]; then
  printf '[FAIL] Manifest file was not created or is empty
' >&2
  exit 1
fi
printf '[PASS] Manifest generated with %s files
' "$(wc -l < "${MANIFEST_FILE}" | tr -d ' ')"

# Test 2: Essential engine files are included
for _req in "libscript.sh" "libscript.cmd" "_lib/_common/component_core.cmd" "stacks/cms/openedx/setup_generic.cmd" "stacks/cms/openedx/cli.cmd"; do
  if ! grep -Fxq "$_req" "${MANIFEST_FILE}"; then
    printf '[FAIL] Required file missing from harvest manifest: %s
' "$_req" >&2
    exit 1
  fi
done
printf '[PASS] All essential engine and stack files present in manifest
'

# Test 3: Excluded directories and patterns are strictly absent
for _bad in ".git/" "tests_tmp/" ".vagrant/" ".tmp" ".log" ".ppm" ".msi" ".wixobj"; do
  if grep -Fq "$_bad" "${MANIFEST_FILE}"; then
    printf '[FAIL] Prohibited pattern present in harvest manifest: %s
' "$_bad" >&2
    exit 1
  fi
done
printf '[PASS] Prohibited patterns and directories correctly excluded
'

# Test 4: WiX fragment exists and has valid structure
if [ ! -s "${WIX_FILE}" ]; then
  printf '[FAIL] WiX fragment was not created or is empty
' >&2
  exit 1
fi

if ! grep -Fq '<ComponentGroup Id="LibscriptHarvestedComponents">' "${WIX_FILE}"; then
  printf '[FAIL] ComponentGroup element missing from WiX fragment
' >&2
  exit 1
fi

if ! grep -Fq 'KeyPath="yes"' "${WIX_FILE}"; then
  printf '[FAIL] File KeyPath attribute missing from WiX fragment
' >&2
  exit 1
fi
printf '[PASS] WiX fragment validated successfully
'

# Test 5: Verify --include-cache and WiX multi-cab DiskId partitioning
printf '[TEST 5] Verifying --include-cache and WiX multi-cab DiskId partitioning...\n'
MOCK_CACHE_DIR="${TEST_TMP_DIR}/mock_cache"
mkdir -p "${MOCK_CACHE_DIR}/runtimes" "${MOCK_CACHE_DIR}/databases" "${MOCK_CACHE_DIR}/codebase"
printf 'python runtime' > "${MOCK_CACHE_DIR}/runtimes/python-3.11.zip"
printf 'mysql db' > "${MOCK_CACHE_DIR}/databases/mysql-8.0.zip"
printf 'edx codebase' > "${MOCK_CACHE_DIR}/codebase/edx-platform.zip"

OFFLINE_MANIFEST="${TEST_TMP_DIR}/offline_manifest.txt"
OFFLINE_WIX="${TEST_TMP_DIR}/offline_fragment.wxs"

"${LIBSCRIPT_ROOT_DIR}/packaging/harvest_payload.sh" \
  --root-dir "${LIBSCRIPT_ROOT_DIR}" \
  --manifest-file "${OFFLINE_MANIFEST}" \
  --wix-fragment "${OFFLINE_WIX}" \
  --include-cache "${MOCK_CACHE_DIR}" >/dev/null

if ! grep -q '^cache/runtimes/python-3.11.zip' "${OFFLINE_MANIFEST}"; then
  printf '[FAIL] Offline cache files missing from offline manifest\n' >&2
  exit 1
fi

if ! grep -Fq 'DiskId="2"' "${OFFLINE_WIX}"; then
  printf '[FAIL] DiskId="2" missing for runtimes in offline WiX fragment\n' >&2
  exit 1
fi

if ! grep -Fq 'DiskId="3"' "${OFFLINE_WIX}"; then
  printf '[FAIL] DiskId="3" missing for databases in offline WiX fragment\n' >&2
  exit 1
fi

if ! grep -Fq 'DiskId="4"' "${OFFLINE_WIX}"; then
  printf '[FAIL] DiskId="4" missing for codebase in offline WiX fragment\n' >&2
  exit 1
fi

if ! grep -Fq '<ComponentGroup Id="LibscriptOfflineCacheComponents">' "${OFFLINE_WIX}"; then
  printf '[FAIL] LibscriptOfflineCacheComponents missing from offline WiX fragment\n' >&2
  exit 1
fi

# Ensure standard online manifest has NO cache entries
if grep -q '^cache/' "${MANIFEST_FILE}"; then
  printf '[FAIL] Base online manifest must not contain cache/ entries\n' >&2
  exit 1
fi

printf '[PASS] Offline cache harvesting and multi-cabinet WiX fragment verified\n'

printf '=== All Harvest Payload Tests Passed ===
'
exit 0
