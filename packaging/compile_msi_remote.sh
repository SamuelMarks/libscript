#!/bin/sh
set -feu

# ## Overview
# Helper to compile MSI remotely via an external or remote service.
#
# ## Usage
#   ./compile_msi_remote.sh <WXS_FILE>

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
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

OUT_FILE="$(basename "$1")"

# Wait for sync to complete via polling the wxs file
sleep 2

VAGRANT_DIR="${LIBSCRIPT_ROOT_DIR}/vagrant/windows-11"
SSH_PORT=$(cd "${VAGRANT_DIR}" && vagrant ssh-config 2>/dev/null | awk '/Port / {print $2; exit}' || true)
: "${SSH_PORT:=50523}"
SSH_KEY="${HOME}/.vagrant.d/insecure_private_key"
SSH_CMD="ssh -p ${SSH_PORT} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -i ${SSH_KEY} vagrant@127.0.0.1"

printf '[INFO] Initiating remote compilation for %s.wxs via Vagrant guest...\n' "${OUT_FILE}"

cat << 'PS1_EOF' > /tmp/remote_build.ps1
$env:Path += ';C:\libscript\tools\wix'
candle.exe -nologo -out "C:\Users\vagrant\Desktop\${OUT_FILE}.wixobj" "C:\libscript\packaging\${OUT_FILE}.wxs"
candle.exe -nologo -out "C:\Users\vagrant\Desktop\${OUT_FILE}_payload.wixobj" "C:\libscript\packaging\${OUT_FILE}_payload.wxs"
light.exe -nologo -sval -ext WixUIExtension -out "C:\Users\vagrant\Desktop\${OUT_FILE}.msi" "C:\Users\vagrant\Desktop\${OUT_FILE}.wixobj" "C:\Users\vagrant\Desktop\${OUT_FILE}_payload.wixobj"
PS1_EOF

sed -i '' "s|\${OUT_FILE}|${OUT_FILE}|g" /tmp/remote_build.ps1

scp -P "${SSH_PORT}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -i "${SSH_KEY}" /tmp/remote_build.ps1 "vagrant@127.0.0.1:C:/Users/vagrant/Desktop/remote_build.ps1"

$SSH_CMD "powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:/Users/vagrant/Desktop/remote_build.ps1"

scp -P "${SSH_PORT}" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -i "${SSH_KEY}" "vagrant@127.0.0.1:C:/Users/vagrant/Desktop/${OUT_FILE}.msi" "packaging/${OUT_FILE}.msi"

printf '[PASS] Successfully retrieved natively compiled %s.msi\n' "${OUT_FILE}"
exit 0
