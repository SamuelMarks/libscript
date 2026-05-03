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
export ETCD_URL="${ETCD_URL:-1}"
export ETCD_VERSION="${ETCD_VERSION:-v3.5.21}"
if [ "${ETCD_PASSWORD_FILE-}" ] && [ -f "${ETCD_PASSWORD_FILE}" ]; then
  pass_contents="$(cat -- "${ETCD_PASSWORD_FILE}"; printf 'a')"
  pass_contents="${pass_contents%a}"
  # TODO(security): Audit
  export ETCD_PASSWORD="${pass_contents}"
fi
export ETCD_SERVICE_USER="${ETCD_SERVICE_USER:-etcd}"
export ETCD_SERVICE_GROUP="${ETCD_SERVICE_GROUP:-${ETCD_SERVICE_USER}}"
