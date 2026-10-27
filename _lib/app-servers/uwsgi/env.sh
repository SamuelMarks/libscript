#!/bin/sh
# ## Overview
# Environment variable setup for uWSGI server.
#
# ## Usage
# Source or execute this script to set environment variables for uwsgi.

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
_EB_CALLER_THIS="${THIS_FILE}"
_EB_CALLER_DIR="${SCRIPT_DIR}"
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/env_base.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true

export UWSGI_WORKERS="${UWSGI_WORKERS:-2}"
UWSGI_VERSION="${UWSGI_VERSION:-2.0.24}"
if [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/uwsgi/${UWSGI_VERSION}/bin" ]; then
  libscript_path_prepend "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/uwsgi/${UWSGI_VERSION}/bin"
fi
if [ -d "${HOME:-/root}/.local/bin" ]; then
  libscript_path_prepend "${HOME:-/root}/.local/bin"
fi
STACK="${STACK%"${THIS_FILE}":}"
export STACK
