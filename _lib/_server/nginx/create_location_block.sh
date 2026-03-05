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
elif [ "${WWWROOT-}" ]; then
  if [ "${PHP_FPM_LISTEN-}" ]; then
    conf_child_tpl="${LIBSCRIPT_ROOT_DIR}"'/_lib/_server/nginx/conf/simple_location_php.conf'
  elif [ "${WWWROOT_AUTOINDEX-}" ]; then
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
