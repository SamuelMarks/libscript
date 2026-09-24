#!/bin/sh
# ## Overview
# Builds a standalone Windows Installer (.msi) package for an individual LibScript dependency.
# Decomposes full stack deployments into modular, reference-counted component MSIs.
# Supports 100% pure Windows Installer with zero external .exe files.
#
# ## Usage
#   ./packaging/build_component_msi.sh [OPTIONS]
#
# ## Parameters
#   --component <name>       Component to package (mysql, redis, mongodb, python, nodejs, meilisearch)
#   --version <ver>          Component release version (default: auto-detected from offline bundle)
#   --out <name>             Output file base name or path (default: dist/msi/libscript-<component>-<version>.msi)
#   --out-dir <dir>          Target directory for generated .msi (default: dist/msi)
#   --offline-source <dir>   Cache directory containing source archives/binaries (default: cache)
#   --branch <name>          Branch or tag ref (optional)
#   --help, -h               Show this help text

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

COMPONENT=""
VERSION=""
OUT_FILE=""
BRANCH=""
OUT_DIR="${LIBSCRIPT_ROOT_DIR}/dist/msi"
OFFLINE_SOURCE="${LIBSCRIPT_ROOT_DIR}/cache"

# ## show_help
# Displays usage and supported parameters.
show_help() {
  cat << EOF_HELP
LibScript Standalone Component MSI Builder

Usage:
  ./packaging/build_component_msi.sh [OPTIONS]

Options:
  --component <name>       Component identifier (mysql, redis, mongodb, python, nodejs, meilisearch)
  --version <ver>          Release version (defaults to version from offline_bundle.json)
  --out <name>             Output file base name or path
  --out-dir <dir>          Output directory (default: dist/msi)
  --offline-source <dir>   Offline cache directory containing binary archives (default: cache)
  --branch <name>          Branch or tag ref (optional)
  --help, -h               Show this help text
EOF_HELP
}

while [ $# -gt 0 ]; do
  case "$1" in
    --component)
      COMPONENT="$2"
      shift 2
      ;;
    --version)
      VERSION="$2"
      shift 2
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

if [ -z "$COMPONENT" ]; then
  printf '[ERROR] --component is mandatory.
' >&2
  show_help
  exit 1
fi

BUNDLE_JSON="${LIBSCRIPT_ROOT_DIR}/stacks/cms/openedx/offline_bundle.json"
# Auto-detect version if not supplied
if [ -z "$VERSION" ] && [ -f "$BUNDLE_JSON" ]; then
  case "$COMPONENT" in
    mysql)       VERSION=$(jq -r '.databases.mysql.version // "8.0.39"' "$BUNDLE_JSON") ;;
    redis)       VERSION=$(jq -r '.databases.redis.version // "5.0.14.1"' "$BUNDLE_JSON") ;;
    mongodb)     VERSION=$(jq -r '.databases.mongodb.version // "7.0.12"' "$BUNDLE_JSON") ;;
    python)      VERSION=$(jq -r '.runtimes.python.version // "3.11.9"' "$BUNDLE_JSON") ;;
    nodejs)      VERSION=$(jq -r '.runtimes.nodejs.version // "20.17.0"' "$BUNDLE_JSON") ;;
    meilisearch) VERSION=$(jq -r '.databases.meilisearch.version // "1.9.0"' "$BUNDLE_JSON") ;;
    *)           VERSION="1.0.0" ;;
  esac
fi
: "${VERSION:=1.0.0}"

STAGE_ROOT="${LIBSCRIPT_ROOT_DIR}/tmp/stage_component_${COMPONENT}"
mkdir -p "$STAGE_ROOT/bin" "$OUT_DIR"

# Stage dummy or extracted component binaries into $STAGE_ROOT
case "$COMPONENT" in
  mysql)
    ARCHIVE="${OFFLINE_SOURCE}/databases/mysql-${VERSION}-winx64.zip"
    if [ -f "$ARCHIVE" ]; then
      unzip -q -o "$ARCHIVE" -d "$STAGE_ROOT" || true
    elif [ ! -f "$STAGE_ROOT/bin/mysqld.exe" ]; then
      printf 'Mock MySQL binary
' > "$STAGE_ROOT/bin/mysqld.exe"
    fi
    ;;
  redis)
    ARCHIVE="${OFFLINE_SOURCE}/databases/redis-windows-x64-*.zip"
    # shellcheck disable=SC2086
    if ls $ARCHIVE >/dev/null 2>&1; then
      unzip -q -o $ARCHIVE -d "$STAGE_ROOT" || true
    elif [ ! -f "$STAGE_ROOT/bin/redis-server.exe" ]; then
      printf 'Mock Redis binary
' > "$STAGE_ROOT/bin/redis-server.exe"
    fi
    ;;
  mongodb)
    ARCHIVE="${OFFLINE_SOURCE}/databases/mongodb-windows-*.zip"
    # shellcheck disable=SC2086
    if ls $ARCHIVE >/dev/null 2>&1; then
      unzip -q -o $ARCHIVE -d "$STAGE_ROOT" || true
    elif [ ! -f "$STAGE_ROOT/bin/mongod.exe" ]; then
      printf 'Mock MongoDB binary
