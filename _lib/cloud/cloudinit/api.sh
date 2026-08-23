#!/bin/sh
# ## Overview
# API implementation for generating cloud-init YAML blocks for OS integration.
#
# ## Usage
# Source this file and call libscript_cloudinit_generate_mount.

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

# ## libscript_cloudinit_generate_mount
# Executes libscript_cloudinit_generate_mount functionality.
libscript_cloudinit_generate_mount() {
  device="$1"
  mount_point="$2"
  fs_type="${3:-ext4}"
  
  if [ -z "$device" ] || [ -z "$mount_point" ]; then
    printf "Error: device and mount_point are required parameters.\n" >&2
    return 1
  fi
  
  # Outputs raw valid #cloud-config YAML to stdout
  cat <<CLOUD_INIT_EOF
#cloud-config

bootcmd:
  - mkdir -p ${mount_point}

disk_setup:
  ${device}:
    table_type: mbr
    layout: true
    overwrite: false

fs_setup:
  - label: data_vol
    filesystem: ${fs_type}
    device: ${device}1

mounts:
  - [ ${device}1, ${mount_point}, ${fs_type}, "defaults,nofail,discard", "0", "2" ]
CLOUD_INIT_EOF
}