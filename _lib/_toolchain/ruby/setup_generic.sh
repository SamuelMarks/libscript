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

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/pkg_mgr.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

RUBY_INSTALL_METHOD="${RUBY_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-system}}"
RUBY_VERSION="${RUBY_VERSION:-latest}"
if [ "${RUBY_VERSION}" = "latest" ] || [ "${RUBY_VERSION}" = "stable" ]; then
  RUBY_VERSION=$(curl -sL https://cache.ruby-lang.org/pub/ruby/index.txt | awk '{print $1}' | grep -E '^ruby-[0-9]+\.[0-9]+\.[0-9]+$' | tail -n 1 | sed 's/^ruby-//')
fi
if [ -z "${RUBY_VERSION}" ]; then
  RUBY_VERSION="3.3.0"
fi
ruby_major=$(echo "${RUBY_VERSION}" | cut -d. -f1,2)

if [ "${RUBY_INSTALL_METHOD}" = 'system' ]; then
  depends 'ruby'
else
  depends 'curl' 'tar' 'make' 'gcc'
  curl -L -o /tmp/ruby.tar.gz "https://cache.ruby-lang.org/pub/ruby/${ruby_major}/ruby-${RUBY_VERSION}.tar.gz"
  tar -xzf /tmp/ruby.tar.gz -C /tmp
  cd "/tmp/ruby-${RUBY_VERSION}" && ./configure && make && priv make install
fi
