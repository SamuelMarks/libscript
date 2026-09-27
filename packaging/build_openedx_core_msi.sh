#!/bin/sh
# ## Overview
# Builds the standalone openedx-core.msi Windows Installer package.
# Packages the LMS and Studio core applications, management CLI, and configuration.
# Supports lightweight online installer and air-gapped offline installer with pre-bundled dependencies.
#
# ## Usage
#   ./packaging/build_openedx_core_msi.sh [OPTIONS]
#
# ## Parameters
#   --version <ver>          Package version (default: 22.1.0)
#   --variant <var>          Installer variant: online, offline, or all (default: all)
#   --online                 Shorthand for --variant online
#   --offline                Shorthand for --variant offline
#   --out <name>             Output file base name or path (default: dist/msi/openedx-core-<version>.msi)
#   --out-dir <dir>          Output directory (default: dist/msi)
#   --offline-source <dir>   Cache directory containing source archives/binaries (default: cache)
#   --hydrate                Force hydration of offline cache before building
#   --allow-mock             Allow fallback to mock assets if offline assets cannot be acquired
#   --branch <name>          Branch or tag ref (optional)
#   --help, -h               Show this help text

set -eu

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
OUT_FILE=""
BRANCH=""
OUT_DIR="${LIBSCRIPT_ROOT_DIR}/dist/msi"
OFFLINE_SOURCE="${LIBSCRIPT_ROOT_DIR}/cache"
HYDRATE=0
ALLOW_MOCK=0

# ## show_help
# Displays command usage documentation.
show_help() {
  cat << EOF_HELP
Open edX Core MSI Builder

Usage:
  ./packaging/build_openedx_core_msi.sh [OPTIONS]

Options:
  --version <ver>          Package version (default: 22.1.0)
  --variant <var>          Installer variant (online, offline, or all; default: all)
  --online                 Build lightweight online installer
  --offline                Build air-gapped offline installer with embedded payload
  --out <name>             Output file base name or path
  --out-dir <dir>          Output directory (default: dist/msi)
  --offline-source <dir>   Offline cache directory containing binary archives (default: cache)
  --hydrate                Force hydration of offline cache before building
  --allow-mock             Allow fallback to mock assets if offline assets cannot be acquired
  --branch <name>          Branch or tag ref (optional)
  --help, -h               Show this help text
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
    --online)
      VARIANT="online"
      shift
      ;;
    --offline)
      VARIANT="offline"
      shift
      ;;
    --out)
      OUT_FILE="$2"
      shift 2
      ;;
    --out-dir)
      OUT_DIR="$2"
      shift 2
      ;;
    --offline-source)
      OFFLINE_SOURCE="$2"
      shift 2
      ;;
    --hydrate)
      HYDRATE=1
      shift
      ;;
    --allow-mock)
      ALLOW_MOCK=1
      shift
      ;;
    --branch)
      BRANCH="$2"
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

: "${BRANCH:=}"

BUNDLE_JSON="${LIBSCRIPT_ROOT_DIR}/stacks/cms/openedx/offline_bundle.json"

