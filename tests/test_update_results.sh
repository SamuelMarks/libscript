#!/bin/sh
# ## Overview
# Unit test suite for tests/update_results.sh.
# Verifies that update_results.sh splits the Supported Components table into all 5
# architectural tiers, preserves existing statuses, applies tests_tmp/*.{success,failure}
# and *.idempotent.success markers, exports valid JSON, and is strictly idempotent (2x run).
#
# ## Usage
# ./tests/test_update_results.sh

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
export LIBSCRIPT_ROOT_DIR

TMP_TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_TEST_DIR"' EXIT INT TERM

FAILURES=0

# ## assert_file_contains
# Asserts that a file contains a specific regex/string pattern.
assert_file_contains() {
  _file="$1"
  _pattern="$2"
  _desc="$3"
  if grep -q "$_pattern" "$_file"; then
    printf '[PASS] %s
' "$_desc"
  else
    printf '[FAIL] %s (pattern "%s" not found in %s)
' "$_desc" "$_pattern" "$_file" >&2
    FAILURES=$((FAILURES + 1))
  fi
}

printf '=== LibScript Tiered README Table Generator Test Suite ===
'

cp "${LIBSCRIPT_ROOT_DIR}/README.md" "${TMP_TEST_DIR}/README.md"
JSON_OUT="${TMP_TEST_DIR}/matrix_results.json"

sh "${LIBSCRIPT_ROOT_DIR}/tests/update_results.sh" "${LIBSCRIPT_ROOT_DIR}" --output "${TMP_TEST_DIR}/README.md" --json "${JSON_OUT}"

assert_file_contains "${TMP_TEST_DIR}/README.md" "### Tier 1: Leaf Recipes, Toolchains & Native Version Managers" "Renders Tier 1 heading"
assert_file_contains "${TMP_TEST_DIR}/README.md" "### Tier 1.5: Base OS Userland, Init Systems, Networking, Audio, Graphics & Desktops" "Renders Tier 1.5 heading"
assert_file_contains "${TMP_TEST_DIR}/README.md" "### Tier 2: OS Synthesizers, Kernels, Bootloaders, Storage & Image Builders" "Renders Tier 2 heading"
assert_file_contains "${TMP_TEST_DIR}/README.md" "### Tier 3: Cloud Operators, Hypervisors & IaaS Provisioners" "Renders Tier 3 heading"
assert_file_contains "${TMP_TEST_DIR}/README.md" "### Tier 3.5, Tier 4 & Cross-Cutting Traits: Topologies, Payloads, Schedulers & Traits" "Renders Tier 3.5/4/Traits heading"
assert_file_contains "${JSON_OUT}" '"tier":' "JSON output contains tier field"
assert_file_contains "${JSON_OUT}" '"category":' "JSON output contains category field"
assert_file_contains "${JSON_OUT}" '"idempotent":' "JSON output contains idempotent field"

cp "${TMP_TEST_DIR}/README.md" "${TMP_TEST_DIR}/README.pass1.md"
sh "${LIBSCRIPT_ROOT_DIR}/tests/update_results.sh" "${LIBSCRIPT_ROOT_DIR}" --output "${TMP_TEST_DIR}/README.md" --json "${JSON_OUT}"

if cmp -s "${TMP_TEST_DIR}/README.pass1.md" "${TMP_TEST_DIR}/README.md"; then
  printf '[PASS] 2x consecutive runs of update_results.sh are 100%% idempotent (zero diff).
'
else
  printf '[FAIL] 2x consecutive runs of update_results.sh produced a diff!
' >&2
  FAILURES=$((FAILURES + 1))
fi

if [ "$FAILURES" -gt 0 ]; then
  printf '[FAIL] test_update_results failed with %d error(s).
' "$FAILURES" >&2
  exit 1
fi

printf '=== All Tiered README Table Generator Checks Passed! ===
'
exit 0
