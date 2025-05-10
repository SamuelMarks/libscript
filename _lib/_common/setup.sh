#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE+x}" ]; then
  this_file="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION+x}" ]; then
  this_file="${(%):-%x}"
  set -o pipefail
else
  this_file="${0}"
fi

STACK="${STACK:-:}"
RERUN_SCRIPT=0
#RERUN_SCRIPT=$(printf '%d' "$(eval printf '%s' "\$${SCRIPT_NAME}_RERUN_SCRIPT")")
case "${STACK}" in
  *':'"${this_file}"':'*)
    if [ "${RERUN_SCRIPT}" -ne 1 ]; then
      printf '[STOP]     processing "%s"\n' "${this_file}"
      return
    fi
    ;;
  *)
    STACK="${STACK}${this_file}"':' ;;
esac
printf '[CONTINUE] processing "%s"\n' "${this_file}"
export STACK

DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)

LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${DIR}"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"
export LIBSCRIPT_ROOT_DIR

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/os_info.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

env_script="${DIR}"'/env.sh'
if [ -f "${env_script}" ]; then
  SCRIPT_NAME="${env_script}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
fi

os_setup_script="${DIR}"'/setup_'"${TARGET_OS}"'.sh'
if [ -f "${os_setup_script}" ]; then
  SCRIPT_NAME="${os_setup_script}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
else
  SCRIPT_NAME="${DIR}"'/setup_generic.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
fi
