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
DIR=$(CDPATH='' cd -- "$(dirname -- "${THIS_FILE}")" && pwd)

LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(D="${DIR}"; while [ ! -f "${D}"'/ROOT' ]; do D="$(dirname -- "${D}")"; done; printf '%s' "${D}")}"

for LIB in '_lib/_common/pkg_mgr.sh' ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

RUBY_INSTALL_METHOD="${RUBY_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-system}}"
RUBY_VERSION="${RUBY_VERSION:-latest}"
if [ "${RUBY_VERSION}" = "latest" ] || [ "${RUBY_VERSION}" = "stable" ]; then
  RUBY_INDEX=$(mktemp)
  libscript_download 'https://cache.ruby-lang.org/pub/ruby/index.txt' "${RUBY_INDEX}"
  RUBY_VERSION=$(awk '{print $1}' < "${RUBY_INDEX}" | grep -E '^ruby-[0-9]+\.[0-9]+\.[0-9]+$' | tail -n 1 | sed 's/^ruby-//')
  rm -f "${RUBY_INDEX}"
fi
if [ -z "${RUBY_VERSION}" ]; then
  RUBY_VERSION="3.3.0"
fi
RUBY_MAJOR=$(echo "${RUBY_VERSION}" | cut -d. -f1,2)

if [ "${RUBY_INSTALL_METHOD}" = 'system' ]; then
  libscript_depends 'ruby'
else
  libscript_depends 'curl' 'tar' 'make' 'gcc'
  RUBY_TARBALL=$(mktemp)
  libscript_download "https://cache.ruby-lang.org/pub/ruby/${RUBY_MAJOR}/ruby-${RUBY_VERSION}.tar.gz" "${RUBY_TARBALL}"
  tar -xzf "${RUBY_TARBALL}" -C /tmp
  rm -f "${RUBY_TARBALL}"
  cd "/tmp/ruby-${RUBY_VERSION}" && ./configure && make && priv make install
fi
