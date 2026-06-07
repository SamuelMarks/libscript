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

for LIB in _lib/_common/envsubst_safe.sh ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

if [ -z "${ENV_SCRIPT_FILE+x}" ]; then
  >&2 printf 'ENV_SCRIPT_FILE must be set'
  exit 3
fi

# shellcheck disable=SC1090,SC1091
. "${ENV_SCRIPT_FILE}"

export SERVER_NAME="${SERVER_NAME:-localhost}"
export LISTEN="${LISTEN:-80}"
export WWWROOT="${WWWROOT:-/var/www/html}"

if [ -n "${PHP_FPM_LISTEN:-}" ]; then
  # Caddy php_fastcgi format: php_fastcgi unix//run/php/php-fpm.sock or 127.0.0.1:9000
  # If PHP_FPM_LISTEN starts with "unix:", we need to change it to "unix//" for Caddy
  CADDY_PHP_LISTEN="${CADDY_PHP_FPM_LISTEN}"
  case "${CADDY_PHP_LISTEN}" in
    unix:/*)
      CADDY_PHP_LISTEN="unix/$(echo "${CADDY_PHP_LISTEN}" | sed 's|^unix:/|/|')"
      ;;
  esac
  export PHP_FPM_DIRECTIVE="php_fastcgi ${CADDY_PHP_LISTEN}"
else
  export PHP_FPM_DIRECTIVE=""
fi

CONF_TPL="${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/caddy/conf/simple_server.caddy"
envsubst_safe < "${CONF_TPL}"
