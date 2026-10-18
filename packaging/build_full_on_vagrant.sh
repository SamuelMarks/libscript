#!/bin/sh
# ## Overview
# Auto-generated doc block for build_full_on_vagrant.sh
#
# ## Usage
#   ./packaging/build_full_on_vagrant.sh

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

set -e
VM_IP=127.0.0.1
# shellcheck disable=SC2009
PORT=$(ps auxww | grep -i 'qemu.*windows-11' | grep -v grep | sed -n 's/.*hostfwd=tcp::\([0-9]*\)-:22.*/\1/p' | head -n 1 || true)
if [ -z "$PORT" ]; then
    PORT=$(cd vagrant/windows-11 && vagrant ssh-config | awk '/Port / {print $2}')
fi

KEY=~/.vagrant.d/insecure_private_key
SSH_CMD="ssh -p $PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $KEY vagrant@$VM_IP"
SCP_CMD="scp -P $PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $KEY"

echo "[INFO] Creating directories on VM..."
$SSH_CMD "powershell -Command \"New-Item -ItemType Directory -Force -Path C:\libscript\""

echo "[INFO] Archiving repo..."
tar -czf payload.tar.gz --exclude='.git' --exclude='vagrant' --exclude='tests_tmp' .

echo "[INFO] Uploading archive..."
$SCP_CMD payload.tar.gz vagrant@$VM_IP:C:/libscript/payload.tar.gz

echo "[INFO] Extracting archive on VM..."
$SSH_CMD "powershell -Command \"cd C:\libscript; tar -xzf payload.tar.gz\""
if [ -d "${LIBSCRIPT_ROOT_DIR}/../cc0-assets/libscript/openedx/assets" ]; then
    $SCP_CMD "${LIBSCRIPT_ROOT_DIR}/../cc0-assets/libscript/openedx/assets/"* vagrant@$VM_IP:C:/libscript/packaging/assets/
fi
cat << 'EOF' > build.ps1
$env:PATH += ';' + $env:USERPROFILE + '\.libscript\msi-rs\default\bin;' + $env:USERPROFILE + '\.libscript\msi-rs\v0.0.1\bin'
cd C:\libscript
cmd.exe /c packaging\build_msi.cmd _lib\web-apps\openedx --online --out OpenEdX-Setup
cmd.exe /c packaging\build_msi.cmd _lib\web-apps\openedx --offline --out OpenEdX-Setup-Offline
EOF

$SCP_CMD build.ps1 vagrant@$VM_IP:C:/libscript/build.ps1
rm -f payload.tar.gz build.ps1
$SSH_CMD "powershell -ExecutionPolicy Bypass -File C:\libscript\build.ps1"

echo "[INFO] Downloading MSIs..."
$SCP_CMD vagrant@$VM_IP:C:/libscript/OpenEdX-Setup.msi packaging/OpenEdX-Setup.msi
$SCP_CMD vagrant@$VM_IP:C:/libscript/OpenEdX-Setup-Offline.msi packaging/OpenEdX-Setup-Offline.msi
echo "[PASS] Done!"
