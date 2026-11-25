#!/bin/sh
# ## Overview
# Packages a synthesized DOS disk into a Vagrant .box archive (box.img + metadata.json + Vagrantfile)
# drop-in compatible with vagrant/{msdos-1.25,msdos-2.0,msdos-4.0,freedos-1.3,freedos-1.4}/.
#
# ## Usage
# ./synthesis/formats/dos_vagrant_box.sh <sysroot_dir> <output.box>

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

SYSROOT="${1:?Missing sysroot}"
OUT_BOX="${2:?Missing output .box path}"
BOX_STAGE="${TMPDIR:-/tmp}/dos_vbox_$$"
mkdir -p "${BOX_STAGE}" "$(dirname -- "${OUT_BOX}")"

STACK='' "${SCRIPT_DIR}/dos_qcow2.sh" "${SYSROOT}" "${BOX_STAGE}/box.img"
printf '{"provider":"qemu","format":"qcow2","virtual_size":1}\n' > "${BOX_STAGE}/metadata.json"
printf 'Vagrant.configure("2") do |config|\n  config.vm.guest = :freebsd\nend\n' > "${BOX_STAGE}/Vagrantfile"
tar -czf "${OUT_BOX}" -C "${BOX_STAGE}" metadata.json Vagrantfile box.img
rm -rf "${BOX_STAGE}"
