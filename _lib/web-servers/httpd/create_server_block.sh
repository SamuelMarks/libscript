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
DIR=$(CDPATH='' cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(D="${DIR}"; while [ ! -f "${D}"'/ROOT' ]; do D="$(dirname -- "${D}")"; done; printf '%s' "${D}")}"

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

# shellcheck disable=SC1090,SC1091,SC2034
. "${ENV_SCRIPT_FILE}"

export SERVER_NAME="${SERVER_NAME:-localhost}"
export LISTEN="${LISTEN:-80}"
export WWWROOT="${WWWROOT:-/var/www/html}"

if [ -n "${PHP_FPM_LISTEN:-}" ]; then
  httpd_php_listen="${HTTPD_PHP_FPM_LISTEN}"
  case "${httpd_php_listen}" in
    unix:*)
      export PHP_FPM_DIRECTIVE="    <FilesMatch \.php$>
        SetHandler \"proxy:${httpd_php_listen}|fcgi://localhost\"
    </FilesMatch>"
      ;;
    *)
      export PHP_FPM_DIRECTIVE="    <FilesMatch \.php$>
        SetHandler \"proxy:fcgi://${httpd_php_listen}\"
    </FilesMatch>"
      ;;
  esac
else
  export PHP_FPM_DIRECTIVE=""
fi

CONF_TPL="${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/httpd/conf/simple_server.conf"
envsubst_safe < "${CONF_TPL}"
