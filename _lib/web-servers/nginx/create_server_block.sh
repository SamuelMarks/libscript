#!/bin/sh
# shellcheck disable=SC3054,SC3040,SC2296,SC2128,SC2039,SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145



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

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/envsubst_safe.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091,SC2034
. "${SCRIPT_NAME}"

if [ -z "${ENV_SCRIPT_FILE+x}" ]; then
  >&2 printf 'ENV_SCRIPT_FILE must be set'
  exit 3
fi

# shellcheck disable=SC1090,SC1091,SC2034
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
    conf_tpl="${LIBSCRIPT_ROOT_DIR}"'/_lib/web-servers/nginx/conf/simple_secure.conf' ;;
  *)
    if [ -n "${NGINX_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET:-}}" ]; then
      export LISTEN="unix:${NGINX_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET}}"
    elif [ -n "${NGINX_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS:-}}" ]; then
      export LISTEN="${NGINX_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS}}:${NGINX_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-${WWWROOT_LISTEN:-80}}}"
    else
      export LISTEN="${NGINX_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-${WWWROOT_LISTEN:-80}}}"
    fi
    conf_tpl="${LIBSCRIPT_ROOT_DIR}"'/_lib/web-servers/nginx/conf/simple_insecure.conf'
    ;;
esac

envsubst_safe < "${conf_tpl}"
