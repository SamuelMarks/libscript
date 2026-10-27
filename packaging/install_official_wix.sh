#!/bin/sh
# ## Overview
# Installs the official WiX Toolset on the Vagrant guest via SSH.
#
# ## Usage
# ./packaging/install_official_wix.sh

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

# ## install_wix
# Retrieves SSH connection details and idempotently installs WiX 3.14 on the guest.
install_wix() {
  cd "${LIBSCRIPT_ROOT_DIR}/vagrant/windows-11"
  PORT=$(vagrant ssh-config | awk '/Port / {print $2}')
  cd - >/dev/null

  VM_IP=127.0.0.1
  KEY=~/.vagrant.d/insecure_private_key
  SSH_CMD="ssh -p $PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $KEY vagrant@$VM_IP"

  echo '[INFO] Installing official WiX Toolset v3.14 on VM...'
  $SSH_CMD "powershell -Command \"\$ErrorActionPreference = 'Stop'; Set-Location C:\libscript; & 'C:\libscript\libscript.cmd' install wix 3.14\""
}

install_wix
