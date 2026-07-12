#!/bin/sh
# ## Overview
# Volume component CLI for Block Storage operations.
#
# ## Usage
# libscript volume [create|delete|list|attach|detach] [--cloud aws|gcp|azure] [--volume-id id] [--name name] [--size gb] [--zone zone] [--type type] [--node-id id] [--device path]

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
export LIBSCRIPT_VOLUME_ID="${LIBSCRIPT_VOLUME_ID:-}"
export LIBSCRIPT_VOLUME_SIZE="${LIBSCRIPT_VOLUME_SIZE:-}"
export LIBSCRIPT_VOLUME_ZONE="${LIBSCRIPT_VOLUME_ZONE:-}"
export LIBSCRIPT_VOLUME_TYPE="${LIBSCRIPT_VOLUME_TYPE:-}"
export LIBSCRIPT_NODE_ID="${LIBSCRIPT_NODE_ID:-}"
export LIBSCRIPT_DEVICE="${LIBSCRIPT_DEVICE:-}"

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
    --volume-id)
      LIBSCRIPT_VOLUME_ID="$2"
      shift 2
      ;;
    --volume-id=*)
      LIBSCRIPT_VOLUME_ID="${1#*=}"
      shift
      ;;
    --size)
      LIBSCRIPT_VOLUME_SIZE="$2"
      shift 2
      ;;
    --size=*)
      LIBSCRIPT_VOLUME_SIZE="${1#*=}"
      shift
      ;;
    --name)
      LIBSCRIPT_VOLUME_NAME="$2"
      shift 2
      ;;
    --name=*)
      LIBSCRIPT_VOLUME_NAME="${1#*=}"
      shift
      ;;
    --zone)
      LIBSCRIPT_VOLUME_ZONE="$2"
      shift 2
      ;;
    --zone=*)
      LIBSCRIPT_VOLUME_ZONE="${1#*=}"
      shift
      ;;
    --type)
      LIBSCRIPT_VOLUME_TYPE="$2"
      shift 2
      ;;
    --type=*)
      LIBSCRIPT_VOLUME_TYPE="${1#*=}"
      shift
      ;;
    --node-id)
      LIBSCRIPT_NODE_ID="$2"
      shift 2
      ;;
    --node-id=*)
      LIBSCRIPT_NODE_ID="${1#*=}"
      shift
      ;;
    --device)
      LIBSCRIPT_DEVICE="$2"
      shift 2
      ;;
    --device=*)
      LIBSCRIPT_DEVICE="${1#*=}"
      shift
      ;;
    *)
      printf "Error: Unknown argument '%s'\n" "$1" >&2
      exit 1
      ;;
  esac
done

if [ -z "$CMD" ]; then
  printf "Error: Missing command for volume (create|delete|list|attach|detach).\n" >&2
  exit 1
fi

case "$CMD" in
  create|delete|list|attach|detach)
    # Execution
    . "$SCRIPT_DIR/api.sh"
    case "$CMD" in
      create)
        libscript_volume_create "$LIBSCRIPT_CLOUD" "$LIBSCRIPT_VOLUME_SIZE" "$LIBSCRIPT_VOLUME_ZONE" "$LIBSCRIPT_VOLUME_TYPE" "${LIBSCRIPT_VOLUME_NAME:-vol-libscript}"
        ;;
      delete)
        libscript_volume_delete "$LIBSCRIPT_CLOUD" "$LIBSCRIPT_VOLUME_ID"
        ;;
      list)
        libscript_volume_list "$LIBSCRIPT_CLOUD"
        ;;
      attach)
        libscript_volume_attach "$LIBSCRIPT_CLOUD" "$LIBSCRIPT_VOLUME_ID" "$LIBSCRIPT_NODE_ID" "$LIBSCRIPT_DEVICE"
        ;;
      detach)
        libscript_volume_detach "$LIBSCRIPT_CLOUD" "$LIBSCRIPT_VOLUME_ID" "$LIBSCRIPT_NODE_ID"
        ;;
    esac
    ;;
  *)
    printf "Error: Unknown volume command '%s'\n" "$CMD" >&2
    exit 1
    ;;
esac