#!/bin/sh
# ## Overview
# Unit and integration tests for WiX MSI installer generation.
#
# ## Usage
# ./tests/test_msi_generation.sh

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

TEST_TMP_DIR="${LIBSCRIPT_ROOT_DIR}/tests_tmp/test_msi_gen_$$"
mkdir -p "$TEST_TMP_DIR"

# ## cleanup
# Cleans up temporary test artifacts upon exit or preserves them on error.
# shellcheck disable=SC2329
cleanup() {
  rm -rf "$TEST_TMP_DIR"
}
trap cleanup EXIT INT TERM

printf '=== Testing WiX MSI Installer Generation ===\n'

# 1. Create a dummy test license, icon, and packaging.json
echo "LibScript Test License Agreement" > "$TEST_TMP_DIR/LICENSE.txt"
touch "$TEST_TMP_DIR/test_icon.ico"
touch "$TEST_TMP_DIR/test_banner_top.bmp"
touch "$TEST_TMP_DIR/test_banner_side.bmp"

WXS_FILE="${TEST_TMP_DIR}/TestPackage.wxs"
"${LIBSCRIPT_ROOT_DIR}/packaging/template_msi.sh" "${LIBSCRIPT_ROOT_DIR}/_lib/web-apps/wordpress" --out "$WXS_FILE"

if [ ! -f "$WXS_FILE" ]; then
  printf '[FAIL] Expected .wxs file was not generated\n' >&2
  exit 1
fi
printf '[PASS] Generated %s\n' "$WXS_FILE"

# 3. Verify XML contents
grep -q '<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">' "$WXS_FILE" || { echo "[FAIL] Missing Wix root"; exit 1; }
grep -q 'Dialog Id="Dlg_DatabaseConfig"' "$WXS_FILE" || { echo "[FAIL] Missing Dlg_DatabaseConfig"; exit 1; }
grep -q 'USER_DB_STRATEGY' "$WXS_FILE" || { echo "[FAIL] Missing USER_DB_STRATEGY"; exit 1; }
grep -q 'MsiHiddenProperties' "$WXS_FILE" || { echo "[FAIL] Missing MsiHiddenProperties"; exit 1; }

printf '[PASS] All XML assertions passed!\n'

# 4. If an MSI was generated (e.g. via msi-rs, candle/light, or wixl), verify its existence
MSI_FILE="${TEST_TMP_DIR}/TestPackage.msi"
if [ -f "$MSI_FILE" ]; then
  printf '[PASS] Successfully generated MSI: %s (size: %s bytes)\n' "$MSI_FILE" "$(wc -c < "$MSI_FILE" | tr -d ' ')"
else
  printf '[INFO] Note: msi-rs / WiX tools (candle/light/wix) not present or skipped, .wxs is validated.\n'
fi

printf '=== All MSI tests completed successfully ===\n'
exit 0
