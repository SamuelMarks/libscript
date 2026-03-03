#!/bin/sh
set -feu
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
else
  this_file="${0}"
fi
DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${DIR}"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/pkg_mgr.sh'
export SCRIPT_NAME
. "${SCRIPT_NAME}"

SCRIPT_NAME="${DIR}"'/env.sh'
export SCRIPT_NAME
. "${SCRIPT_NAME}"

if ! depends 'postgresql'; then
    >&2 printf "PostgreSQL package not available, failing...
"
    exit 1
fi

case "${INIT_SYS-}" in
  'systemd')
    systemctl enable "${LIBSCRIPT_SERVICE_NAME:-postgresql}" || true
    systemctl start "${LIBSCRIPT_SERVICE_NAME:-postgresql}" || true
    ;;
  'openrc')
    rc-update add "${LIBSCRIPT_SERVICE_NAME:-postgresql}" || true
    rc-service "${LIBSCRIPT_SERVICE_NAME:-postgresql}" start || true
    ;;
  *)
    >&2 printf 'Warning: Postgres installation successful, but init system %s not supported for auto-start
' "${INIT_SYS-}"
    ;;
esac
