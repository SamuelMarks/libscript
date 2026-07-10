#!/bin/sh
# ## Overview
# Storage component CLI for Object Storage (buckets) operations.
#
# ## Usage
# libscript storage [create|delete|list|sync] [--cloud aws|gcp|azure] [--bucket name]

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
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

CMD="${1:-}"
if [ -n "$CMD" ]; then
  shift
fi

export LIBSCRIPT_CLOUD="${LIBSCRIPT_CLOUD:-}"
export LIBSCRIPT_BUCKET="${LIBSCRIPT_BUCKET:-}"
export LIBSCRIPT_SYNC_DIR="${LIBSCRIPT_SYNC_DIR:-}"
export LIBSCRIPT_STORAGE_PUBLIC_WEB="${LIBSCRIPT_STORAGE_PUBLIC_WEB:-false}"

while [ $# -gt 0 ]; do
  case "$1" in
    --cloud)
      LIBSCRIPT_CLOUD="$2"
      shift 2
      ;;
    --cloud=*)
      LIBSCRIPT_CLOUD="${1#*=}"
      shift
      ;;
    --bucket)
      LIBSCRIPT_BUCKET="$2"
      shift 2
      ;;
    --bucket=*)
      LIBSCRIPT_BUCKET="${1#*=}"
      shift
      ;;
    --local-dir)
      LIBSCRIPT_SYNC_DIR="$2"
      shift 2
      ;;
    --local-dir=*)
      LIBSCRIPT_SYNC_DIR="${1#*=}"
      shift
      ;;
    --public-web)
      LIBSCRIPT_STORAGE_PUBLIC_WEB="true"
      shift
      ;;
    *)
      printf "Error: Unknown argument '%s'\n" "$1" >&2
      exit 1
      ;;
  esac
done

if [ -z "$CMD" ]; then
  printf "Error: Missing command for storage (create|delete|list|sync).\n" >&2
  exit 1
fi

case "$CMD" in
  create|delete|list|sync)
    # Execution
    . "$SCRIPT_DIR/api.sh"
    case "$CMD" in
      create)
        libscript_storage_create "$LIBSCRIPT_CLOUD" "$LIBSCRIPT_BUCKET" "${LIBSCRIPT_STORAGE_PUBLIC_WEB:-false}"
        ;;
      delete)
        libscript_storage_delete "$LIBSCRIPT_CLOUD" "$LIBSCRIPT_BUCKET"
        ;;
      list)
        libscript_storage_list "$LIBSCRIPT_CLOUD"
        ;;
      sync)
        if [ -z "${LIBSCRIPT_SYNC_DIR:-}" ]; then
          printf "Error: --local-dir (or LIBSCRIPT_SYNC_DIR) is required for sync.\n" >&2
          exit 1
        fi
        libscript_storage_sync "$LIBSCRIPT_CLOUD" "$LIBSCRIPT_BUCKET" "$LIBSCRIPT_SYNC_DIR"
        ;;
    esac
    ;;
  *)
    printf "Error: Unknown storage command '%s'\n" "$CMD" >&2
    exit 1
    ;;
esac