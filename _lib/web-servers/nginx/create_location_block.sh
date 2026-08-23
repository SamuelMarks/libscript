#!/bin/sh
# ## Overview
# Lifecycle script for create_location_block.sh.
#
# ## Usage
# Refer to the internal functions of create_location_block.sh for implementation details.


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

if [ -z "${SERVER_NAME+x}" ]; then
  >&2 printf 'SERVER_NAME must be set for nginx sites-available to work'
  exit 3
fi

export LOCATION_EXPR="${LOCATION_EXPR:-/}"

# guess which template is correct
if [ "${NGINX_FRAGMENT_CONF-}" ]; then
  if [ -f "${NGINX_FRAGMENT_CONF}" ]; then
    conf_child_tpl="${NGINX_FRAGMENT_CONF}"
  else
    conf_child_tpl="${LIBSCRIPT_ROOT_DIR}"'/'"${NGINX_FRAGMENT_CONF}"
    if [ ! -f "${conf_child_tpl}" ]; then
      >&2 printf 'Template to interpolate for nginx not found: "%s"\n' "${conf_child_tpl}"
      exit 2
    fi
  fi
elif [ "${NGINX_WWWROOT-}" ]; then
  if [ "${NGINX_PHP_FPM_LISTEN-}" ]; then
    conf_child_tpl="${LIBSCRIPT_ROOT_DIR}"'/_lib/web-servers/nginx/conf/simple_location_php.conf'
  elif [ "${WWWROOT_AUTOINDEX-}" ]; then
    conf_child_tpl="${LIBSCRIPT_ROOT_DIR}"'/_lib/web-servers/nginx/conf/simple_location_wwwroot_autoindex.conf'
  else
    conf_child_tpl="${LIBSCRIPT_ROOT_DIR}"'/_lib/web-servers/nginx/conf/simple_location_wwwroot.conf'
  fi
elif [ "${PROXY_PASS-}" ]; then
  if [ "${PROXY_WEBSOCKETS-}" ]; then
    if [ "${PROXY_WEBSOCKETS_ADVANCED-}" ]; then
      conf_child_tpl="${LIBSCRIPT_ROOT_DIR}"'/_lib/web-servers/nginx/conf/location_proxy_websockets.conf'
    else
      conf_child_tpl="${LIBSCRIPT_ROOT_DIR}"'/_lib/web-servers/nginx/conf/simple_location_proxy_websockets.conf'
    fi
  else
    conf_child_tpl="${LIBSCRIPT_ROOT_DIR}"'/_lib/web-servers/nginx/conf/simple_location_proxy.conf'
  fi
fi

if [ -z "${conf_child_tpl+x}" ]; then
  >&2 printf 'Could not determine which template to interpolate for nginx'
  exit 3
fi

envsubst_safe < "${conf_child_tpl}"
