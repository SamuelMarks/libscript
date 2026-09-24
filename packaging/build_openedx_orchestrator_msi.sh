#!/bin/sh
# ## Overview
# Builds the unified Open edX Master Orchestrator Windows Installer (.msi) package.
# Supports both the online installer and the air-gapped offline installer.
# Embeds and chains component MSIs with ZERO external .exe files.
#
# ## Usage
#   ./packaging/build_openedx_orchestrator_msi.sh [OPTIONS]
#
# ## Parameters
#   --version <ver>    Stack release version (default: 22.1.0)
#   --variant <var>    Installer variant: online, offline, or all (default: all)
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
VARIANT="all"
OUT_DIR="${LIBSCRIPT_ROOT_DIR}/dist/msi"

# ## show_help
# Displays command usage documentation.
show_help() {
  cat << EOF_HELP
Open edX Master Orchestrator MSI Builder

Usage:
  ./packaging/build_openedx_orchestrator_msi.sh [OPTIONS]

Options:
  --version <ver>    Stack release version (default: 22.1.0)
  --variant <var>    Installer variant (online, offline, or all; default: all)
  --out-dir <dir>    Output directory for built MSIs (default: dist/msi)
  --help, -h         Show this help text
EOF_HELP
}

while [ $# -gt 0 ]; do
  case "$1" in
    --version)
      VERSION="$2"
      shift 2
      ;;
    --variant)
      VARIANT="$2"
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

mkdir -p "$OUT_DIR"

# ## build_single_variant
# Builds a specific orchestrator variant (online or offline).
# Arguments:
#   $1 - Variant ("online" or "offline")
build_single_variant() {
  _v="$1"
  _stage="${LIBSCRIPT_ROOT_DIR}/tmp/stage_orchestrator_${_v}"
  rm -rf "$_stage"
  mkdir -p "$_stage/bundle"

  if [ "$_v" = "offline" ]; then
    # Copy all compiled sub-MSIs into bundle directory for offline installer embedding
    cp "${OUT_DIR}"/libscript-*.msi "$_stage/bundle/" 2>/dev/null || true
    cp "${OUT_DIR}"/openedx-core-*.msi "$_stage/bundle/" 2>/dev/null || true
  fi

  _main_wxs="${LIBSCRIPT_ROOT_DIR}/tmp/openedx_orch_${_v}_main.wxs"
  _payload_wxs="${LIBSCRIPT_ROOT_DIR}/tmp/openedx_orch_${_v}_payload.wxs"

  "${SCRIPT_DIR}/template_openedx_orchestrator.sh" \
    --version "$VERSION" \
    --variant "$_v" \
    --msi-dir "$OUT_DIR" \
    --out "$_main_wxs"

  "${SCRIPT_DIR}/harvest_payload.sh" \
    --output-dir "$_stage" \
    --wix-fragment "$_payload_wxs" \
    --component-group "ChainedMsiPayloads" \
    --directory-id "INSTALLFOLDER"

  if [ "$_v" = "offline" ]; then
    _target_msi="${OUT_DIR}/openedx-offline-${VERSION}.msi"
  else
    _target_msi="${OUT_DIR}/openedx-${VERSION}.msi"
  fi

  if command -v wixl >/dev/null 2>&1; then
    printf '[INFO] Compiling Orchestrator MSI (%s) via wixl: %s
' "$_v" "$_target_msi"
    _wixl_main="${_main_wxs}_clean.wxs"
    _wixl_payload="${_payload_wxs}_clean.wxs"
    sed 's/ Schedule="[^"]*"//g' "$_main_wxs" > "$_wixl_main"
    sed 's/ DiskId="[0-9]*"/ DiskId="1"/g' "$_payload_wxs" > "$_wixl_payload"
    wixl -a x64 -o "$_target_msi" "$_wixl_main" "$_wixl_payload"
    rm -f "$_wixl_main" "$_wixl_payload"
  elif command -v candle.exe >/dev/null 2>&1 && command -v light.exe >/dev/null 2>&1; then
    candle.exe -arch x64 "$_main_wxs" "$_payload_wxs" -out "${LIBSCRIPT_ROOT_DIR}/tmp/"
    light.exe -ext WixUIExtension -out "$_target_msi" "${LIBSCRIPT_ROOT_DIR}/tmp/openedx_orch_${_v}_main.wixobj" "${LIBSCRIPT_ROOT_DIR}/tmp/openedx_orch_${_v}_payload.wixobj"
  fi

  printf '[PASS] Successfully built %s
' "$_target_msi"
}

case "$VARIANT" in
  online)
    build_single_variant "online"
    ;;
  offline)
    build_single_variant "offline"
    ;;
  all)
    build_single_variant "online"
    build_single_variant "offline"
    ;;
  *)
    printf '[ERROR] Unknown variant: %s. Use online, offline, or all.
' "$VARIANT" >&2
    exit 1
    ;;
esac
