#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
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

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/envsubst_safe.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

if [ -z "${ENV_SCRIPT_FILE+x}" ]; then
  >&2 printf 'ENV_SCRIPT_FILE must be set'
  exit 3
fi

# shellcheck disable=SC1090
. "${ENV_SCRIPT_FILE}"

case "${HTTPS_ALWAYS:-}" in
  '1'|'true')
    if [ -n "${NGINX_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET:-}}" ]; then
      export LISTEN_INSECURE="unix:${NGINX_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET}}"
      export LISTEN_SECURE="unix:${NGINX_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET}}"
    elif [ -n "${NGINX_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS:-}}" ]; then
      export LISTEN_INSECURE="${NGINX_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS}}:${NGINX_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-${WWWROOT_LISTEN:-80}}}"
      export LISTEN_SECURE="${NGINX_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS}}:${NGINX_LISTEN_PORT_SECURE:-${LIBSCRIPT_LISTEN_PORT_SECURE:-443}}"
    else
      export LISTEN_INSECURE="${NGINX_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-${WWWROOT_LISTEN:-80}}}"
      export LISTEN_SECURE="${NGINX_LISTEN_PORT_SECURE:-${LIBSCRIPT_LISTEN_PORT_SECURE:-443}}"
    fi
    conf_tpl="${LIBSCRIPT_ROOT_DIR}"'/_lib/_server/nginx/conf/simple_secure.conf' ;;
  *)
    if [ -n "${NGINX_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET:-}}" ]; then
      export LISTEN="unix:${NGINX_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET}}"
    elif [ -n "${NGINX_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS:-}}" ]; then
      export LISTEN="${NGINX_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS}}:${NGINX_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-${WWWROOT_LISTEN:-80}}}"
    else
      export LISTEN="${NGINX_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-${WWWROOT_LISTEN:-80}}}"
    fi
    conf_tpl="${LIBSCRIPT_ROOT_DIR}"'/_lib/_server/nginx/conf/simple_insecure.conf'
    ;;
esac

envsubst_safe < "${conf_tpl}"
