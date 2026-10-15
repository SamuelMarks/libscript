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

# ## install_msirs
# Orchestrates compiling msi-rs on the Vagrant Windows guest.
install_msirs() {
  cd "${LIBSCRIPT_ROOT_DIR}/vagrant/windows-11"
  PORT=$(vagrant ssh-config | awk '/Port / {print $2}')
  cd - >/dev/null

  VM_IP=127.0.0.1
  KEY=~/.vagrant.d/insecure_private_key
  SSH_CMD="ssh -p $PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $KEY vagrant@$VM_IP"

  echo "[INFO] Ensuring VC++ Redistributable, MSVC, and Rust are installed..."
  # Idempotent dependency resolution via LibScript
  $SSH_CMD "powershell -Command \"\$ErrorActionPreference = 'Stop'; Set-Location C:\libscript; & 'C:\libscript\libscript.cmd' install vcredist latest; & 'C:\libscript\libscript.cmd' install msvc latest; & 'C:\libscript\libscript.cmd' install rust latest\""

  echo "[INFO] Compiling msi-rs from synced folder..."
  # Conditionally compile if it doesn't already exist
  cat << 'PS1_EOF' > "${LIBSCRIPT_ROOT_DIR}/tmp/install_msirs.ps1"
$ErrorActionPreference = 'Stop'
if (Test-Path "C:\msi-rs\target\release\candle.exe") {
  Write-Host "[INFO] msi-rs is already compiled. Skipping."
} else {
  Set-Location C:\msi-rs
  # Ensure the LibScript installed Rust is used
  $env:PATH = "C:\Users\vagrant\.cargo\bin;$env:PATH"
  $env:USERPROFILE = "C:\Users\vagrant"
  & rustup toolchain install 1.85.0-x86_64-pc-windows-msvc --force-non-host
  & rustup default 1.85.0-x86_64-pc-windows-msvc --force-non-host

  $vcvars = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
  if (-not (Test-Path $vcvars)) {
      $vcvars = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat"
      $cmd = "`"$vcvars`" x64 && cargo build --release"
  } else {
      $cmd = "`"$vcvars`" && cargo build --release"
  }

  cmd.exe /c $cmd
  if ($LASTEXITCODE -ne 0) {
    Write-Error "cargo build failed"
    exit 1
  }
}
$env:PATH = "C:\msi-rs\target\release;$env:PATH"
if (-not (Get-Command candle.exe -ErrorAction SilentlyContinue) -or -not (Get-Command light.exe -ErrorAction SilentlyContinue)) {
  Write-Error "msi-rs candle.exe or light.exe not found in PATH"
  exit 1
} else {
  Write-Host "msi-rs successfully compiled and verified."
}
PS1_EOF
  
  scp -P $PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $KEY "${LIBSCRIPT_ROOT_DIR}/tmp/install_msirs.ps1" vagrant@$VM_IP:C:/install_msirs.ps1
  $SSH_CMD "powershell -ExecutionPolicy Bypass -File C:\install_msirs.ps1"
}

install_msirs