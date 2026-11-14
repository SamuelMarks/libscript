#!/bin/sh
# ## Overview
# Compiles online and offline Windows Installer (.msi) packages for Open edX using
# zero-dependency POSIX shell orchestration over wixl (msitools) or WiX candle/light.
#
# ## Usage
# ./packaging/build.sh [--out-dir <dir>] [--online-only | --offline-only]

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

OUT_DIR="${SCRIPT_DIR}"
MODE='all'

# ## show_help
# Displays command-line usage instructions for the MSI build script.
show_help() {
  printf 'Usage: %s [--out-dir <dir>] [--online-only | --offline-only]\n' "$(basename "$THIS_FILE")"
  printf 'Compiles OpenEdX-Setup.msi and OpenEdX-Setup-Offline.msi via wixl or WiX Toolset.\n'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h|/\?|-\?)
      show_help
      exit 0
      ;;
    --out-dir)
      OUT_DIR="$2"
      shift 2
      ;;
    --out-dir=*)
      OUT_DIR="${1#*=}"
      shift
      ;;
    --online-only)
      MODE='online'
      shift
      ;;
    --offline-only)
      MODE='offline'
      shift
      ;;
    *)
      shift
      ;;
  esac
done

WIX_HOME="${LIBSCRIPT_HOME:-${HOME:-/tmp}/.libscript}/wix/3.14/bin"
if [ -d "$WIX_HOME" ]; then
  PATH="${WIX_HOME}:${PATH}"
  export PATH
fi

mkdir -p "$OUT_DIR"

# ## compile_wxs_pair
# Compiles a main and payload WiX source pair into a target MSI artifact idempotently.
compile_wxs_pair() {
  _base_name="$1"
  _main_wxs="${SCRIPT_DIR}/${_base_name}.wxs"
  _payload_wxs="${SCRIPT_DIR}/${_base_name}_payload.wxs"
  _out_msi="${OUT_DIR}/${_base_name}.msi"

  if [ ! -f "$_main_wxs" ]; then
    printf '[INFO] Source %s not present; delegating to build_msi.sh...\n' "$_main_wxs"
    if [ "$_base_name" = "OpenEdX-Setup-Offline" ]; then
      "${SCRIPT_DIR}/build_msi.sh" --offline --out-dir "$OUT_DIR"
    else
      "${SCRIPT_DIR}/build_msi.sh" --online --out-dir "$OUT_DIR"
    fi
    return 0
  fi

  if command -v candle.exe >/dev/null 2>&1 && command -v light.exe >/dev/null 2>&1; then
    printf '[INFO] Compiling %s via WiX candle.exe/light.exe...\n' "$_out_msi"
    (
      cd "$SCRIPT_DIR"
      candle.exe -nologo -out "${_base_name}.wixobj" "${_base_name}.wxs"
      if [ -f "$_payload_wxs" ]; then
        candle.exe -nologo -out "${_base_name}_payload.wixobj" "${_base_name}_payload.wxs"
        light.exe -nologo -sval -ext WixUIExtension -out "$_out_msi" "${_base_name}.wixobj" "${_base_name}_payload.wixobj"
      else
        light.exe -nologo -sval -ext WixUIExtension -out "$_out_msi" "${_base_name}.wixobj"
      fi
    )
  elif command -v wixl >/dev/null 2>&1; then
    printf '[INFO] Compiling %s via msitools wixl...\n' "$_out_msi"
    if [ -f "$_payload_wxs" ]; then
      wixl -o "$_out_msi" "$_main_wxs" "$_payload_wxs"
    else
      wixl -o "$_out_msi" "$_main_wxs"
    fi
  else
    printf '[ERROR] Neither WiX (candle.exe/light.exe) nor msitools (wixl) found on PATH.\n' >&2
    return 1
  fi
}

if [ "$MODE" = "all" ] || [ "$MODE" = "online" ]; then
  compile_wxs_pair "OpenEdX-Setup"
fi

if [ "$MODE" = "all" ] || [ "$MODE" = "offline" ]; then
  compile_wxs_pair "OpenEdX-Setup-Offline"
fi

printf '[OK] MSI compilation workflow completed in %s\n' "$OUT_DIR"
exit 0
