#!/bin/sh
# ## Overview
# Builds an installer target with SamuelMarks/msi-rs (default) and optionally compares its
# MSI tables and structure against the Windows-only WiX Toolset using msiinfo and msidiff.
# Never invokes WiX on Linux, macOS, FreeBSD, or illumos unless explicitly delegating to
# the Windows 11 Vagrant VM (--with-windows-vagrant).
#
# ## Usage
# ./packaging/compare_msirs_wix.sh [--target <dir>] [--variant <online|offline>] [--out-dir <dir>] [--with-windows-vagrant]

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
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"

TARGET_DIR='_lib/web-apps/openedx'
VARIANT='online'
OUT_DIR="${LIBSCRIPT_ROOT_DIR}/tmp/compare_msi"
WITH_WINDOWS_VAGRANT=0

# ## show_help
# Prints command-line usage instructions for compare_msirs_wix.sh.
show_help() {
  printf 'Usage: %s [--target <dir>] [--variant <online|offline>] [--out-dir <dir>] [--with-windows-vagrant]
' "$0"
  printf 'Builds target MSI with msi-rs and optionally compares against Windows-only WiX.
'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --target)
      TARGET_DIR="$2"
      shift 2
      ;;
    --variant)
      VARIANT="$2"
      shift 2
      ;;
    --out-dir)
      OUT_DIR="$2"
      shift 2
      ;;
    --with-windows-vagrant)
      WITH_WINDOWS_VAGRANT=1
      shift
      ;;
    --help|-h|/\?|-\?)
      show_help
      exit 0
      ;;
    *)
      TARGET_DIR="$1"
      shift
      ;;
  esac
done

# ## ensure_msirs_env
# Ensures msi-rs tools (msiinfo, msidiff) are available on PATH.
ensure_msirs_env() {
  if [ -d "${LIBSCRIPT_HOME:-$HOME/.libscript}/msi-rs/default/bin" ]; then
    PATH="${LIBSCRIPT_HOME:-$HOME/.libscript}/msi-rs/default/bin:${PATH}"
    export PATH
  elif [ -d "${LIBSCRIPT_HOME:-$HOME/.libscript}/msi-rs/v0.0.1/bin" ]; then
    PATH="${LIBSCRIPT_HOME:-$HOME/.libscript}/msi-rs/v0.0.1/bin:${PATH}"
    export PATH
  fi
}

# ## run_comparison
# Builds the msi-rs MSI and optionally compares against Windows WiX.
run_comparison() {
  ensure_msirs_env
  mkdir -p "$OUT_DIR"
  _base_name=$(basename "$TARGET_DIR")
  _msirs_out="${OUT_DIR}/${_base_name}-${VARIANT}-msirs"
  _wix_out="${OUT_DIR}/${_base_name}-${VARIANT}-wix"

  printf '[INFO] Building %s (%s) via SamuelMarks/msi-rs...
' "$TARGET_DIR" "$VARIANT"
  "${SCRIPT_DIR}/build_msi.sh" "$TARGET_DIR" "--${VARIANT}" --out "$_msirs_out"

  if command -v msiinfo >/dev/null 2>&1; then
    msiinfo tables "${_msirs_out}.msi" > "${_msirs_out}.tables.txt" 2>/dev/null || true
    printf '[PASS] Extracted msi-rs tables to %s.tables.txt
' "$_msirs_out"
  fi

  if [ "${OS:-}" = "Windows_NT" ] || [ "$WITH_WINDOWS_VAGRANT" -eq 1 ]; then
    printf '[INFO] Building %s (%s) via Windows WiX (--use-wix) for A/B comparison...
' "$TARGET_DIR" "$VARIANT"
    "${SCRIPT_DIR}/build_msi.sh" "$TARGET_DIR" "--${VARIANT}" --use-wix --out "$_wix_out"
    if command -v msiinfo >/dev/null 2>&1 && [ -f "${_wix_out}.msi" ]; then
      msiinfo tables "${_wix_out}.msi" > "${_wix_out}.tables.txt" 2>/dev/null || true
      diff -u "${_msirs_out}.tables.txt" "${_wix_out}.tables.txt" > "${OUT_DIR}/${_base_name}-${VARIANT}-tables.diff" 2>&1 || true
    fi
    if command -v msidiff >/dev/null 2>&1 && [ -f "${_wix_out}.msi" ]; then
      msidiff "${_msirs_out}.msi" "${_wix_out}.msi" > "${OUT_DIR}/${_base_name}-${VARIANT}-msidiff.txt" 2>&1 || true
      printf '[PASS] Generated msidiff report at %s/%s-%s-msidiff.txt
' "$OUT_DIR" "$_base_name" "$VARIANT"
    fi
  else
    printf '[INFO] Skipping WiX build on non-Windows host (WiX is Windows-only; pass --with-windows-vagrant to delegate to vagrant/windows-11).
'
  fi
}

run_comparison
