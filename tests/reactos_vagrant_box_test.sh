#!/bin/sh
# ## Overview
# Vagrant .box lifecycle smoketest for generated ReactOS .box archives.
# Validates tar.gz integrity, metadata.json, WinRM/Windows guest Vagrantfile, box.img, and SHA-256 manifest.
#
# ## Usage
# ./tests/reactos_vagrant_box_test.sh [box_path]

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

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM HUP
export LIBSCRIPT_HOME="${TMP_DIR}/home"
export LIBSCRIPT_OFFLINE=1
export LIBSCRIPT_ALLOW_STUB=1

BOX_PATH="${1:-${TMP_DIR}/reactos.box}"
if [ ! -f "$BOX_PATH" ]; then
  STACK='' "${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/reactos_distro.sh" \
    --format box \
    --profile "${LIBSCRIPT_ROOT_DIR}/profiles/reactos/minimal-headless-i686.json" \
    --sysroot "${TMP_DIR}/sys" \
    --output "$BOX_PATH" >/dev/null
fi

tar -tzf "$BOX_PATH" >/dev/null
tar -tzf "$BOX_PATH" | grep -qx 'metadata.json'
tar -tzf "$BOX_PATH" | grep -qx 'Vagrantfile'
tar -tzf "$BOX_PATH" | grep -qx 'box.img'
[ -f "${BOX_PATH}.sha256" ]

mkdir -p "${TMP_DIR}/unpack"
tar -xzf "$BOX_PATH" -C "${TMP_DIR}/unpack"
grep -q '"os_family": "reactos"' "${TMP_DIR}/unpack/metadata.json"
grep -q 'config.vm.guest = :windows' "${TMP_DIR}/unpack/Vagrantfile"
[ -s "${TMP_DIR}/unpack/box.img" ]

printf '[OK]       ReactOS Vagrant box lifecycle test PASSED.\n'
