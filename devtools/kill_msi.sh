#!/bin/sh
# ## Overview
# Auto-generated doc block for kill_msi.sh
#
# ## Usage
#   ./devtools/kill_msi.sh

set -feu

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

PORT=$(cd vagrant/windows-11 && vagrant ssh-config | awk '/Port / {print $2}')
ssh -p $PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.vagrant.d/insecure_private_key vagrant@127.0.0.1 "powershell -Command \"taskkill /F /IM msiexec.exe /T; Remove-Item C:\libscript\packaging\*.msi -Force -ErrorAction SilentlyContinue; Remove-Item C:\libscript\msi_error.txt -Force -ErrorAction SilentlyContinue\""
