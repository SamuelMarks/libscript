#!/bin/sh
# ## Overview
# Generic msi-rs workload driver resolving and staging an arbitrary component list
# ({component0, component1, ...}) into the target OS sysroot without leaking host paths.
# ## Usage
# ./_lib/package-managers/msi-rs/workloads/components.sh <target_dir> <c0,c1,...>

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

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf 'Usage: %s <target_dir> <c0,c1,...>\n' "$(basename "$THIS_FILE")"
  exit 0
fi

TARGET_DIR="${1:-/mnt/target}"
COMPONENTS_CSV="${2:-${MSI_RS_COMPONENTS:-}}"

if [ -z "$COMPONENTS_CSV" ]; then
  printf '[INFO] No custom components specified for workload; skipping.\n'
  exit 0
fi

STAMP_DIR="${TARGET_DIR}/var/lib/libscript"
mkdir -p "$STAMP_DIR"
_safe_tag=$(printf '%s' "$COMPONENTS_CSV" | tr ',/ ' '___')
STAMP_FILE="${STAMP_DIR}/workload_components_${_safe_tag}.installed"

if [ -f "$STAMP_FILE" ]; then
  printf '[SKIP] Component workload (%s) already installed at %s.\n' "$COMPONENTS_CSV" "$TARGET_DIR"
  exit 0
fi

_old_ifs="$IFS"
IFS=','
for _comp in $COMPONENTS_CSV; do
  [ -n "$_comp" ] || continue
  printf '[WORKLOAD] Staging component "%s" into %s...\n' "$_comp" "$TARGET_DIR"
  LIBSCRIPT_TARGET_SYSROOT="$TARGET_DIR" \
    LIBSCRIPT_IMAGE_BUILD='1' \
    STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install "$_comp" latest
done
IFS="$_old_ifs"

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
printf '[OK] Generic component workload (%s) staged into %s.\n' "$COMPONENTS_CSV" "$TARGET_DIR"
exit 0
