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
