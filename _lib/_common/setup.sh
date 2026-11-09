#!/bin/sh
# ## Overview
# Serves as the primary Unix setup entry point for a component, delegating to OS-specific setup scripts and registering netctl ports.
# ## Usage
# Execute this script to orchestrate a component's complete setup lifecycle.
set -feu
_common_setup_caller_this="${THIS_FILE:-}"; _common_setup_caller_dir="${SCRIPT_DIR:-}"
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
    [ -n "$_common_setup_caller_this" ] && THIS_FILE="$_common_setup_caller_this"
    [ -n "$_common_setup_caller_dir" ] && SCRIPT_DIR="$_common_setup_caller_dir"
    unset SCRIPT_NAME || true; if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export DIR="${SCRIPT_DIR}"
export LIBSCRIPT_ROOT_DIR
_common_setup_this="${THIS_FILE}"

for LIB in "_lib/_common/os_info.sh" ${_LIBSCRIPT_DUMMY_NO_RUN:-}; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME || true

ENV_SCRIPT="${DIR}"'/env.sh'
if [ -f "${ENV_SCRIPT}" ]; then
  SCRIPT_NAME="${ENV_SCRIPT}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
  unset SCRIPT_NAME || true
  STACK="${STACK%"${ENV_SCRIPT}":}"
  export STACK
fi

OS_SETUP_SCRIPT="${DIR}"'/setup_'"${TARGET_OS}"'.sh'
if [ -f "${OS_SETUP_SCRIPT}" ]; then
  _delegated_setup="${OS_SETUP_SCRIPT}"
else
  _delegated_setup="${DIR}"'/setup_generic.sh'
fi
SCRIPT_NAME="${_delegated_setup}"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true
STACK="${STACK%"${_delegated_setup}":}"
export STACK
unset _delegated_setup || true
THIS_FILE="${_common_setup_this}"
SCRIPT_DIR="${DIR}"

case "${_LIBSCRIPT_TRUE:-1}" in
  "$( [ -n "${CADDY_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET:-}}" ] && printf '%s\n' 1 )")
  if ! "${LIBSCRIPT_ROOT_DIR}/_lib/networking/netctl/cli.sh" --listen "unix:${CADDY_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET}}" >/dev/null 2>&1 ; then
    true
  fi
    ;;
  "$( [ -n "${CADDY_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS:-}}" ] && [ -n "${CADDY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ] && printf '%s\n' 1 )")
  if ! "${LIBSCRIPT_ROOT_DIR}/_lib/networking/netctl/cli.sh" --listen "${CADDY_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS}}:${CADDY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 ; then
    true
  fi
    ;;
  "$( [ -n "${CADDY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ] && printf '%s\n' 1 )")
  if ! "${LIBSCRIPT_ROOT_DIR}/_lib/networking/netctl/cli.sh" --listen "${CADDY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 ; then
    true
  fi
    ;;
esac

STACK="${STACK%"${THIS_FILE}":}"
export STACK
[ -n "${_common_setup_caller_dir:-}" ] && SCRIPT_DIR="$_common_setup_caller_dir"
[ -n "${_common_setup_caller_this:-}" ] && THIS_FILE="$_common_setup_caller_this"
unset SCRIPT_NAME _common_setup_caller_this _common_setup_caller_dir _common_setup_this || true
