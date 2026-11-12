#!/bin/sh
# ## Overview
# CLI command wrapper for the unified rapid cloud and Bento multi-OS Vagrant matrix experimentation lifecycle (`a` / `provision_instance`, `0` / `use_bento_fork`, `1` / `install_virtualization_stack`, `2` / `deploy_vagrant_box`, `3` / `snapshot_vagrant_box`, `4` / `test_libscript_components`, `5` / `send_logs_to_host`, `i` / `deprovision_instance`).
# ## Usage
# ./libscript.sh experiment [a|0|1|2|3|4|5|i|provision_instance|use_bento_fork|install_virtualization_stack|deploy_vagrant_box|snapshot_vagrant_box|test_libscript_components|send_logs_to_host|deprovision_instance|bento_matrix|all] [--target-os=alpine-3.24]
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
export LIBSCRIPT_ROOT_DIR
unset SCRIPT_NAME || true

STACK="${STACK%"${THIS_FILE}":}"
export STACK
exec "${LIBSCRIPT_ROOT_DIR}/_lib/cloud/core/experiment_cloud.sh" "$@"
