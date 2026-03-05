#!/bin/sh
# shellcheck disable=SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145



set -feu
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE}"

elif [ "${ZSH_VERSION-}" ]; then
  this_file="${0}"

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
