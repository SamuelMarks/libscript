#!/bin/sh

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

DIR=$(CDPATH='' cd -- "$(dirname -- "${THIS_FILE}")" && pwd)

LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(D="${DIR}"; while [ ! -f "${D}"'/ROOT' ]; do D="$(dirname -- "${D}")"; done; printf '%s' "${D}")}"
export LIBSCRIPT_ROOT_DIR

for LIB in _lib/_common/os_info.sh ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

ENV_SCRIPT="${DIR}"'/env.sh'
if [ -f "${ENV_SCRIPT}" ]; then
  SCRIPT_NAME="${ENV_SCRIPT}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
# shellcheck disable=SC1090,SC1091,SC2034
  . "${SCRIPT_NAME}"
fi

OS_SETUP_SCRIPT="${DIR}"'/setup_'"${TARGET_OS}"'.sh'
if [ -f "${OS_SETUP_SCRIPT}" ]; then
  SCRIPT_NAME="${OS_SETUP_SCRIPT}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
# shellcheck disable=SC1090,SC1091,SC2034
  . "${SCRIPT_NAME}"
else
  SCRIPT_NAME="${DIR}"'/setup_generic.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
# shellcheck disable=SC1090,SC1091,SC2034
  . "${SCRIPT_NAME}"
fi

if [ -n "${DRUPAL_LISTEN:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "${DRUPAL_LISTEN:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 ; then
    true
  fi
fi
