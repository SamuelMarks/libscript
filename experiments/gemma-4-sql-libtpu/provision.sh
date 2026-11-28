#!/bin/sh
# ## Overview
# Provisions a TFRC-guarded Cloud TPU VM slice, arms auto-TTL, and bootstraps `libtpu`, `libtpu-rs`, and `uv` across workers for `gemma-4-sql-libtpu`.
# ## Usage
# ./experiments/gemma-4-sql-libtpu/provision.sh [--tfrc-config=<path>] [--repo-dir=<dir>] [--dry-run]

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

TPU_BOOTSTRAP_LIBTPU_RS='1'
export TPU_BOOTSTRAP_LIBTPU_RS
exec "${LIBSCRIPT_ROOT_DIR}/experiments/gemma-4-sql/provision.sh" "$@"
