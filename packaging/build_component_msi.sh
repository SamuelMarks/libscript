#!/bin/sh
# ## Overview
# ## Overview
# Builds a standalone Windows Installer (.msi) package for an individual LibScript dependency.
# Decomposes full stack deployments into modular, reference-counted component MSIs.
# Supports lightweight online installer and air-gapped offline installer with pre-bundled dependencies.
#
# ## Usage
#   ./packaging/build_component_msi.sh [OPTIONS]
#
# ## Parameters
#   --component <name>       Component to package (mysql, redis, mongodb, python, nodejs, meilisearch)
#   --version <ver>          Component release version (default: auto-detected from offline bundle)
#   --variant <var>          Installer variant: online, offline, or all (default: all)
#   --online                 Shorthand for --variant online
#   --offline                Shorthand for --variant offline
#   --out <name>             Output file base name or path (default: dist/msi/libscript-<component>-<version>.msi)
#   --out-dir <dir>          Target directory for generated .msi (default: dist/msi)
#   --offline-source <dir>   Cache directory containing source archives/binaries (default: cache)
#   --hydrate                Force hydration of offline cache before building
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
VARIANT="all"
OUT_FILE=""
BRANCH=""
OUT_DIR="${LIBSCRIPT_ROOT_DIR}/dist/msi"
OFFLINE_SOURCE="${LIBSCRIPT_ROOT_DIR}/cache"
HYDRATE=0

# ## cleanup_artifacts
# ## Overview
# Removes transient MSI compilation artifacts.
cleanup_artifacts() {
  rm -f "${LIBSCRIPT_ROOT_DIR}/tmp/${COMPONENT}_${_v:-}_main.wixobj" \
        "${LIBSCRIPT_ROOT_DIR}/tmp/${COMPONENT}_${_v:-}_payload.wixobj" \
        "${MAIN_WXS:-}" "${PAYLOAD_WXS:-}"
}
trap cleanup_artifacts EXIT INT TERM


# ## show_help
# ## Overview
# Displays usage and supported parameters.
# ## Usage
#   Internal function.
show_help() {
  cat << EOF_HELP
LibScript Standalone Component MSI Builder

Usage:
  ./packaging/build_component_msi.sh [OPTIONS]

Options:
  --component <name>       Component identifier (mysql, redis, mongodb, python, nodejs, meilisearch)
  --version <ver>          Release version (defaults to version from offline_bundle.json)
  --variant <var>          Installer variant (online, offline, or all; default: all)
  --online                 Build lightweight online installer
  --offline                Build air-gapped offline installer with embedded payload
  --out <name>             Output file base name or path
  --out-dir <dir>          Output directory (default: dist/msi)
  --offline-source <dir>   Offline cache directory containing binary archives (default: cache)
  --hydrate                Force hydration of offline cache before building
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

if [ -z "$COMPONENT" ]; then
  printf '[ERROR] --component is mandatory.
' >&2
  show_help
  exit 1
fi

BUNDLE_JSON="${LIBSCRIPT_ROOT_DIR}/stacks/cms/openedx/offline_bundle.json"
# Auto-detect version if not supplied
if [ -z "$VERSION" ] && [ -f "$BUNDLE_JSON" ] && command -v jq >/dev/null 2>&1; then
  case "$COMPONENT" in
    mysql)       VERSION=$(jq -r '.databases.mysql.version // "8.0.39"' "$BUNDLE_JSON") ;;
    redis)       VERSION=$(jq -r '.databases.redis.version // "8.10.2"' "$BUNDLE_JSON") ;;
    mongodb)     VERSION=$(jq -r '.databases.mongodb.version // "7.0.12"' "$BUNDLE_JSON") ;;
    python)      VERSION=$(jq -r '.runtimes.python.version // "3.11.9"' "$BUNDLE_JSON") ;;
    nodejs)      VERSION=$(jq -r '.runtimes.nodejs.version // "20.17.0"' "$BUNDLE_JSON") ;;
    meilisearch) VERSION=$(jq -r '.databases.meilisearch.version // "1.9.0"' "$BUNDLE_JSON") ;;
    *)           VERSION="1.0.0" ;;
  esac
fi
: "${VERSION:=1.0.0}"

# ## find_first_file
# ## Overview
# Returns the path of the first existing file matching any of the passed glob arguments.
# Temporarily enables filename expansion since the script operates under set -f.
#
# ## Parameters
#   $@ - Glob patterns or file paths
# ## Usage
#   Internal function.
find_first_file() {
  set +f
  for _pat in "$@"; do
    # shellcheck disable=SC2086
    for _target in $_pat; do
      if [ -f "$_target" ]; then
        set -f
        printf '%s\n' "$_target"
        return 0
      fi
    done
  done
  set -f
  return 0
}

