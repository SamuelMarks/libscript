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

TEST_TMP_DIR="${LIBSCRIPT_ROOT_DIR}/tests_tmp/test_msi_gen_$$"
mkdir -p "$TEST_TMP_DIR"

# ## cleanup
# Cleans up temporary test artifacts upon exit or preserves them on error.
cleanup() {
  if [ $? -eq 0 ]; then
    rm -rf "$TEST_TMP_DIR"
  else
    printf 'Preserving test artifacts in %s for inspection
' "$TEST_TMP_DIR"
  fi
}
trap cleanup EXIT INT TERM

printf '=== Testing WiX MSI Installer Generation ===
'

# 1. Create a dummy test license and test icon
echo "LibScript Test License Agreement" > "$TEST_TMP_DIR/LICENSE.txt"
touch "$TEST_TMP_DIR/test_icon.ico"
touch "$TEST_TMP_DIR/test_banner_top.bmp"
touch "$TEST_TMP_DIR/test_banner_side.bmp"

# 2. Invoke template_msi.sh
export OUT_FILE="$TEST_TMP_DIR/TestPackage"
export APP_NAME="TestStack"
export APP_VERSION="1.0.0"
export APP_PUBLISHER="LibScriptTest"
export PRODUCT_CODE="*"
export UPGRADE_CODE="12345678-1234-5678-1234-567812345678"
export install_scope="perMachine"
export WELCOME_TEXT="Welcome to TestStack"
export ICON_PATH="$TEST_TMP_DIR/test_icon.ico"
export BANNER_TOP_PATH="$TEST_TMP_DIR/test_banner_top.bmp"
export BANNER_SIDE_PATH="$TEST_TMP_DIR/test_banner_side.bmp"
export LICENSE_PATH="$TEST_TMP_DIR/LICENSE.txt"
export AGREEMENT_TEXT="I accept the test terms"

# Provide sample dependencies: mysql, memcached, meilisearch, python
"${LIBSCRIPT_ROOT_DIR}/packaging/template_msi.sh" mysql 8.4 memcached 1.6 meilisearch 1.3 python 3.11

WXS_FILE="${TEST_TMP_DIR}/TestPackage.wxs"
if [ ! -f "$WXS_FILE" ]; then
  printf '[FAIL] Expected .wxs file was not generated
' >&2
  exit 1
fi
printf '[PASS] Generated %s
' "$WXS_FILE"

# 3. Verify XML contents
grep -q 'WixVariable Id="WixUILicenseRtf"' "$WXS_FILE" || { echo "[FAIL] Missing WixUILicenseRtf"; exit 1; }
grep -q 'WixVariable Id="WixUIBannerBmp"' "$WXS_FILE" || { echo "[FAIL] Missing WixUIBannerBmp"; exit 1; }
grep -q 'WixVariable Id="WixUIDialogBmp"' "$WXS_FILE" || { echo "[FAIL] Missing WixUIDialogBmp"; exit 1; }
grep -q 'Dialog Id="Dlg_License"' "$WXS_FILE" || { echo "[FAIL] Missing Dlg_License"; exit 1; }
grep -q 'Control Id="Chk_mysql"' "$WXS_FILE" || { echo "[FAIL] Missing Chk_mysql"; exit 1; }
grep -q 'Control Id="Chk_memcached"' "$WXS_FILE" || { echo "[FAIL] Missing Chk_memcached"; exit 1; }
grep -q 'Control Id="Chk_meilisearch"' "$WXS_FILE" || { echo "[FAIL] Missing Chk_meilisearch"; exit 1; }
grep -q 'Control Id="Chk_python"' "$WXS_FILE" || { echo "[FAIL] Missing Chk_python"; exit 1; }
grep -q 'MsiHiddenProperties' "$WXS_FILE" || { echo "[FAIL] Missing MsiHiddenProperties"; exit 1; }
grep -q 'Type="PathEdit"' "$WXS_FILE" || { echo "[FAIL] Missing PathEdit browse control for python"; exit 1; }

printf '[PASS] All XML assertions passed!
'

# 4. If an MSI was generated (e.g. via wixl or candle/light), verify its existence
MSI_FILE="${TEST_TMP_DIR}/TestPackage.msi"
if [ -f "$MSI_FILE" ]; then
  printf '[PASS] Successfully generated MSI: %s (size: %s bytes)
' "$MSI_FILE" "$(wc -c < "$MSI_FILE" | tr -d ' ')"
else
  printf '[INFO] Note: WiX tools (wix.exe/candle.exe/wixl) not present or skipped, .wxs is validated.
'
fi

printf '=== All MSI tests completed successfully ===
'
exit 0
