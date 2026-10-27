#!/bin/sh
# ## Overview
# Environment initialization for Go.
#
# ## Usage
# Sets up `GO_VERSION` and prepends Go to PATH.


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

export GO_INSTALL_METHOD="${GO_INSTALL_METHOD:-system}"
GO_VERSION="${GO_VERSION:-latest}"
export GO_VERSION
_go_home="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/go"
if [ "$GO_INSTALL_METHOD" = "libscript_native" ] || [ -d "${_go_home}/${GO_VERSION}" ] || [ -d "${_go_home}/default" ]; then
  if [ -d "${_go_home}/${GO_VERSION}" ]; then
    export GOROOT="${_go_home}/${GO_VERSION}"
  elif [ -d "${_go_home}/default" ]; then
    export GOROOT="${_go_home}/default"
  else
    export GOROOT="${_go_home}/${GO_VERSION}"
  fi
  libscript_path_prepend "${GOROOT}/bin"
fi
for _go_sys_cand in "/usr/local/go/bin" "/opt/ooce/go/bin" "${HOME:-/root}/go/bin"; do
  if [ -d "$_go_sys_cand" ]; then
    libscript_path_prepend "$_go_sys_cand"
  fi
done
STACK="${STACK%"${THIS_FILE}":}"
export STACK
