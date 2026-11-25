#!/bin/sh
# ## Overview
# Lifecycle script for create_server_block.sh.
#
# ## Usage
# Refer to the internal functions of create_server_block.sh for implementation details.


set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
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
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export DIR="${SCRIPT_DIR}"

for LIB in "engine/common/envsubst_safe.sh" ${_LIBSCRIPT_DUMMY_NO_RUN:-}; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME || true

if [ -z "${ENV_SCRIPT_FILE+x}" ]; then
  >&2 printf 'ENV_SCRIPT_FILE must be set'
  exit 3
fi

_ws_saved_this="${THIS_FILE}"
_ws_saved_dir="${SCRIPT_DIR}"
SCRIPT_NAME="${ENV_SCRIPT_FILE}"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${ENV_SCRIPT_FILE}"
unset SCRIPT_NAME || true
THIS_FILE="${_ws_saved_this}"
SCRIPT_DIR="${_ws_saved_dir}"
unset _ws_saved_this _ws_saved_dir || true

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
      export NGINX_LISTEN="unix:${NGINX_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET}}"
    elif [ -n "${NGINX_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS:-}}" ]; then
      export NGINX_LISTEN="${NGINX_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS}}:${NGINX_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-${WWWROOT_LISTEN:-80}}}"
    else
      export NGINX_LISTEN="${NGINX_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-${WWWROOT_LISTEN:-80}}}"
    fi
    conf_tpl="${LIBSCRIPT_ROOT_DIR}"'/_lib/web-servers/nginx/conf/simple_insecure.conf'
    ;;
esac

envsubst_safe < "${conf_tpl}"
