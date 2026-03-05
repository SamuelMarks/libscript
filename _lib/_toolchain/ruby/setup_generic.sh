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

DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)

LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${DIR}"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/pkg_mgr.sh'
export SCRIPT_NAME
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
  libscript_download "https://cache.ruby-lang.org/pub/ruby/${ruby_major}/ruby-${RUBY_VERSION}.tar.gz" /tmp/ruby.tar.gz
  tar -xzf /tmp/ruby.tar.gz -C /tmp
  cd "/tmp/ruby-${RUBY_VERSION}" && ./configure && make && priv make install
fi
