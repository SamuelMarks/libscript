#!/bin/sh
# ## Overview
# Orchestrates the setup and installation process for the JupyterHub data science platform stack.
# 
# ## Usage
# Execute this script to install and configure jupyterhub on the local system.


set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
#RERUN_SCRIPT=0
#RERUN_SCRIPT=$(printf '%d' "$(eval printf '%s' "\$${SCRIPT_NAME}_RERUN_SCRIPT")")
#case "${STACK}" in
#  *':'"${THIS_FILE}"':'*)
#    if [ "${RERUN_SCRIPT}" -ne 1 ]; then

SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
DIR="${SCRIPT_DIR}"
export LIBSCRIPT_ROOT_DIR

for LIB in "_lib/_common/os_info.sh" ${_LIBSCRIPT_DUMMY_NO_RUN:-}; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

ENV_SCRIPT="${DIR}"'/env.sh'
if [ -f "${ENV_SCRIPT}" ]; then
  SCRIPT_NAME="${ENV_SCRIPT}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
fi

OS_SETUP_SCRIPT="${DIR}"'/setup_'"${TARGET_OS}"'.sh'
if [ -f "${OS_SETUP_SCRIPT}" ]; then
  SCRIPT_NAME="${OS_SETUP_SCRIPT}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
else
  SCRIPT_NAME="${DIR}"'/setup_generic.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
fi

case "${_LIBSCRIPT_TRUE:-1}" in
  "$( [ -n "${CADDY_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET:-}}" ] && printf '%s\n' 1 )")
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "unix:${CADDY_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET}}" >/dev/null 2>&1 ; then
    true
  fi
    ;;
  "$( [ -n "${CADDY_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS:-}}" ] && [ -n "${CADDY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ] && printf '%s\n' 1 )")
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "${CADDY_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS}}:${CADDY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 ; then
    true
  fi
    ;;
  "$( [ -n "${CADDY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ] && printf '%s\n' 1 )")
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "${CADDY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 ; then
    true
  fi
    ;;
esac
