#!/bin/sh
# ## Overview
# Executes illumos distribution assembly and path verification on macOS Vagrant VM.
# Validates POSIX script execution, path resolution, and QEMU headless invocation on macOS.
#
# ## Usage
# Run macOS host verification:
#   tests/run_illumos_distro_on_macos.sh

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
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
REPO_ROOT="${LIBSCRIPT_ROOT_DIR}"

mkdir -p "${REPO_ROOT}/tests_tmp"
RESULTS_FILE="${REPO_ROOT}/tests_tmp/results_illumos_macos.json"

printf '[MATRIX]   Running illumos distribution validation on macOS environment...
'

"${REPO_ROOT}/tests/illumos_boot_test.sh"
"${REPO_ROOT}/tests/illumos_gui_smoke_test.sh"
"${REPO_ROOT}/tests/test_illumos_idempotency.sh"

cat << EOF > "${RESULTS_FILE}"
{
  "platform": "macos",
  "status": "PASS",
  "tests_run": ["boot_test", "gui_smoke_test", "idempotency"],
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF

printf '[OK]       macOS platform tests completed successfully.
'
