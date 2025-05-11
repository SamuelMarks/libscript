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

if [ -z "${SERVER_NAME+x}" ]; then
  >&2 printf 'SERVER_NAME must be set for nginx sites-available to work'
  exit 3
fi

export LOCATION_EXPR="${LOCATION_EXPR:-/}"

# guess which template is correct
# shellcheck disable=SC2236
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
elif [ "${WWWROOT-}" ]; then
  if [ "${WWWROOT_AUTOINDEX-}" ]; then
    conf_child_tpl="${LIBSCRIPT_ROOT_DIR}"'/_lib/_server/nginx/conf/simple_location_wwwroot_autoindex.conf'
  else
    conf_child_tpl="${LIBSCRIPT_ROOT_DIR}"'/_lib/_server/nginx/conf/simple_location_wwwroot.conf'
  fi
elif [ "${PROXY_PASS-}" ]; then
  if [ "${PROXY_WEBSOCKETS-}" ]; then
    if [ "${PROXY_WEBSOCKETS_ADVANCED-}" ]; then
      conf_child_tpl="${LIBSCRIPT_ROOT_DIR}"'/_lib/_server/nginx/conf/location_proxy_websockets.conf'
    else
      conf_child_tpl="${LIBSCRIPT_ROOT_DIR}"'/_lib/_server/nginx/conf/simple_location_proxy_websockets.conf'
    fi
  else
    conf_child_tpl="${LIBSCRIPT_ROOT_DIR}"'/_lib/_server/nginx/conf/simple_location_proxy.conf'
  fi
fi

if [ -z "${conf_child_tpl+x}" ]; then
  >&2 printf 'Could not determine which template to interpolate for nginx'
  exit 3
fi

envsubst_safe < "${conf_child_tpl}"
