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

case "${STACK+x}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
export STACK="${STACK:-}${this_file}"':'

DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)

LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${DIR}"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"
export LIBSCRIPT_ROOT_DIR

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/environ.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

infer_locations() {
  cwd="$(pwd)"
  locations_conf="${cwd}"'/.config/nginx/locations.conf'
  if [ -f "${locations_conf}" ]; then
     if [ -w . ]; then
       ENV_SAVED_FILE='tmp.nginx.env.sh'
     else
       ENV_SAVED_FILE='/tmp/nginx.env.sh'
     fi

     export ENV_SAVED_FILE
     save_environment >> "${ENV_SAVED_FILE}"

     clear_environment

     if [ -w . ]; then
       ENV_SAVED_FILE='tmp.nginx.env.sh'
     else
       ENV_SAVED_FILE='/tmp/nginx.env.sh'
     fi
     trap 'rm -f -- "${ENV_SAVED_FILE}"' EXIT HUP INT QUIT TERM

     # shellcheck disable=SC1090
     LIBSCRIPT_ROOT_DIR="$(. "${ENV_SAVED_FILE}"; printf '%s' "${LIBSCRIPT_ROOT_DIR}")"
     # shellcheck disable=SC1090
     VARS="$(. "${ENV_SAVED_FILE}"; printf '%s' "${VARS:-}")"

     SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/envsubst_safe.sh'
     export SCRIPT_NAME
     # shellcheck disable=SC1090
     . "${SCRIPT_NAME}"

     # shellcheck disable=SC1090
     . "${ENV_SAVED_FILE}"

     unset ENV_SAVED_FILE
  fi
}
