#!/bin/sh
# ## Overview
# Standalone POSIX script to provision the Bento Builder environment:
# - Hypervisors: QEMU / KVM, Oracle VirtualBox 7.0 + Extension Pack
# - HashiCorp Packer & HashiCorp Vagrant (with vagrant-libvirt)
# - ISO and Windows WIM tools: wimtools, xorriso, genisoimage, 7zip, cabextract
# - Ruby >= 3.1 & Bundler
# - Bento repo Packer plugin initialization & bundle install
#
# ## Usage
#   sh install_bento_builder.sh
#   or: ./install_bento_builder.sh

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
export LIBSCRIPT_ROOT_DIR

printf '%s\n' "===================================================="
printf '%s\n' " Bento Builder Environment Installer (POSIX /bin/sh)"
printf '%s\n' "===================================================="

# Invoke the bento-builder stack setup
sh "$SCRIPT_DIR/stacks/virtualization/bento-builder/setup.sh" install bento-builder latest

printf '%s\n' "Installation complete! Running validation tests..."
sh "$SCRIPT_DIR/stacks/virtualization/bento-builder/test.sh"
