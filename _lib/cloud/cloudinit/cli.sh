#!/bin/sh
# ## Overview
# Cloud-init component CLI for generating OS configurations.
#
# ## Usage
# libscript cloudinit generate-mount [--device path] [--mount-point path] [--fs-type type]

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  eval 'THIS_FILE="${BASH_SOURCE[0]}"'
  eval 'set -o pipefail'
elif [ "${ZSH_VERSION-}" ]; then
  eval 'THIS_FILE="${(%):-%x}"'
  eval 'set -o pipefail'
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

export LIBSCRIPT_DEVICE="${LIBSCRIPT_DEVICE:-}"
export LIBSCRIPT_MOUNT_POINT="${LIBSCRIPT_MOUNT_POINT:-}"
export LIBSCRIPT_FS_TYPE="${LIBSCRIPT_FS_TYPE:-ext4}"

while [ $# -gt 0 ]; do
  case "$1" in
    --device)
      LIBSCRIPT_DEVICE="$2"
      shift 2
      ;;
    --device=*)
      LIBSCRIPT_DEVICE="${1#*=}"
      shift
      ;;
    --mount-point)
      LIBSCRIPT_MOUNT_POINT="$2"
      shift 2
      ;;
    --mount-point=*)
      LIBSCRIPT_MOUNT_POINT="${1#*=}"
      shift
      ;;
    --fs-type)
      LIBSCRIPT_FS_TYPE="$2"
      shift 2
      ;;
    --distro=*)
      export LIBSCRIPT_DISTRO="${1#*=}"
      shift
      ;;
    cloudinit)
      shift
      ;;
    *)
      printf "Error: Unknown argument '%s'\n" "$1" >&2
      exit 1
      ;;
    esac
    done

    if [ -z "$CMD" ]; then
    printf "Error: Missing command for cloudinit (generate|validate).\n" >&2
    exit 1
    fi

    case "$CMD" in
    install)
    printf "Cloud components are operational wrappers and do not require installation.\n"
    exit 0
    ;;
    test)
    printf "Running mock test for cloudinit...\n"
    exit 0
    ;;
    generate|validate)
    . "$SCRIPT_DIR/api.sh"
    libscript_cloudinit_generate_mount "$LIBSCRIPT_DEVICE" "$LIBSCRIPT_MOUNT_POINT" "$LIBSCRIPT_FS_TYPE"
    ;;
  *)
    printf "Error: Unknown cloudinit command '%s'\n" "$CMD" >&2
    exit 1
    ;;
esac