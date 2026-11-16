#!/bin/sh
# ## Overview
# Unified multi-platform verification orchestrator for the ReactOS distribution matrix.
# Executes verification across {FreeBSD, Linux, macOS, Windows, SunOS} runners and writes
# structured status summary to tests_tmp/reactos_matrix_summary.json.
#
# ## Usage
# ./tests/run_reactos_distro_matrix.sh [--all]

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

if [ "${1:-}" = '--help' ] || [ "${1:-}" = '-h' ]; then
  printf 'Usage: %s [--all]\n' "$THIS_FILE"
  exit 0
fi

mkdir -p "${LIBSCRIPT_ROOT_DIR}/tests_tmp"
SUMMARY_FILE="${LIBSCRIPT_ROOT_DIR}/tests_tmp/reactos_matrix_summary.json"

printf '[MATRIX]   Starting Unified ReactOS Multi-Platform Verification Matrix...\n'

STACK='' "${SCRIPT_DIR}/run_reactos_distro_on_freebsd.sh"
STACK='' "${SCRIPT_DIR}/run_reactos_distro_on_linux.sh"
STACK='' "${SCRIPT_DIR}/run_reactos_distro_on_macos.sh"
STACK='' "${SCRIPT_DIR}/run_reactos_distro_on_windows.sh"
STACK='' "${SCRIPT_DIR}/run_reactos_distro_on_sunos.sh"

cat <<SUM_EOF > "$SUMMARY_FILE"
{
  "matrix_version": "1.0.0",
  "distribution": "reactos",
  "generated_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "platforms": {
    "freebsd": "PASS",
    "linux": "PASS",
    "macos": "PASS",
    "windows": "PASS",
    "sunos": "PASS"
  },
  "overall_status": "PASS"
}
SUM_EOF

printf '[OK]       All 5 platforms verified successfully for ReactOS!\n'
printf '[OK]       Summary written to %s\n' "$SUMMARY_FILE"
