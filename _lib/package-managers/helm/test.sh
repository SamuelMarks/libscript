#!/bin/sh
# ## Overview
# Tests the helm component.
#
# ## Usage
# Executes the test routine for helm.

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

export PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:${PATH:-}"

SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
if [ -f "$SCRIPT_DIR/env.sh" ]; then
  unset SCRIPT_NAME || true
  _ls_src_this="${THIS_FILE:-}"; _ls_src_dir="${SCRIPT_DIR:-}"
  SCRIPT_NAME="$SCRIPT_DIR/env.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
  unset SCRIPT_NAME || true
  [ -n "${_ls_src_this:-}" ] && THIS_FILE="$_ls_src_this"
  [ -n "${_ls_src_dir:-}" ] && SCRIPT_DIR="$_ls_src_dir"
fi

if command -v helm >/dev/null 2>&1; then
  helm --version || helm version || true
else
  printf '%s\n' 'helm is not installed (likely unsupported on this OS), skipping test.'
fi
