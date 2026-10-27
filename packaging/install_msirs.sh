#!/bin/sh
# ## Overview
# Installs msi-rs natively on the Vagrant guest using LibScript.
#
# ## Usage
# ./packaging/install_msirs.sh

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

# ## install_msirs
# Connects to the Windows Vagrant guest via SSH and invokes LibScript's msi-rs recipe.
install_msirs() {
  VM_IP='192.168.56.10'
  KEY="${LIBSCRIPT_ROOT_DIR}/vagrant/windows-11/.vagrant/machines/default/vmware_desktop/private_key"
  SSH_CMD="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $KEY vagrant@$VM_IP"

  printf '[INFO] Installing msi-rs on VM via LibScript...\n'
  $SSH_CMD "powershell -Command \"\$ErrorActionPreference = 'Stop'; Set-Location C:\libscript; & 'C:\libscript\libscript.cmd' install msi-rs latest\""
}

install_msirs
