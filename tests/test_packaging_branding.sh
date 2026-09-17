#!/bin/sh
# ## Overview
# Unit and integration tests for cross-platform packaging branding assets.
#
# ## Usage
# ./tests/test_packaging_branding.sh

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

TEST_TMP_DIR="${LIBSCRIPT_ROOT_DIR}/tests_tmp/test_branding_$$"
mkdir -p "$TEST_TMP_DIR"

# ## cleanup
# Cleans up temporary test artifacts upon exit or preserves them on error.
cleanup() {
  if [ $? -eq 0 ]; then
    rm -rf "$TEST_TMP_DIR"
  else
    printf 'Preserving test artifacts in %s for inspection\n' "$TEST_TMP_DIR"
  fi
}
trap cleanup EXIT INT TERM

printf '=== Testing Cross-Platform Installer Branding ===
'

# 1. Setup mock assets
echo "Custom Enterprise License Agreement terms" > "$TEST_TMP_DIR/CUSTOM_LICENSE.txt"
touch "$TEST_TMP_DIR/custom_icon.ico"
touch "$TEST_TMP_DIR/banner_top.bmp"
touch "$TEST_TMP_DIR/banner_side.bmp"

export APP_NAME="BrandApp"
export APP_VERSION="2.5.0"
export APP_PUBLISHER="BrandCorp"
export PRODUCT_CODE="*"
export UPGRADE_CODE="12345678-1234-5678-1234-567812345678"
export OUT_FILE="$TEST_TMP_DIR/BrandApp"
export ICON_PATH="$TEST_TMP_DIR/custom_icon.ico"
export BANNER_TOP_PATH="$TEST_TMP_DIR/banner_top.bmp"
export BANNER_SIDE_PATH="$TEST_TMP_DIR/banner_side.bmp"
export LICENSE_PATH="$TEST_TMP_DIR/CUSTOM_LICENSE.txt"

# 2. Test Inno Setup generation
INNO_FILE="${TEST_TMP_DIR}/BrandApp.iss"
"${LIBSCRIPT_ROOT_DIR}/packaging/template_inno.sh" > "$INNO_FILE"
grep -q "WizardSmallImageFile=$BANNER_TOP_PATH" "$INNO_FILE" || { echo "[FAIL] Inno missing WizardSmallImageFile"; exit 1; }
grep -q "WizardImageFile=$BANNER_SIDE_PATH" "$INNO_FILE" || { echo "[FAIL] Inno missing WizardImageFile"; exit 1; }
grep -q "LicenseFile=$LICENSE_PATH" "$INNO_FILE" || { echo "[FAIL] Inno missing LicenseFile"; exit 1; }
printf '[PASS] Inno Setup branding assertions passed
'

# 3. Test NSIS generation
NSIS_FILE="${TEST_TMP_DIR}/BrandApp.nsi"
"${LIBSCRIPT_ROOT_DIR}/packaging/template_nsis.sh" > "$NSIS_FILE"
grep -q "!define MUI_HEADERIMAGE_BITMAP" "$NSIS_FILE" || { echo "[FAIL] NSIS missing MUI_HEADERIMAGE_BITMAP"; exit 1; }
grep -q "!define MUI_WELCOMEFINISHPAGE_BITMAP" "$NSIS_FILE" || { echo "[FAIL] NSIS missing MUI_WELCOMEFINISHPAGE_BITMAP"; exit 1; }
grep -q "Page license" "$NSIS_FILE" || { echo "[FAIL] NSIS missing Page license"; exit 1; }
printf '[PASS] NSIS branding assertions passed\n'

# 4. Test WiX MSI generation
"${LIBSCRIPT_ROOT_DIR}/packaging/template_msi.sh"
WXS_FILE="${TEST_TMP_DIR}/BrandApp.wxs"
grep -q 'WixVariable Id="WixUIBannerBmp"' "$WXS_FILE" || { echo "[FAIL] MSI missing WixUIBannerBmp"; exit 1; }
grep -q 'WixVariable Id="WixUIDialogBmp"' "$WXS_FILE" || { echo "[FAIL] MSI missing WixUIDialogBmp"; exit 1; }
grep -q 'WixVariable Id="WixUILicenseRtf"' "$WXS_FILE" || { echo "[FAIL] MSI missing WixUILicenseRtf"; exit 1; }
grep -q 'Dialog Id="Dlg_License"' "$WXS_FILE" || { echo "[FAIL] MSI missing Dlg_License"; exit 1; }
printf '[PASS] WiX MSI branding assertions passed
'

printf '=== All branding tests completed successfully! ===
'
exit 0