# ## build_single_variant
# Builds a specific Open edX Core installer variant (online or offline).
#
# ## Parameters
#   $1 - Variant ("online" or "offline")
build_single_variant() {
  _v="$1"
  STAGE_ROOT="${LIBSCRIPT_ROOT_DIR}/tmp/stage_openedx_core_${_v}"
  rm -rf "$STAGE_ROOT"
  mkdir -p "$STAGE_ROOT" "$OUT_DIR"

  # Stage Open edX scripts and configuration into staging directory
  cp -R "${LIBSCRIPT_ROOT_DIR}/stacks/cms/openedx/." "$STAGE_ROOT/" 2>/dev/null || true

  if [ "$_v" = "offline" ]; then
    _need_hydrate=0
    if [ ! -d "${OFFLINE_SOURCE}/codebase" ] || [ ! -d "${OFFLINE_SOURCE}/wheels" ]; then
      _need_hydrate=1
    fi

    if [ "$HYDRATE" -eq 1 ] || [ "$_need_hydrate" -eq 1 ]; then
      if [ "$ALLOW_MOCK" -eq 0 ]; then
        printf '[INFO] Hydrating codebase and wheels before building offline core...
'
        "${SCRIPT_DIR}/hydrate_offline_cache.sh" --manifest "$BUNDLE_JSON" --cache-dir "$OFFLINE_SOURCE" --codebase --wheels || true
      fi
    fi

    if [ -d "${OFFLINE_SOURCE}/codebase" ]; then
      mkdir -p "$STAGE_ROOT/codebase"
      cp -R "${OFFLINE_SOURCE}/codebase/." "$STAGE_ROOT/codebase/" 2>/dev/null || true
    elif [ "$ALLOW_MOCK" -eq 1 ]; then
      mkdir -p "$STAGE_ROOT/codebase"
      printf 'Mock Open edX codebase archive
' > "$STAGE_ROOT/codebase/mock_codebase.zip"
    fi

    if [ -d "${OFFLINE_SOURCE}/wheels" ]; then
      mkdir -p "$STAGE_ROOT/wheels"
      cp -R "${OFFLINE_SOURCE}/wheels/." "$STAGE_ROOT/wheels/" 2>/dev/null || true
    elif [ "$ALLOW_MOCK" -eq 1 ]; then
      mkdir -p "$STAGE_ROOT/wheels"
      printf 'Mock wheel package
' > "$STAGE_ROOT/wheels/mock_wheel.whl"
    fi
  fi

  MAIN_WXS="${LIBSCRIPT_ROOT_DIR}/tmp/openedx_core_${_v}_main.wxs"
  PAYLOAD_WXS="${LIBSCRIPT_ROOT_DIR}/tmp/openedx_core_${_v}_payload.wxs"

  "${SCRIPT_DIR}/template_openedx_core_msi.sh" \
    --version "$VERSION" \
    --variant "$_v" \
    --out "$MAIN_WXS"

  "${SCRIPT_DIR}/harvest_payload.sh" \
    --source-dir "$STAGE_ROOT" \
    --wix-fragment "$PAYLOAD_WXS" \
    --component-group "OpenEdXCorePayloadComponents" \
    --directory-id "INSTALLFOLDER"

  if [ -n "$OUT_FILE" ]; then
    case "$OUT_FILE" in
      *.msi|*.MSI) _base="${OUT_FILE%.*}" ;;
      *) _base="$OUT_FILE" ;;
    esac
    if [ "$VARIANT" = "all" ]; then
      if [ "$_v" = "offline" ]; then
        TARGET_MSI="${_base}-offline.msi"
      else
        TARGET_MSI="${_base}.msi"
      fi
    else
      TARGET_MSI="${_base}.msi"
    fi
  else
    if [ "$_v" = "offline" ]; then
      TARGET_MSI="${OUT_DIR}/openedx-core-offline-${VERSION}.msi"
    else
      TARGET_MSI="${OUT_DIR}/openedx-core-${VERSION}.msi"
    fi
  fi

  _target_dir=$(dirname "$TARGET_MSI")
  mkdir -p "$_target_dir" "$OUT_DIR"

  if command -v wixl >/dev/null 2>&1; then
    printf '[INFO] Compiling Open edX Core %s MSI via wixl: %s
' "$_v" "$TARGET_MSI"
    _wixl_main="${MAIN_WXS}_clean.wxs"
    _wixl_payload="${PAYLOAD_WXS}_clean.wxs"
    sed 's/ Schedule="[^"]*"//g; s/ Permanent="[^"]*"//g; s/ NeverOverwrite="[^"]*"//g; /<CustomAction/d; /<InstallExecuteSequence>/,/<\/InstallExecuteSequence>/d' "$MAIN_WXS" > "$_wixl_main"
    sed 's/ DiskId="[0-9]*"/ DiskId="1"/g' "$PAYLOAD_WXS" > "$_wixl_payload"
    wixl -a x64 -o "$TARGET_MSI" "$_wixl_main" "$_wixl_payload"
    rm -f "$_wixl_main" "$_wixl_payload"
  elif command -v candle.exe >/dev/null 2>&1 && command -v light.exe >/dev/null 2>&1; then
    printf '[INFO] Compiling Open edX Core %s MSI via WiX toolset: %s
' "$_v" "$TARGET_MSI"
    candle.exe -nologo -arch x64 -out "${LIBSCRIPT_ROOT_DIR}/tmp/openedx_core_${_v}_main.wixobj" "$MAIN_WXS" || exit 1
    candle.exe -nologo -arch x64 -out "${LIBSCRIPT_ROOT_DIR}/tmp/openedx_core_${_v}_payload.wixobj" "$PAYLOAD_WXS" || exit 1
    light.exe -nologo -sval -ext WixUIExtension -out "$TARGET_MSI" "${LIBSCRIPT_ROOT_DIR}/tmp/openedx_core_${_v}_main.wixobj" "${LIBSCRIPT_ROOT_DIR}/tmp/openedx_core_${_v}_payload.wixobj" || exit 1
  else
    printf '[WARN] Neither wixl nor WiX toolset found. Created XML manifests at %s
' "$MAIN_WXS"
  fi

  if [ ! -f "$TARGET_MSI" ]; then
    printf '[ERROR] Target Core MSI was not generated: %s
' "$TARGET_MSI" >&2
    exit 1
  fi

  _target_abs=$(cd -- "$(dirname "$TARGET_MSI")" && pwd)/$(basename "$TARGET_MSI")
  _out_dir_abs=$(cd -- "$OUT_DIR" 2>/dev/null && pwd || true)
  if [ -n "$_out_dir_abs" ] && [ "$(dirname "$_target_abs")" != "$_out_dir_abs" ]; then
    mkdir -p "$OUT_DIR"
    cp -f "$TARGET_MSI" "$OUT_DIR/" 2>/dev/null || true
  fi

  _fsize=$(wc -c < "$TARGET_MSI" | tr -d ' ')
  printf '[PASS] Successfully built Open edX Core MSI (%s): %s (%s bytes)
' "$_v" "$TARGET_MSI" "$_fsize"
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
