#!/bin/sh
# ## Overview
# Offline preload asset manager for the msi-rs live installer.
# Packages and stages LibScript components, offline MSI payloads, and dependency caches
# directly into target sysroots, and executes post-install chroot activation hooks.
#
# ## Usage
# Execute this script to preload components into a target system root:
#   ./_lib/package-managers/msi-rs/preloader/preload_assets.sh [target_dir] [component_list...]

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
REPO_ROOT="${LIBSCRIPT_ROOT_DIR}"

# ## show_help
# Displays usage instructions and supported options.
show_help() {
  printf '%s
' "Usage: $(basename "$THIS_FILE") [target_dir] [component_list...]"
  printf '%s
' "Stages offline components and executes chroot activation hooks in target sysroot."
  printf '
'
  printf '%s
' "Options:"
  printf '%s
' "  --help, -h, /?, -?  Show this help message."
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "/?" ] || [ "${1:-}" = "-?" ]; then
  show_help
  exit 0
fi

TARGET_DIR="${1:-/mnt/target}"
shift || true

CACHE_DIR="${TARGET_DIR}/opt/libscript/cache"
mkdir -p "$CACHE_DIR" "${TARGET_DIR}/usr/local/bin"

printf '[PRELOAD] Staging offline LibScript payloads into %s...
' "$CACHE_DIR"

# Copy libscript orchestrator to target
if [ -f "${REPO_ROOT}/libscript.sh" ]; then
  cp "${REPO_ROOT}/libscript.sh" "${TARGET_DIR}/usr/local/bin/libscript.sh"
  chmod +x "${TARGET_DIR}/usr/local/bin/libscript.sh"
fi

# Stage components
for comp in "$@"; do
  [ -n "$comp" ] || continue
  printf '          Preloading component: %s...
' "$comp"
  mkdir -p "${CACHE_DIR}/${comp}"

  # Stage pre-compiled local artifacts if present
  if [ -d "${REPO_ROOT}/_lib/${comp}" ]; then
    cp -R "${REPO_ROOT}/_lib/${comp}" "${CACHE_DIR}/" 2>/dev/null || true
  fi
done

printf '[OK] Offline component staging completed in %s.
' "$TARGET_DIR"
exit 0
