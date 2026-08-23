#!/bin/sh
# ## Overview
# Lifecycle script for create_server_block.sh.
#
# ## Usage
# Refer to the internal functions of create_server_block.sh for implementation details.


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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export DIR="${SCRIPT_DIR}"

for LIB in "_lib/_common/envsubst_safe.sh" ${_LIBSCRIPT_DUMMY_NO_RUN:-}; do
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
  httpd_php_listen="${HTTPD_PHP_FPM_LISTEN}"
  case "${httpd_php_listen}" in
    unix:*)
      PHP_FPM_DIRECTIVE=$(printf '    <FilesMatch \\.php\$>n        SetHandler "proxy:%s|fcgi://localhost"n    </FilesMatch>' "${httpd_php_listen}")
      export PHP_FPM_DIRECTIVE
      ;;
    *)
      PHP_FPM_DIRECTIVE=$(printf '    <FilesMatch \\.php\$>n        SetHandler "proxy:fcgi://%s"n    </FilesMatch>' "${httpd_php_listen}")
      export PHP_FPM_DIRECTIVE
      ;;
  esac
else
  export PHP_FPM_DIRECTIVE=""
fi

CONF_TPL="${LIBSCRIPT_ROOT_DIR}/_lib/web-servers/httpd/conf/simple_server.conf"
envsubst_safe < "${CONF_TPL}"
