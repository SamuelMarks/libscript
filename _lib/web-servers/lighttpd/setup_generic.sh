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

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/pkg_mgr.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091,SC2034
. "${SCRIPT_NAME}"

LIGHTTPD_INSTALL_METHOD="${LIGHTTPD_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-system}}"

if [ "${LIGHTTPD_INSTALL_METHOD}" = 'system' ]; then
  depends 'lighttpd'
else
  echo "[WARN] From-source or alternative installation requested for lighttpd, but currently only system package manager is fully supported."
  depends 'lighttpd'
fi

CONF_DIR="${LIBSCRIPT_DATA_DIR}/lighttpd"
mkdir -p "${CONF_DIR}"
if [ ! -f "${CONF_DIR}/lighttpd.conf" ]; then
  cat <<EOF > "${CONF_DIR}/lighttpd.conf"
server.port = ${LIGHTTPD_LISTEN_PORT:-8080}
server.bind = "${LIGHTTPD_LISTEN_ADDRESS:-127.0.0.1}"
server.document-root = "${LIBSCRIPT_ROOT_DIR}/www"
server.errorlog = "${CONF_DIR}/error.log"
server.modules = (
  "mod_access",
  "mod_accesslog"
)
accesslog.filename = "${CONF_DIR}/access.log"
EOF
fi
