#!/bin/sh

# shellcheck disable=SC2236
if [ ! -z "${SCRIPT_NAME+x}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ ! -z "${BASH_VERSION+x}" ]; then
  # shellcheck disable=SC3028 disable=SC3054
  this_file="${BASH_SOURCE[0]}"
  # shellcheck disable=SC3040
  set -o pipefail
elif [ ! -z "${ZSH_VERSION+x}" ]; then
  # shellcheck disable=SC2296
  this_file="${(%):-%x}"
  # shellcheck disable=SC3040
  set -o pipefail
else
  this_file="${0}"
fi
set -feu

STACK="${STACK:-:}"
case "${STACK}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    return ;;
  *)
    printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
STACK="${STACK}${this_file}"':'
export STACK

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
