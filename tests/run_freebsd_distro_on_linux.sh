#!/bin/sh
# ## Overview
# Executes FreeBSD cross-synthesis and verification on Linux Vagrant VMs.
# Tests cross-synthesis tools, target-sysroot staging, and QEMU headless boot.
#
# ## Usage
# Run Linux host verification:
#   tests/run_freebsd_distro_on_linux.sh

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
RESULTS_FILE="${REPO_ROOT}/tests_tmp/results_linux.json"

printf '[MATRIX]   Running FreeBSD distribution validation on Linux environment...\n'

"${REPO_ROOT}/tests/freebsd_boot_test.sh"
"${REPO_ROOT}/tests/freebsd_gui_smoke_test.sh"
"${REPO_ROOT}/tests/test_freebsd_idempotency.sh"

cat << EOF > "${RESULTS_FILE}"
{
  "platform": "linux",
  "status": "PASS",
  "tests_run": ["boot_test", "gui_smoke_test", "idempotency"],
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF

printf '[OK]       Linux platform tests completed successfully.\n'
