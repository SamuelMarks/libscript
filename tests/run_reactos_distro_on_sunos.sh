#!/bin/sh
# ## Overview
# Executes ReactOS distribution synthesis, smoke tests, and 2-pass idempotency verification for sunos hosts.
#
# ## Usage
# ./tests/run_reactos_distro_on_sunos.sh

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

mkdir -p "${LIBSCRIPT_ROOT_DIR}/tests_tmp"
RESULTS_FILE="${LIBSCRIPT_ROOT_DIR}/tests_tmp/results_reactos_sunos.json"

printf '[MATRIX]   Running ReactOS distribution validation for %s...\n' 'sunos'
STACK='' "${SCRIPT_DIR}/run_reactos_tests.sh"

cat <<JSON_EOF > "$RESULTS_FILE"
{
  "platform": "sunos",
  "distribution": "reactos",
  "status": "PASS",
  "tests_run": ["boot_test", "gui_smoke_test", "network_smoke_test", "vagrant_box_test", "idempotency"],
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
JSON_EOF

printf '[OK]       %s ReactOS platform verification completed.\n' 'sunos'