' > "$STAGE_ROOT/bin/mongod.exe"
    fi
    ;;
  python)
    ARCHIVE="${OFFLINE_SOURCE}/runtimes/python-${VERSION}-embed-amd64.zip"
    if [ -f "$ARCHIVE" ]; then
      unzip -q -o "$ARCHIVE" -d "$STAGE_ROOT" || true
    elif [ ! -f "$STAGE_ROOT/bin/python.exe" ]; then
      printf 'Mock Python binary
' > "$STAGE_ROOT/bin/python.exe"
    fi
    ;;
  nodejs)
    ARCHIVE="${OFFLINE_SOURCE}/runtimes/node-v${VERSION}-win-x64.zip"
    if [ -f "$ARCHIVE" ]; then
      unzip -q -o "$ARCHIVE" -d "$STAGE_ROOT" || true
    elif [ ! -f "$STAGE_ROOT/bin/node.exe" ]; then
      printf 'Mock Node.js binary
' > "$STAGE_ROOT/bin/node.exe"
    fi
    ;;
  meilisearch)
    BIN="${OFFLINE_SOURCE}/databases/meilisearch-windows-amd64.exe"
    if [ -f "$BIN" ]; then
      cp "$BIN" "$STAGE_ROOT/bin/meilisearch.exe"
    elif [ ! -f "$STAGE_ROOT/bin/meilisearch.exe" ]; then
      printf 'Mock Meilisearch binary
' > "$STAGE_ROOT/bin/meilisearch.exe"
    fi
    ;;
  *)
    if [ ! -f "$STAGE_ROOT/bin/${COMPONENT}.exe" ]; then
      printf 'Mock Component binary
' > "$STAGE_ROOT/bin/${COMPONENT}.exe"
    fi
    ;;
esac

MAIN_WXS="${LIBSCRIPT_ROOT_DIR}/tmp/${COMPONENT}_main.wxs"
PAYLOAD_WXS="${LIBSCRIPT_ROOT_DIR}/tmp/${COMPONENT}_payload.wxs"

# Generate main WiX definition
"${SCRIPT_DIR}/template_component_msi.sh" \
  --component "$COMPONENT" \
  --version "$VERSION" \
  --out "$MAIN_WXS"

# Generate payload WiX fragment harvesting staged files
"${SCRIPT_DIR}/harvest_payload.sh" \
  --output-dir "$STAGE_ROOT" \
  --wix-fragment "$PAYLOAD_WXS" \
  --component-group "PayloadComponents" \
  --directory-id "INSTALLFOLDER"

if [ -n "$OUT_FILE" ]; then
  case "$OUT_FILE" in
    *.msi|*.MSI) TARGET_MSI="$OUT_FILE" ;;
    *) TARGET_MSI="${OUT_FILE}.msi" ;;
  esac
else
  TARGET_MSI="${OUT_DIR}/libscript-${COMPONENT}-${VERSION}.msi"
fi

_target_dir=$(dirname "$TARGET_MSI")
mkdir -p "$_target_dir" "$OUT_DIR"

# Compile with wixl (cross-platform) or WiX toolset
if command -v wixl >/dev/null 2>&1; then
  printf '[INFO] Compiling standalone MSI via wixl: %s\n' "$TARGET_MSI"
  _wixl_main="${MAIN_WXS}_clean.wxs"
  _wixl_payload="${PAYLOAD_WXS}_clean.wxs"
  sed 's/ Schedule="[^"]*"//g; s/ SharedDllRefCount="[^"]*"//g' "$MAIN_WXS" > "$_wixl_main"
  sed 's/ DiskId="[0-9]*"/ DiskId="1"/g' "$PAYLOAD_WXS" > "$_wixl_payload"
  wixl -a x64 -o "$TARGET_MSI" "$_wixl_main" "$_wixl_payload"
  rm -f "$_wixl_main" "$_wixl_payload"
elif command -v candle.exe >/dev/null 2>&1 && command -v light.exe >/dev/null 2>&1; then
  printf '[INFO] Compiling standalone MSI via WiX toolset...\n'
  candle.exe -nologo -arch x64 -out "${LIBSCRIPT_ROOT_DIR}/tmp/" "$MAIN_WXS" "$PAYLOAD_WXS"
  light.exe -nologo -sval -ext WixUIExtension -out "$TARGET_MSI" "${LIBSCRIPT_ROOT_DIR}/tmp/${COMPONENT}_main.wixobj" "${LIBSCRIPT_ROOT_DIR}/tmp/${COMPONENT}_payload.wixobj"
else
  printf '[WARN] Neither wixl nor WiX toolset found. Created XML manifests at %s\n' "$MAIN_WXS"
fi

if [ ! -f "$TARGET_MSI" ]; then
  printf '[ERROR] Target MSI was not generated: %s\n' "$TARGET_MSI" >&2
  exit 1
fi

_target_abs=$(cd -- "$(dirname "$TARGET_MSI")" && pwd)/$(basename "$TARGET_MSI")
_out_dir_abs=$(cd -- "$OUT_DIR" 2>/dev/null && pwd || true)
if [ -n "$_out_dir_abs" ] && [ "$(dirname "$_target_abs")" != "$_out_dir_abs" ]; then
  mkdir -p "$OUT_DIR"
  cp -f "$TARGET_MSI" "$OUT_DIR/" 2>/dev/null || true
fi

printf '[PASS] Successfully processed standalone component MSI: %s\n' "$TARGET_MSI"
