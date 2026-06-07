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

for LIB in _lib/_common/pkg_mgr.sh ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

LIGHTTPD_INSTALL_METHOD="${LIGHTTPD_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-system}}"

if [ "${LIGHTTPD_INSTALL_METHOD}" = 'system' ]; then
  libscript_depends 'lighttpd'
else
  log_info "[WARN] From-source or alternative installation requested for lighttpd, but currently only system package manager is fully supported."
  libscript_depends 'lighttpd'
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
