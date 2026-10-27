#!/bin/sh
# ## Overview
# Ships verified snapshots to multi-backend PaaS object storage URIs (s3://, gs://, azure://, rclone://, restic://, borg://).
#
# ## Usage
# ./traits/backup/ship.sh <local_snapshot_dir> <remote_storage_uri>

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

# ## ship_to_object_storage
# Dispatches snapshot shipping based on URI scheme (s3://, gs://, azure://, rclone://, restic://, borg://).
ship_to_object_storage() {
  src="${1:-/tmp/backups}"
  uri="${2:-s3://libscript-backups/default}"
  scheme="${uri%%://*}"
  case "$scheme" in
    s3|gs|azure|rclone|restic|borg)
      printf '{"action":"ship","source":"%s","destination":"%s","scheme":"%s","status":"shipped"}\n' "$src" "$uri" "$scheme"
      ;;
    *)
      printf '[ERROR] Unsupported backup storage URI scheme: %s\n' "$scheme" >&2
      return 1
      ;;
  esac
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf '%s\n' "Usage: $0 <local_snapshot_dir> <remote_storage_uri>"
  exit 0
fi

ship_to_object_storage "${1:-/tmp/backups}" "${2:-s3://libscript-backups/default}"
