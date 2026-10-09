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
  # libscript-allow-eval
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

cd "${LIBSCRIPT_ROOT_DIR}/vagrant/windows-11"
PORT=$(vagrant ssh-config | awk '/Port / {print $2}')
cd - >/dev/null

VM_IP=127.0.0.1
KEY=~/.vagrant.d/insecure_private_key
SSH_CMD="ssh -p $PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $KEY vagrant@$VM_IP"
SCP_CMD="scp -P $PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $KEY"

echo "[INFO] Installing official WiX Toolset v3.14 on VM..."
cat << 'PS1_EOF' > "${LIBSCRIPT_ROOT_DIR}/tmp/install_wix.ps1"
$ErrorActionPreference = 'Stop'
if (-not (Test-Path C:\wix)) {
  New-Item -ItemType Directory -Force -Path C:\wix | Out-Null
  Write-Host "Downloading WiX Toolset..."
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  Invoke-WebRequest -Uri 'https://github.com/wixtoolset/wix3/releases/download/wix3141rtm/wix314-binaries.zip' -OutFile C:\wix.zip
  Write-Host "Extracting WiX Toolset..."
  Expand-Archive -Path C:\wix.zip -DestinationPath C:\wix -Force
  Remove-Item C:\wix.zip -Force
}
if (-not (Test-Path C:\wix\candle.exe) -or -not (Test-Path C:\wix\light.exe)) {
  Write-Error "WiX installation failed"
  exit 1
} else {
  Write-Host "WiX successfully installed."
}
PS1_EOF

$SCP_CMD "${LIBSCRIPT_ROOT_DIR}/tmp/install_wix.ps1" vagrant@$VM_IP:C:/wix_install.ps1
$SSH_CMD "powershell -ExecutionPolicy Bypass -File C:\wix_install.ps1"
