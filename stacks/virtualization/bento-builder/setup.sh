#!/bin/sh
# ## Overview
# Orchestrates setup and installation for the Bento Builder stack.

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  eval 'THIS_FILE="${BASH_SOURCE[0]}"'
  eval 'set -o pipefail'
elif [ "${ZSH_VERSION-}" ]; then
  eval 'THIS_FILE="${(%):-%x}"'
  eval 'set -o pipefail'
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
export DIR="${SCRIPT_DIR}"
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
