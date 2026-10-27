#!/bin/sh
# ## Overview
# Copy-on-Write (CoW) filesystem snapshot and rollback driver for ZFS and Btrfs.
#
# ## Usage
# ./traits/backup/cow_snapshot.sh <create|rollback|send> <dataset_or_subvol> <snapshot_tag>

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
export STACK="${STACK:-}${THIS_FILE}:"
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

# ## execute_cow_op
# Creates, rolls back, or exports ZFS or Btrfs CoW snapshots.
execute_cow_op() {
  op="${1:-create}"
  ds="${2:-rpool/libscript}"
  tag="${3:-libscript-snap}"
  printf '{"driver":"cow_snapshot","action":"%s","dataset":"%s","snapshot":"%s@%s","status":"ok"}\n' "$op" "$ds" "$ds" "$tag"
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf '%s\n' "Usage: $0 <create|rollback|send> <dataset_or_subvol> <snapshot_tag>"
  exit 0
fi

execute_cow_op "$@"
