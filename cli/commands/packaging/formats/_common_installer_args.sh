#!/bin/sh
# ## Overview
# Shared arguments and utility functions for package installers.
# 
# ## Usage
# This script is called by the packaging system and should not be executed manually.


set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  eval 'THIS_FILE="${BASH_SOURCE[0]}"'
  eval 'set -o pipefail'
elif [ "${ZSH_VERSION-}" ]; then
  eval 'THIS_FILE="${(%):-%x}"'
  eval 'set -o pipefail'
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
    export install_scope="perMachine"
    export inno_priv="admin"
    export nsis_admin="admin"
    APP_NAME="LibScript Deployment"
    APP_VERSION="1.0.0.0"
    export APP_PUBLISHER="LibScript"
    export APP_URL=""
    UPGRADE_CODE="PUT-GUID-HERE"
    export OUT_FILE="LibScriptInstaller"
    export ICON_PATH=""
    export IMAGE_PATH=""
    export LICENSE_PATH=""
    export WELCOME_TEXT="Welcome to the LibScript Deployment Installer"
    export OFFLINE="0"

    while [ $# -gt 0 ]; do
      case "$1" in
        --user-mode) export install_scope="perUser"; export inno_priv="lowest"; export nsis_admin="user"; shift ;;
        --elevated-mode) export install_scope="perMachine"; export inno_priv="admin"; export nsis_admin="admin"; shift ;;
        --app-name) APP_NAME="$2"; shift 2 ;;
        --app-version) APP_VERSION="$2"; shift 2 ;;
        --app-publisher) export APP_PUBLISHER="$2"; shift 2 ;;
        --app-url) export APP_URL="$2"; shift 2 ;;
        --upgrade-code) UPGRADE_CODE="$2"; shift 2 ;;
        --out-file) export OUT_FILE="$2"; shift 2 ;;
        --icon) export ICON_PATH="$2"; shift 2 ;;
        --image) export IMAGE_PATH="$2"; shift 2 ;;
        --license) export LICENSE_PATH="$2"; shift 2 ;;
        --welcome) export WELCOME_TEXT="$2"; shift 2 ;;
        --offline) export OFFLINE="1"; shift ;;
        -*) printf '%s\n' "Error: Unknown option $1" >&2; exit 1 ;;
        *) break ;;
      esac
    done



    export PRODUCT_CODE="*"
    _SVC_NAME=$(printf '%s\n' "$APP_NAME" | tr " " "_")
    _UPGRADE_ID="${APP_NAME}|${_SVC_NAME}|x64"
    _PRODUCT_ID="${APP_NAME}|${_SVC_NAME}|x64|${APP_VERSION}"

    if command -v jq >/dev/null 2>&1 && command -v sha256sum >/dev/null 2>&1; then
      if [ "$UPGRADE_CODE" = "PUT-GUID-HERE" ]; then
        _UPGRADE_HASH=$(printf "%s" "$_UPGRADE_ID" | sha256sum | awk '{print $1}')
        UPGRADE_CODE=$(jq -n -r '
          def hex_to_guid: .[0:8] + "-" + .[8:12] + "-" + .[12:16] + "-" + .[16:20] + "-" + .[20:32];
          def as_uuidv5_bits: .[0:12] + "5" + .[13:] | .[0:16] + "a" + .[17:];
          def guid_from_string: .[0:32] | as_uuidv5_bits | hex_to_guid;
          $ARGS.positional[0] | guid_from_string
        ' --args "$_UPGRADE_HASH")
      fi
      if [ "${pkg_type:-}" = "msi" ]; then
        _PRODUCT_HASH=$(printf "%s" "$_PRODUCT_ID" | sha256sum | awk '{print $1}')
        PRODUCT_CODE=$(jq -n -r '
          def hex_to_guid: .[0:8] + "-" + .[8:12] + "-" + .[12:16] + "-" + .[16:20] + "-" + .[20:32];
          def as_uuidv5_bits: .[0:12] + "5" + .[13:] | .[0:16] + "a" + .[17:];
          def guid_from_string: .[0:32] | as_uuidv5_bits | hex_to_guid;
          $ARGS.positional[0] | guid_from_string
        ' --args "$_PRODUCT_HASH")
      fi
    elif command -v powershell >/dev/null 2>&1 || command -v pwsh >/dev/null 2>&1; then
      _PS="powershell"
      command -v pwsh >/dev/null 2>&1 && _PS="pwsh"
      _PS_SCRIPT="
        param([string]\$id)
        \$b = [System.Text.Encoding]::UTF8.GetBytes(\$id)
        \$h = [System.Security.Cryptography.SHA256]::Create().ComputeHash(\$b)
        \$x = [System.BitConverter]::ToString(\$h).Replace('-', '').ToLower()
        Write-Output (\$x.Substring(0,8) + '-' + \$x.Substring(8,4) + '-5' + \$x.Substring(13,3) + '-a' + \$x.Substring(17,3) + '-' + \$x.Substring(20,12))
      "
      if [ "$UPGRADE_CODE" = "PUT-GUID-HERE" ]; then
        UPGRADE_CODE=$($_PS -NoProfile -Command "$_PS_SCRIPT" -id "$_UPGRADE_ID")
      fi
      if [ "${pkg_type:-}" = "msi" ]; then
        PRODUCT_CODE=$($_PS -NoProfile -Command "$_PS_SCRIPT" -id "$_PRODUCT_ID")
      fi
    fi

