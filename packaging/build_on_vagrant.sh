#!/bin/sh
# ## Overview
# Auto-generated doc block for build_on_vagrant.sh
#
# ## Usage
#   ./packaging/build_on_vagrant.sh

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

set -e
VM_IP=127.0.0.1
cd ../vagrant/windows-11
PORT=$(vagrant ssh-config | awk '/Port / {print $2}')
cd ../../packaging

KEY=~/.vagrant.d/insecure_private_key
SSH_CMD="ssh -p $PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $KEY vagrant@$VM_IP"
SCP_CMD="scp -P $PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $KEY"

echo "[INFO] Creating directories on VM..."
$SSH_CMD "powershell -Command \"New-Item -ItemType Directory -Force -Path C:\libscript\packaging\""

echo "[INFO] Uploading WXS files..."
$SCP_CMD OpenEdX-Setup.wxs OpenEdX-Setup_payload.wxs OpenEdX-Setup-Offline.wxs OpenEdX-Setup-Offline_payload.wxs vagrant@$VM_IP:C:/libscript/packaging/

cat << 'PS1_EOF' > build.ps1
$env:Path += ';' + $env:USERPROFILE + '\.libscript\wix\3.14\bin'
Set-Location C:\libscript\packaging
Write-Host "[INFO] Building Online MSI..."
candle.exe -nologo -out OpenEdX-Setup.wixobj OpenEdX-Setup.wxs
candle.exe -nologo -out OpenEdX-Setup_payload.wixobj OpenEdX-Setup_payload.wxs
light.exe -nologo -sval -ext WixUIExtension -out OpenEdX-Setup.msi OpenEdX-Setup.wixobj OpenEdX-Setup_payload.wixobj

Write-Host "[INFO] Building Offline MSI..."
candle.exe -nologo -out OpenEdX-Setup-Offline.wixobj OpenEdX-Setup-Offline.wxs
candle.exe -nologo -out OpenEdX-Setup-Offline_payload.wixobj OpenEdX-Setup-Offline_payload.wxs
light.exe -nologo -sval -ext WixUIExtension -out OpenEdX-Setup-Offline.msi OpenEdX-Setup-Offline.wixobj OpenEdX-Setup-Offline_payload.wixobj
PS1_EOF

$SCP_CMD build.ps1 vagrant@$VM_IP:C:/libscript/packaging/build.ps1
$SSH_CMD "powershell -ExecutionPolicy Bypass -File C:\libscript\packaging\build.ps1"

echo "[INFO] Downloading MSIs..."
$SCP_CMD vagrant@$VM_IP:C:/libscript/packaging/OpenEdX-Setup.msi .
$SCP_CMD vagrant@$VM_IP:C:/libscript/packaging/OpenEdX-Setup-Offline.msi .
echo "[PASS] Done!"
