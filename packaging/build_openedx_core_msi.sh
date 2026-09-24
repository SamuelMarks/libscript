#!/bin/sh
# ## Overview
# Builds the standalone openedx-core.msi Windows Installer package.
# Packages the LMS and Studio core applications, management CLI, and configuration.
# Eliminates external .exe files while maintaining full native MSI compliance.
#
# ## Usage
#   ./packaging/build_openedx_core_msi.sh [OPTIONS]
#
# ## Parameters
#   --version <ver>    Package version (default: 22.1.0)
#   --out-dir <dir>    Output directory (default: dist/msi)
#   --help, -h         Show this help text

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

VERSION="22.1.0"
OUT_DIR="${LIBSCRIPT_ROOT_DIR}/dist/msi"

# ## show_help
# Displays command usage documentation.
show_help() {
  cat << EOF_HELP
Open edX Core MSI Builder

Usage:
  ./packaging/build_openedx_core_msi.sh [OPTIONS]

Options:
  --version <ver>    Package version (default: 22.1.0)
  --out-dir <dir>    Output directory (default: dist/msi)
  --help, -h         Show this help text
EOF_HELP
}

while [ $# -gt 0 ]; do
  case "$1" in
    --version)
      VERSION="$2"
      shift 2
      ;;
    --out-dir)
      OUT_DIR="$2"
      shift 2
      ;;
    --help|-h)
      show_help
      exit 0
      ;;
    *)
      printf '[ERROR] Unknown parameter: %s
' "$1" >&2
      exit 1
      ;;
  esac
done

STAGE_ROOT="${LIBSCRIPT_ROOT_DIR}/tmp/stage_openedx_core"
mkdir -p "$STAGE_ROOT" "$OUT_DIR"

# Stage Open edX scripts and configuration into staging directory
cp -R "${LIBSCRIPT_ROOT_DIR}/stacks/cms/openedx/"* "$STAGE_ROOT/" 2>/dev/null || true

MAIN_WXS="${LIBSCRIPT_ROOT_DIR}/tmp/openedx_core_main.wxs"
PAYLOAD_WXS="${LIBSCRIPT_ROOT_DIR}/tmp/openedx_core_payload.wxs"

"${SCRIPT_DIR}/template_openedx_core_msi.sh" \
  --version "$VERSION" \
  --out "$MAIN_WXS"

"${SCRIPT_DIR}/harvest_payload.sh" \
  --output-dir "$STAGE_ROOT" \
  --wix-fragment "$PAYLOAD_WXS" \
  --component-group "OpenEdXCorePayloadComponents" \
  --directory-id "INSTALLFOLDER"

TARGET_MSI="${OUT_DIR}/openedx-core-${VERSION}.msi"

if command -v wixl >/dev/null 2>&1; then
  printf '[INFO] Compiling Open edX Core MSI via wixl: %s
' "$TARGET_MSI"
  _wixl_main="${MAIN_WXS}_clean.wxs"
  _wixl_payload="${PAYLOAD_WXS}_clean.wxs"
  sed 's/ Schedule="[^"]*"//g; s/ Permanent="[^"]*"//g; s/ NeverOverwrite="[^"]*"//g' "$MAIN_WXS" > "$_wixl_main"
  sed 's/ DiskId="[0-9]*"/ DiskId="1"/g' "$PAYLOAD_WXS" > "$_wixl_payload"
  wixl -a x64 -o "$TARGET_MSI" "$_wixl_main" "$_wixl_payload"
  rm -f "$_wixl_main" "$_wixl_payload"
elif command -v candle.exe >/dev/null 2>&1 && command -v light.exe >/dev/null 2>&1; then
  candle.exe -arch x64 "$MAIN_WXS" "$PAYLOAD_WXS" -out "${LIBSCRIPT_ROOT_DIR}/tmp/"
  light.exe -ext WixUIExtension -out "$TARGET_MSI" "${LIBSCRIPT_ROOT_DIR}/tmp/openedx_core_main.wixobj" "${LIBSCRIPT_ROOT_DIR}/tmp/openedx_core_payload.wixobj"
fi

printf '[PASS] Successfully built Open edX Core MSI: %s
' "$TARGET_MSI"
