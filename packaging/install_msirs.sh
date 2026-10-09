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

echo "[INFO] Installing VC++ Redistributable..."
$SSH_CMD "powershell -Command \"\$ErrorActionPreference = 'Stop'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://aka.ms/vs/17/release/vc_redist.arm64.exe' -OutFile C:\vc_redist.arm64.exe; Start-Process -Wait -FilePath C:\vc_redist.arm64.exe -ArgumentList '/install /quiet /norestart'; Invoke-WebRequest -Uri 'https://aka.ms/vs/17/release/vc_redist.x64.exe' -OutFile C:\vc_redist.x64.exe; Start-Process -Wait -FilePath C:\vc_redist.x64.exe -ArgumentList '/install /quiet /norestart'\""

echo "[INFO] Installing Visual Studio Build Tools for MSVC (required by rust)..."
$SSH_CMD "powershell -Command \"\$ErrorActionPreference = 'Stop'; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://aka.ms/vs/17/release/vs_buildtools.exe' -OutFile C:\vs_buildtools.exe; Start-Process -Wait -FilePath C:\vs_buildtools.exe -ArgumentList '--quiet --wait --norestart --nocache --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK.19041'\""

echo "[INFO] Installing Rust via LibScript to compile msi-rs..."
$SSH_CMD "powershell -Command \"\$ErrorActionPreference = 'Stop'; Set-Location C:\libscript; & 'C:\libscript\libscript.cmd' install rust latest\""

echo "[INFO] Compiling msi-rs from synced folder..."
$SSH_CMD "powershell -Command \"\$ErrorActionPreference = 'Stop'; Set-Location C:\msi-rs; cargo build --release\""

echo "[INFO] Verifying compiled msi-rs candle.exe and light.exe..."
$SSH_CMD "powershell -Command \"\$ErrorActionPreference = 'Stop'; \$env:PATH = 'C:\msi-rs\target\release;' + \$env:PATH; if (-not (Get-Command candle.exe -ErrorAction SilentlyContinue) -or -not (Get-Command light.exe -ErrorAction SilentlyContinue)) { Write-Error 'msi-rs candle.exe or light.exe not found in PATH'; exit 1 } else { Write-Host 'msi-rs successfully compiled and verified.' }\""
