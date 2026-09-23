#!/bin/sh
# ## Overview
# Generates a WiX Windows Installer (.msi) package for the Open edX platform.
# Supports lightweight online installer and air-gapped offline installer with pre-bundled dependencies.
#
# ## Usage
#   ./packaging/build_openedx_msi.sh [OPTIONS]
#
# ## Parameters
#   --offline         Build completely air-gapped installer embedding pre-downloaded offline cache
#   --online          Build lightweight online installer (default: ~4 MB)
#   --hydrate-cache   Pre-fetch and verify all offline assets prior to building MSI
#   --cache-dir <dir> Override offline dependency cache directory
#   --out <name>      Override output base file name
#   --version <ver>   Package version

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

variant="online"
if [ "${LIBSCRIPT_OFFLINE:-0}" = "1" ]; then
  variant="offline"
fi
hydrate_cache=0
cache_dir="${LIBSCRIPT_CACHE_DIR:-${LIBSCRIPT_ROOT_DIR}/cache}"
manifest_path="${LIBSCRIPT_ROOT_DIR}/stacks/cms/openedx/offline_bundle.json"

extra_args=""
while [ $# -gt 0 ]; do
  case "$1" in
    --offline|-o)
      variant="offline"
      shift
      ;;
    --online)
      variant="online"
      shift
      ;;
    --hydrate-cache)
      hydrate_cache=1
      shift
      ;;
    --cache-dir)
      cache_dir="$2"
      extra_args="$extra_args --cache-dir $2"
      shift 2
      ;;
    --help|-h|/\?|-\?)
      cat << 'EOF_HELP'
Open edX Windows Installer (.msi) Generator

Usage:
  ./packaging/build_openedx_msi.sh [OPTIONS]

Options:
  --online          Build lightweight online installer (~4 MB) (default)
  --offline, -o     Build completely air-gapped offline installer (~1 GB)
  --hydrate-cache   Pre-fetch and verify all offline dependencies before building
  --cache-dir <dir> Override offline artifact cache directory
  --out <name>      Override output base file name
  --version <ver>   Package version (default: 1.0.0.0)
  --help, -h        Show this help text
EOF_HELP
      exit 0
      ;;
    *)
      extra_args="$extra_args $1"
      shift
      ;;
  esac
done

if [ "$variant" = "offline" ] && [ ! -f "${cache_dir}/runtimes/python-3.11.9-embed-amd64.zip" ]; then
  hydrate_cache=1
fi

if [ "$hydrate_cache" -eq 1 ]; then
  printf '[INFO] Hydrating offline cache before MSI build...\n'
  "${SCRIPT_DIR}/hydrate_offline_cache.sh" --manifest "$manifest_path" --cache-dir "$cache_dir"
fi

# shellcheck disable=SC2086
exec "${SCRIPT_DIR}/build_msi.sh" "stacks/cms/openedx" --variant "$variant" --cache-dir "$cache_dir" $extra_args
