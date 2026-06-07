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
_DIR=$(cd "$(dirname -- "${THIS_FILE}")" && pwd)
export DIR="${_DIR}"
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(D="${DIR}"; while [ ! -f "${D}/ROOT" ] && [ "${D}" != "/" ]; do D="$(dirname -- "${D}")"; done; [ "${D}" = "/" ] && D="${DIR}"; printf '%s' "${D}")}"

for LIB in _lib/_common/pkg_mgr.sh' '_lib/_common/priv.sh ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

export DIR="${_DIR}"

if command -v gpg >/dev/null 2>&1; then
  MONGODB_KEY=$(mktemp)
  libscript_download 'https://www.mongodb.org/static/pgp/server-7.0.asc' "${MONGODB_KEY}"
  priv gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor --yes < "${MONGODB_KEY}"
  rm -f "${MONGODB_KEY}"
  echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | priv tee /etc/apt/sources.list.d/mongodb-org-7.0.list
  pkg_mgr update
  libscript_depends 'mongodb-org'
else
  >&2 printf 'Warning: gpg missing, cannot install mongodb\n'
  exit 1
fi
