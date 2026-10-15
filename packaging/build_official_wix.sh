#!/bin/sh
# ## Overview
# Orchestrates building the nodejs .msi via the official WiX Toolset on the guest.
#
# ## Usage
# ./packaging/build_official_wix.sh

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

# shellcheck disable=SC1091
. "${LIBSCRIPT_ROOT_DIR}/_lib/_common/pkg_mgr.sh"

# ## build_msi
# Builds the nodejs MSI artifact via Vagrant using the WiX toolchain.
build_msi() {
  COMPONENT="nodejs"
  VERSION="20.17.0"
  STAGE_ROOT="${LIBSCRIPT_ROOT_DIR}/tmp/stage_component_${COMPONENT}_offline"

  # Ensure the runtime payload is downloaded idempotently
  mkdir -p "${LIBSCRIPT_ROOT_DIR}/cache/runtimes"
  libscript_download "https://nodejs.org/dist/v${VERSION}/node-v${VERSION}-win-x64.zip" "${LIBSCRIPT_ROOT_DIR}/cache/runtimes/node-v${VERSION}-win-x64.zip"

  rm -rf "$STAGE_ROOT"
  mkdir -p "$STAGE_ROOT/bin"
  unzip -q -o "${LIBSCRIPT_ROOT_DIR}/cache/runtimes/node-v${VERSION}-win-x64.zip" -d "$STAGE_ROOT" || true
  
  _sub=$(find "$STAGE_ROOT" -mindepth 1 -maxdepth 1 -type d ! -name bin | head -n 1 || true)
  set +f
  if [ -n "$_sub" ]; then
    mv "$_sub"/* "$STAGE_ROOT/"
    rmdir "$_sub" 2>/dev/null || true
  fi
  set -f
  if [ -f "$STAGE_ROOT/node.exe" ] && [ ! -f "$STAGE_ROOT/bin/node.exe" ]; then
    cp -f "$STAGE_ROOT/node.exe" "$STAGE_ROOT/bin/"
  fi

  MAIN_WXS="${STAGE_ROOT}/${COMPONENT}_offline_main.wxs"
  PAYLOAD_WXS="${STAGE_ROOT}/${COMPONENT}_offline_payload.wxs"

  "${LIBSCRIPT_ROOT_DIR}/packaging/template_component_msi.sh" --component "$COMPONENT" --version "$VERSION" --variant offline --out "$MAIN_WXS"
  "${LIBSCRIPT_ROOT_DIR}/packaging/harvest_payload.sh" --source-dir "$STAGE_ROOT" --wix-fragment "$PAYLOAD_WXS" --component-group PayloadComponents --directory-id INSTALLFOLDER

  echo "[INFO] Syncing files to guest..."
  cd "${LIBSCRIPT_ROOT_DIR}/vagrant/windows-11"
  vagrant rsync
  PORT=$(vagrant ssh-config | awk '/Port / {print $2}')
  cd - >/dev/null

  VM_IP=127.0.0.1
  KEY=~/.vagrant.d/insecure_private_key
  SSH_CMD="ssh -p $PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $KEY vagrant@$VM_IP"
  SCP_CMD="scp -P $PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $KEY"

  echo "[INFO] Building MSI via official WiX on guest..."
  cat << 'PS1_EOF' > "${LIBSCRIPT_ROOT_DIR}/tmp/build_wix.ps1"
$ErrorActionPreference = 'Stop'
Set-Location C:\libscript\tmp\stage_component_nodejs_offline
& "$env:USERPROFILE\.libscript\wix\3.14\bin\candle.exe" -nologo -arch x64 -out nodejs_offline_main.wixobj nodejs_offline_main.wxs
& "$env:USERPROFILE\.libscript\wix\3.14\bin\candle.exe" -nologo -arch x64 -out nodejs_offline_payload.wixobj nodejs_offline_payload.wxs
& "$env:USERPROFILE\.libscript\wix\3.14\bin\light.exe" -nologo -sval -ext WixUIExtension -out nodejs-official.msi nodejs_offline_main.wixobj nodejs_offline_payload.wixobj
if (-not (Test-Path nodejs-official.msi)) {

  Write-Error "Failed to build nodejs-official.msi"
  exit 1
} else {
  Write-Host "Successfully built nodejs-official.msi"
  Copy-Item nodejs-official.msi -Destination C:\libscript\tmp\nodejs-official.msi -Force
}
PS1_EOF

  $SCP_CMD "${LIBSCRIPT_ROOT_DIR}/tmp/build_wix.ps1" vagrant@$VM_IP:C:/build_wix.ps1
  $SSH_CMD "powershell -ExecutionPolicy Bypass -File C:\build_wix.ps1"
}

build_msi
