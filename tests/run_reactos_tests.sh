#!/bin/sh
# ## Overview
# Runs all standalone ReactOS distribution, exporter, boot, GUI, network, Vagrant box, and idempotency tests.
#
# ## Usage
# ./tests/run_reactos_tests.sh

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

STACK='' "${SCRIPT_DIR}/reactos_boot_test.sh"
STACK='' "${SCRIPT_DIR}/reactos_gui_smoke_test.sh"
STACK='' "${SCRIPT_DIR}/reactos_network_smoke_test.sh"
STACK='' "${SCRIPT_DIR}/reactos_vagrant_box_test.sh"
STACK='' "${SCRIPT_DIR}/test_reactos_idempotency.sh"

printf '[OK]       All ReactOS distribution tests PASSED.\n'
