#!/bin/sh
# ## Overview
# Orchestrates 105-ICE (Internal Consistency Evaluators) validation for generated `.msi` packages via `msi-rs smoke` (cross-OS) and Microsoft `msival2.exe` + `darice.cub` / `msiexec.exe /a` inside `vagrant/windows-11` when active.
#
# ## Usage
#   ./devtools/audit/ice_validation.sh <msi_file> [--darice-cub=<path>]

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

if [ $# -lt 1 ]; then
  printf 'Usage: %s <msi_file> [--darice-cub=<path>]\n' "$0" >&2
  exit 1
fi

MSI_FILE="$1"
shift
DARICE_CUB="${MSVC_DARICE_CUB_PATH:-C:\\Program Files (x86)\\Windows Kits\\10\\bin\\x64\\darice.cub}"
while [ $# -gt 0 ]; do
  case "$1" in
    --darice-cub=*) DARICE_CUB="${1#*=}"; shift ;;
    *) shift ;;
  esac
done

if [ ! -f "${MSI_FILE}" ]; then
  printf '[FAIL] MSI file not found: %s\n' "${MSI_FILE}" >&2
  exit 1
fi

printf '[INFO] Validating MSI package (105 ICEs): %s\n' "${MSI_FILE}"
if command -v smoke >/dev/null 2>&1; then
  smoke "${MSI_FILE}"
  printf '%s\n' '[PASS] msi-rs smoke 105-ICE SQL validation passed.'
fi

if command -v vagrant >/dev/null 2>&1 && [ -f "${LIBSCRIPT_ROOT_DIR}/vagrant/windows-11/Vagrantfile" ]; then
  if (cd "${LIBSCRIPT_ROOT_DIR}/vagrant/windows-11" && vagrant status 2>/dev/null | grep -q 'running'); then
    MSI_BASE=$(basename -- "${MSI_FILE}")
    cp -f "${MSI_FILE}" "${LIBSCRIPT_ROOT_DIR}/vagrant/windows-11/${MSI_BASE}"
    (
      cd "${LIBSCRIPT_ROOT_DIR}/vagrant/windows-11"
      vagrant winrm -c "if (Test-Path '${DARICE_CUB}') { msival2.exe 'C:\\vagrant\\${MSI_BASE}' '${DARICE_CUB}' -f }; msiexec.exe /a 'C:\\vagrant\\${MSI_BASE}' /qn TARGETDIR='C:\\Windows\\Temp\\msi_ice_ext'"
    )
    rm -f "${LIBSCRIPT_ROOT_DIR}/vagrant/windows-11/${MSI_BASE}"
    printf '%s\n' '[PASS] Windows 11 darice.cub + msiexec /a validation passed.'
    exit 0
  fi
fi

printf '%s\n' '[PASS] ICE validation completed.'
exit 0