# ## build_single_variant
# ## Overview
# Builds a specific component installer variant (online or offline).
#
# ## Parameters
#   $1 - Variant ("online" or "offline")
# ## Usage
#   Internal function.
build_single_variant() {
  _v="$1"
  STAGE_ROOT="${LIBSCRIPT_ROOT_DIR}/tmp/stage_component_${COMPONENT}_${_v}"
  rm -rf "$STAGE_ROOT"
  mkdir -p "$STAGE_ROOT/bin" "$OUT_DIR"

  if [ "$_v" = "offline" ]; then
    set +f
    _need_hydrate=0
    case "$COMPONENT" in
      mysql)
        _arc=$(find_first_file "${OFFLINE_SOURCE}/databases/mysql-"*".zip")
        [ -n "$_arc" ] && [ -f "$_arc" ] || _need_hydrate=1
        ;;
      redis)
        _arc=$(find_first_file "${OFFLINE_SOURCE}/databases/redis-"*".zip" "${OFFLINE_SOURCE}/databases/Redis-"*".zip")
        [ -n "$_arc" ] && [ -f "$_arc" ] || _need_hydrate=1
        ;;
      mongodb)
        _arc=$(find_first_file "${OFFLINE_SOURCE}/databases/mongodb-"*".zip")
        [ -n "$_arc" ] && [ -f "$_arc" ] || _need_hydrate=1
        ;;
      python)
        _arc=$(find_first_file "${OFFLINE_SOURCE}/runtimes/python-"*".zip")
        [ -n "$_arc" ] && [ -f "$_arc" ] || _need_hydrate=1
        ;;
      nodejs)
        _arc=$(find_first_file "${OFFLINE_SOURCE}/runtimes/node-"*".zip")
        [ -n "$_arc" ] && [ -f "$_arc" ] || _need_hydrate=1
        ;;
      meilisearch)
        _bin=$(find_first_file "${OFFLINE_SOURCE}/databases/meilisearch-"*".exe")
        [ -n "$_bin" ] && [ -f "$_bin" ] || _need_hydrate=1
        ;;
    esac

    if [ "$HYDRATE" -eq 1 ] || [ "$_need_hydrate" -eq 1 ]; then
        printf '[INFO] Hydrating %s offline cache before build...\n' "$COMPONENT"
        "${SCRIPT_DIR}/hydrate_offline_cache.sh" --manifest "$BUNDLE_JSON" --cache-dir "$OFFLINE_SOURCE" --component "$COMPONENT" || true
    fi


    case "$COMPONENT" in
      mysql)
        _arc=$(find_first_file "${OFFLINE_SOURCE}/databases/mysql-"*".zip")
        if [ -n "$_arc" ] && [ -f "$_arc" ]; then
          unzip -q -o "$_arc" -d "$STAGE_ROOT" || true
          _sub=$(find "$STAGE_ROOT" -mindepth 1 -maxdepth 1 -type d ! -name bin | head -n 1 || true)
          if [ -n "$_sub" ] && [ -d "$_sub/bin" ]; then
            mv "$_sub"/* "$STAGE_ROOT/"
            rmdir "$_sub" 2>/dev/null || true
          fi
        else
          printf '[ERROR] Offline MySQL archive missing from %s\n' "$OFFLINE_SOURCE" >&2
          exit 1
        fi
        ;;
      redis)
        _arc=$(find_first_file "${OFFLINE_SOURCE}/databases/redis-"*".zip" "${OFFLINE_SOURCE}/databases/Redis-"*".zip")
        if [ -n "$_arc" ] && [ -f "$_arc" ]; then
          unzip -q -o "$_arc" -d "$STAGE_ROOT" || true
          _sub=$(find "$STAGE_ROOT" -mindepth 1 -maxdepth 1 -type d ! -name bin | head -n 1 || true)
          if [ -n "$_sub" ]; then
            if [ -d "$_sub/bin" ]; then
              mv "$_sub"/* "$STAGE_ROOT/" 2>/dev/null || true
            else
              mkdir -p "$STAGE_ROOT/bin"
              mv "$_sub"/* "$STAGE_ROOT/bin/" 2>/dev/null || true
            fi
            rmdir "$_sub" 2>/dev/null || true
          fi
          mkdir -p "$STAGE_ROOT/bin"
          if [ -f "$STAGE_ROOT/redis-server.exe" ] && [ ! -f "$STAGE_ROOT/bin/redis-server.exe" ]; then
            cp -f "$STAGE_ROOT/redis-server.exe" "$STAGE_ROOT/bin/"
            cp -f "$STAGE_ROOT/redis-cli.exe" "$STAGE_ROOT/bin/" 2>/dev/null || true
          fi
          mkdir -p "$STAGE_ROOT/bin"
        else
          printf '[ERROR] Offline Redis archive missing from %s\n' "$OFFLINE_SOURCE" >&2
          exit 1
        fi
        ;;
      mongodb)
        _arc=$(find_first_file "${OFFLINE_SOURCE}/databases/mongodb-"*".zip")
        if [ -n "$_arc" ] && [ -f "$_arc" ]; then
          unzip -q -o "$_arc" -d "$STAGE_ROOT" || true
          _sub=$(find "$STAGE_ROOT" -mindepth 1 -maxdepth 1 -type d ! -name bin | head -n 1 || true)
          if [ -n "$_sub" ] && [ -d "$_sub/bin" ]; then
            mv "$_sub"/* "$STAGE_ROOT/"
            rmdir "$_sub" 2>/dev/null || true
          fi
        else
          printf '[ERROR] Offline MongoDB archive missing from %s\n' "$OFFLINE_SOURCE" >&2
          exit 1
        fi
        ;;
      python)
        _arc=$(find_first_file "${OFFLINE_SOURCE}/runtimes/python-"*".zip")
        if [ -n "$_arc" ] && [ -f "$_arc" ]; then
          unzip -q -o "$_arc" -d "$STAGE_ROOT" || true
          if [ -f "$STAGE_ROOT/python.exe" ] && [ ! -f "$STAGE_ROOT/bin/python.exe" ]; then
            cp -f "$STAGE_ROOT/python.exe" "$STAGE_ROOT/bin/"
          fi
        else
          printf '[ERROR] Offline Python archive missing from %s\n' "$OFFLINE_SOURCE" >&2
          exit 1
        fi
        ;;
      nodejs)
        _arc=$(find_first_file "${OFFLINE_SOURCE}/runtimes/node-"*".zip")
        if [ -n "$_arc" ] && [ -f "$_arc" ]; then
          unzip -q -o "$_arc" -d "$STAGE_ROOT" || true
          _sub=$(find "$STAGE_ROOT" -mindepth 1 -maxdepth 1 -type d ! -name bin | head -n 1 || true)
          if [ -n "$_sub" ]; then
            mv "$_sub"/* "$STAGE_ROOT/"
            rmdir "$_sub" 2>/dev/null || true
          fi
          if [ -f "$STAGE_ROOT/node.exe" ] && [ ! -f "$STAGE_ROOT/bin/node.exe" ]; then
            cp -f "$STAGE_ROOT/node.exe" "$STAGE_ROOT/bin/"
          fi
        else
          printf '[ERROR] Offline Node.js archive missing from %s\n' "$OFFLINE_SOURCE" >&2
          exit 1
        fi
        ;;
      meilisearch)
        _bin=$(find_first_file "${OFFLINE_SOURCE}/databases/meilisearch-"*".exe")
        if [ -n "$_bin" ] && [ -f "$_bin" ]; then
          cp -f "$_bin" "$STAGE_ROOT/bin/meilisearch.exe"
          cp -f "$_bin" "$STAGE_ROOT/meilisearch.exe" 2>/dev/null || true
        else
          printf '[ERROR] Offline Meilisearch binary missing from %s\n' "$OFFLINE_SOURCE" >&2
          exit 1
        fi
        ;;
      *)
        if [ ! -f "$STAGE_ROOT/bin/${COMPONENT}.exe" ]; then
          :
        fi

        ;;
    esac
    set -f
  else
    # Online variant: lightweight manifest and stub
    printf '{"component":"%s","version":"%s","variant":"online"}
' "$COMPONENT" "$VERSION" > "$STAGE_ROOT/component.json"
    printf 'LibScript %s Online Standalone Installer
' "$COMPONENT" > "$STAGE_ROOT/README.txt"
    mkdir -p "$STAGE_ROOT/bin"
    printf 'LibScript %s Online Stub
' "$COMPONENT" > "$STAGE_ROOT/bin/README.txt"
  fi

  MAIN_WXS="${LIBSCRIPT_ROOT_DIR}/tmp/${COMPONENT}_${_v}_main.wxs"
  PAYLOAD_WXS="${LIBSCRIPT_ROOT_DIR}/tmp/${COMPONENT}_${_v}_payload.wxs"

  # Generate main WiX definition
  "${SCRIPT_DIR}/template_component_msi.sh" \
    --component "$COMPONENT" \
    --version "$VERSION" \
    --variant "$_v" \
    --out "$MAIN_WXS"
  cp -f "$MAIN_WXS" "${LIBSCRIPT_ROOT_DIR}/tmp/${COMPONENT}_main.wxs" 2>/dev/null || true

  # Generate payload WiX fragment harvesting staged files
  "${SCRIPT_DIR}/harvest_payload.sh" \
    --source-dir "$STAGE_ROOT" \
    --wix-fragment "$PAYLOAD_WXS" \
    --component-group "PayloadComponents" \
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
      TARGET_MSI="${OUT_DIR}/libscript-${COMPONENT}-offline-${VERSION}.msi"
    else
      TARGET_MSI="${OUT_DIR}/libscript-${COMPONENT}-${VERSION}.msi"
    fi
  fi

  _target_dir=$(dirname "$TARGET_MSI")
  mkdir -p "$_target_dir" "$OUT_DIR"

  # Ensure msi-rs is available via libscript mechanisms
  if [ -d "${LIBSCRIPT_HOME:-$HOME/.libscript}/msi-rs/default/bin" ]; then
    PATH="${LIBSCRIPT_HOME:-$HOME/.libscript}/msi-rs/default/bin:${PATH}"
    export PATH
  elif [ -d "${LIBSCRIPT_HOME:-$HOME/.libscript}/msi-rs/v0.0.1/bin" ]; then
    PATH="${LIBSCRIPT_HOME:-$HOME/.libscript}/msi-rs/v0.0.1/bin:${PATH}"
    export PATH
  fi
  if ! command -v candle >/dev/null 2>&1 && ! command -v candle.exe >/dev/null 2>&1; then
    if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/msi-rs/env.sh" ]; then
      . "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/msi-rs/env.sh" >/dev/null 2>&1 || true
    fi
  fi
  if ! command -v candle >/dev/null 2>&1 && ! command -v candle.exe >/dev/null 2>&1; then
    if [ -x "${LIBSCRIPT_ROOT_DIR}/libscript.sh" ]; then
      "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install msi-rs v0.0.1 >/dev/null 2>&1 || true
      if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/msi-rs/env.sh" ]; then
        . "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/msi-rs/env.sh" >/dev/null 2>&1 || true
      fi
    fi
  fi

  _candle="candle"
  _light="light"
  if [ "${OS:-}" = "Windows_NT" ]; then
    command -v candle.exe >/dev/null 2>&1 && _candle="candle.exe"
    command -v light.exe >/dev/null 2>&1 && _light="light.exe"
  fi

  if ! command -v "$_candle" >/dev/null 2>&1; then
    printf '[ERROR] msi-rs not found. Please install msi-rs.n' >&2
    exit 1
  fi

  printf '[INFO] Compiling standalone %s MSI via msi-rs: %sn' "$_v" "$TARGET_MSI"
  "$_candle" -nologo -arch x64 -out "${LIBSCRIPT_ROOT_DIR}/tmp/${COMPONENT}_${_v}_main.wixobj" "$MAIN_WXS" || exit 1
  "$_candle" -nologo -arch x64 -out "${LIBSCRIPT_ROOT_DIR}/tmp/${COMPONENT}_${_v}_payload.wixobj" "$PAYLOAD_WXS" || exit 1
  "$_light" -nologo -sval -ext WixUIExtension -out "$TARGET_MSI" "${LIBSCRIPT_ROOT_DIR}/tmp/${COMPONENT}_${_v}_main.wixobj" "${LIBSCRIPT_ROOT_DIR}/tmp/${COMPONENT}_${_v}_payload.wixobj" || exit 1


  if [ ! -f "$TARGET_MSI" ]; then
    printf '[ERROR] Target MSI was not generated: %s
' "$TARGET_MSI" >&2
    exit 1
  fi

  _target_abs=$(cd -- "$(dirname "$TARGET_MSI")" && pwd)/$(basename "$TARGET_MSI")
  _out_dir_abs=$(cd -- "$OUT_DIR" 2>/dev/null && pwd || true)
  if [ -n "$_out_dir_abs" ] && [ "$(dirname "$_target_abs")" != "$_out_dir_abs" ]; then
    mkdir -p "$OUT_DIR"
    cp -f "$TARGET_MSI" "$OUT_DIR/" 2>/dev/null || true
  fi

  rm -f "${LIBSCRIPT_ROOT_DIR}/tmp/${COMPONENT}_${_v}_main.wixobj" "${LIBSCRIPT_ROOT_DIR}/tmp/${COMPONENT}_${_v}_payload.wixobj" "${MAIN_WXS}" "${PAYLOAD_WXS}"
  _fsize=$(wc -c < "$TARGET_MSI" | tr -d ' ')
  printf '[PASS] Successfully processed standalone component MSI (%s): %s (%s bytes)
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
