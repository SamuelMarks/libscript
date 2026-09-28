#!/bin/sh
# ## Overview
# Unified multi-platform verification orchestrator for the FreeBSD distribution matrix.
# Executes tests sequentially across all 5 target environments: {macOS, Windows, FreeBSD, SunOS, Linux}.
# Aggregates pass/fail status into tests_tmp/freebsd_matrix_summary.json.
#
# ## Usage
# Run multi-platform test matrix:
#   tests/run_freebsd_distro_matrix.sh [--all | --platforms <list>]

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *":"*"\${THIS_FILE}:"*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}:"
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
REPO_ROOT="${LIBSCRIPT_ROOT_DIR}"

mkdir -p "${REPO_ROOT}/tests_tmp"
SUMMARY_FILE="${REPO_ROOT}/tests_tmp/freebsd_matrix_summary.json"

printf '[MATRIX]   Starting Unified FreeBSD Multi-Platform Verification Matrix...\n'

# Run verification across all 5 platforms
"${SCRIPT_DIR}/run_freebsd_distro_on_freebsd.sh"
"${SCRIPT_DIR}/run_freebsd_distro_on_linux.sh"
"${SCRIPT_DIR}/run_freebsd_distro_on_macos.sh"
"${SCRIPT_DIR}/run_freebsd_distro_on_windows.sh"
"${SCRIPT_DIR}/run_freebsd_distro_on_sunos.sh"

cat << EOF > "${SUMMARY_FILE}"
{
  "matrix_version": "1.0.0",
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
EOF

printf '[OK]       All 5 Vagrant platforms verified successfully!\n'
printf '[OK]       Summary written to %s\n' "${SUMMARY_FILE}"
