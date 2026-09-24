#!/bin/sh
# ## Overview
# Validates WiX Windows Installer (.msi) multi-license dialog sequence generation.
# Asserts that each bundled component receives a dedicated license agreement dialog,
# individual acceptance checkbox property, sequential UI routing, and unattended guard.
#
# ## Usage
# ./tests/test_msi_multi_license.sh

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

TEST_TMP_DIR="${LIBSCRIPT_ROOT_DIR}/tests_tmp/test_msi_multi_license_$$"
mkdir -p "$TEST_TMP_DIR"

# ## cleanup
# Removes temporary test directory on script exit.
# shellcheck disable=SC2329
cleanup() {
  rm -rf "$TEST_TMP_DIR"
}
trap cleanup EXIT INT TERM

printf '=== Testing WiX MSI Multi-License Dialog Sequence ===\n'

# ## assert_wxs_contains
# Asserts that the generated WiX manifest contains a specified string pattern.
assert_wxs_contains() {
  _pattern="$1"
  _desc="$2"
  if grep -Fq "$_pattern" "$TEST_WXS"; then
    printf '[PASS] Verified: %s
' "$_desc"
  else
    printf '[FAIL] Missing expected pattern in WiX manifest: %s
' "$_pattern" >&2
    printf 'Description: %s
' "$_desc" >&2
    exit 1
  fi
}

TEST_WXS="${TEST_TMP_DIR}/test_multi_license.wxs"

# Generate Open edX WiX manifest which bundles MySQL, Redis, MongoDB, Python, Node, Meilisearch
"${LIBSCRIPT_ROOT_DIR}/packaging/build_msi.sh" "stacks/cms/openedx" \
  --out "${TEST_TMP_DIR}/test_openedx" \
  --variant online

if [ -f "${TEST_TMP_DIR}/test_openedx.wxs" ]; then
  cp "${TEST_TMP_DIR}/test_openedx.wxs" "$TEST_WXS"
elif [ -f "${TEST_TMP_DIR}/test_openedx.candle.wxs" ]; then
  cp "${TEST_TMP_DIR}/test_openedx.candle.wxs" "$TEST_WXS"
else
  printf '[FAIL] Could not find generated WiX manifest at %s
' "${TEST_TMP_DIR}/test_openedx.wxs" >&2
  exit 1
fi

printf '[PASS] Successfully generated test WiX manifest: %s\n' "$TEST_WXS"

if command -v xmllint >/dev/null 2>&1; then
  if xmllint --noout "$TEST_WXS"; then
    printf '[PASS] Validated XML syntax via xmllint: %s\n' "$TEST_WXS"
  else
    printf '[FAIL] Invalid XML syntax in generated WiX manifest: %s\n' "$TEST_WXS" >&2
    exit 1
  fi
fi

# 1. Verify Consolidated EULA Dialog with single I Agree button
assert_wxs_contains 'Dialog Id="Dlg_License"' "Top-level EULA Dialog exists"
assert_wxs_contains 'Property="LICENSE_ACCEPTED"' "License acceptance property configured"
assert_wxs_contains 'Text="I Agree"' "Button text is I Agree instead of Next>"

# 2. Verify InstallUISequence Routing (Single License step)
assert_wxs_contains '<Show Dialog="Dlg_Welcome" After="CostFinalize">NOT Installed</Show>' "Welcome dialog shown after CostFinalize"
assert_wxs_contains '<Show Dialog="Dlg_License" After="Dlg_Welcome">NOT Installed</Show>' "License shown after Welcome"
assert_wxs_contains '<Show Dialog="Dlg_SetupType" After="Dlg_License">NOT Installed</Show>' "SetupType directly after License"

# 3. Verify Unattended Silent Installation Guard
assert_wxs_contains 'CustomAction Id="CA_AbortNoLicense"' "Unattended install license validation custom action"
assert_wxs_contains 'AGREE_ALL_LICENSES="1"' "Blanket opt-in property AGREE_ALL_LICENSES supported"
assert_wxs_contains '<Custom Action="CA_AbortNoLicense" Before="InstallInitialize">' "License agreement check scheduled before InstallInitialize"

printf '=== All WiX MSI multi-license tests passed successfully! ===
'
exit 0
