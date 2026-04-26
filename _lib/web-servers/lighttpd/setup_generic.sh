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

for lib in '_lib/_common/pkg_mgr.sh' ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

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
