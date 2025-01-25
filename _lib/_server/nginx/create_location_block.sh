#!/bin/sh

# shellcheck disable=SC2236
if [ ! -z "${SCRIPT_NAME+x}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ ! -z "${BASH_VERSION+x}" ]; then
  # shellcheck disable=SC3028 disable=SC3054
  this_file="${BASH_SOURCE[0]}"
  # shellcheck disable=SC3040
  set -o pipefail
elif [ ! -z "${ZSH_VERSION+x}" ]; then
  # shellcheck disable=SC2296
  this_file="${(%):-%x}"
  # shellcheck disable=SC3040
  set -o pipefail
else
  this_file="${0}"
fi
set -feu

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
if [ ! -z "${NGINX_FRAGMENT_CONF+x}" ]; then
  if [ -f "${NGINX_FRAGMENT_CONF}" ]; then
    conf_child_tpl="${NGINX_FRAGMENT_CONF}"
  else
    conf_child_tpl="${LIBSCRIPT_ROOT_DIR}"'/'"${NGINX_FRAGMENT_CONF}"
    if [ ! -f "${conf_child_tpl}" ]; then
      >&2 printf 'Template to interpolate for nginx not found: "%s"\n' "${conf_child_tpl}"
      exit 2
    fi
  fi
elif [ ! -z "${WWWROOT+x}" ]; then
  if [ ! -z "${WWWROOT_AUTOINDEX+x}" ]; then
    conf_child_tpl="${LIBSCRIPT_ROOT_DIR}"'/_lib/_server/nginx/conf/simple_location_wwwroot_autoindex.conf'
  else
    conf_child_tpl="${LIBSCRIPT_ROOT_DIR}"'/_lib/_server/nginx/conf/simple_location_wwwroot.conf'
  fi
elif [ ! -z "${PROXY_PASS+x}" ]; then
  if [ ! -z "${PROXY_WEBSOCKETS+x}" ]; then
    conf_child_tpl="${LIBSCRIPT_ROOT_DIR}"'/_lib/_server/nginx/conf/simple_location_proxy_websockets.conf'
  else
    conf_child_tpl="${LIBSCRIPT_ROOT_DIR}"'/_lib/_server/nginx/conf/simple_location_proxy.conf'
  fi
fi

if [ -z "${conf_child_tpl+x}" ]; then
  >&2 printf 'Could not determine which template to interpolate for nginx'
  exit 3
fi

envsubst_safe < "${conf_child_tpl}"
