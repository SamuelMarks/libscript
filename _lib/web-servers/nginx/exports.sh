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
DIR=$(cd "$(dirname -- "${THIS_FILE}")" && pwd)

LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(D="${DIR}"; while [ ! -f "${D}/ROOT" ] && [ "${D}" != "/" ]; do D="$(dirname -- "${D}")"; done; [ "${D}" = "/" ] && D="${DIR}"; printf '%s' "${D}")}"
export LIBSCRIPT_ROOT_DIR

for LIB in _lib/_common/environ.sh ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

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
      # shellcheck disable=SC1090,SC1091
      . "${SCRIPT_NAME}"

      # shellcheck disable=SC1090,SC1091
      . "${ENV_SAVED_FILE}"

      unset ENV_SAVED_FILE
  fi
}
