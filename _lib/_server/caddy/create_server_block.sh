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

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/envsubst_safe.sh'
export SCRIPT_NAME
. "${SCRIPT_NAME}"

if [ -z "${ENV_SCRIPT_FILE+x}" ]; then
  >&2 printf 'ENV_SCRIPT_FILE must be set'
  exit 3
fi

. "${ENV_SCRIPT_FILE}"

export SERVER_NAME="${SERVER_NAME:-localhost}"
export LISTEN="${LISTEN:-80}"
export WWWROOT="${WWWROOT:-/var/www/html}"

if [ -n "${PHP_FPM_LISTEN:-}" ]; then
  # Caddy php_fastcgi format: php_fastcgi unix//run/php/php-fpm.sock or 127.0.0.1:9000
  # If PHP_FPM_LISTEN starts with "unix:", we need to change it to "unix//" for Caddy
  caddy_php_listen="${PHP_FPM_LISTEN}"
  case "${caddy_php_listen}" in
    unix:/*)
      caddy_php_listen="unix/$(echo "${caddy_php_listen}" | sed 's|^unix:/|/|')"
      ;;
  esac
  export PHP_FPM_DIRECTIVE="php_fastcgi ${caddy_php_listen}"
else
  export PHP_FPM_DIRECTIVE=""
fi

conf_tpl="${LIBSCRIPT_ROOT_DIR}/_lib/_server/caddy/conf/simple_server.caddy"
envsubst_safe < "${conf_tpl}"
