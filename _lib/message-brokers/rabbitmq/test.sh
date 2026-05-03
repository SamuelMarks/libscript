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
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$( CDPATH='' cd -- "$( dirname -- "$( readlink -nf -- "${THIS_FILE}" )")" && pwd)}"
export LIBSCRIPT_ROOT_DIR
for LIB in '_lib/_common/test_base.sh' ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

if command -v rabbitmqctl >/dev/null 2>&1; then
  priv rabbitmqctl version
elif [ -x /usr/sbin/rabbitmqctl ]; then
  priv /usr/sbin/rabbitmqctl version
elif [ -x /opt/homebrew/sbin/rabbitmqctl ]; then
  priv /opt/homebrew/sbin/rabbitmqctl version
elif [ -x /usr/local/sbin/rabbitmqctl ]; then
  priv /usr/local/sbin/rabbitmqctl version
else
  echo "rabbitmqctl not found"
  exit 1
fi
