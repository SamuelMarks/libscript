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
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${DIR}"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"
export LIBSCRIPT_ROOT_DIR
LIBSCRIPT_DATA_DIR="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"
export LIBSCRIPT_DATA_DIR

previous_wd="$(pwd)"
_DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)
export DIR="${_DIR}"
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${DIR}"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"

for lib in '_lib/_common/pkg_mgr.sh' '_lib/_common/priv.sh' '_lib/git-servers/git.sh'; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
# shellcheck disable=SC1090,SC1091,SC2034
  . "${SCRIPT_NAME}"
done

export DIR="${_DIR}"
SCRIPT_NAME="${DIR}"'/env.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091,SC2034
. "${SCRIPT_NAME}"

depends git build-essential libsystemd-dev

target="${VALKEY_BUILD_DIR}"'/valkey'
git_get https://github.com/valkey-io/valkey "${target}"
cd -- "${target}"
hash="$(git rev-list HEAD -1)"

build_install() {
  [ -d 'build' ] || mkdir -p -- 'build'
  touch 'build/'"${hash}"
  make BUILD_TLS='yes' USE_SYSTEMD='yes'
  priv  make install
}

noop=0

if [ -f 'build/'"${hash}" ]; then
  noop=1
elif [ -f './src/rand.o' ]; then
  make distclean
  build_install
else
  build_install
fi


cd -- "${previous_wd}"

if [ "${noop}" -eq 0 ]; then
  service_name="${LIBSCRIPT_SERVICE_NAME:-valkey}"
  valkey_conf="/tmp/valkey_$$.conf"
  cp -- "${LIBSCRIPT_ROOT_DIR}"'/_lib/caches/valkey/conf/valkey.conf' "${valkey_conf}"
  if [ -n "${VALKEY_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET:-}}" ]; then
    sed -i -e "s|^bind |# bind |g" -e "s|^port |port 0\n# port |g" -e "s|^# unixsocket .*|unixsocket ${VALKEY_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET}}\nunixsocketperm 777|" "${valkey_conf}"
  else
    if [ -n "${VALKEY_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS:-}}" ]; then
      sed -i "s|^bind .*|bind ${VALKEY_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS}}|" "${valkey_conf}"
    fi
    if [ -n "${VALKEY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
      sed -i "s|^port .*|port ${VALKEY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}|" "${valkey_conf}"
    fi
  fi
  priv  install -m 0644 -o 'root' -- "${valkey_conf}" /etc/valkey.conf
  rm -f -- "${valkey_conf}"
  priv  install -m 0644 -o 'root' -- "${LIBSCRIPT_ROOT_DIR}"'/_lib/caches/valkey/conf/systemd/'"${service_name}"'.service' /etc/systemd/system/
  priv  systemctl daemon-reload
  priv  systemctl reload-or-restart -- "${service_name}"
fi

[ -d "${LIBSCRIPT_DATA_DIR}" ] || mkdir -p -- "${LIBSCRIPT_DATA_DIR}"
val='redis://localhost'
for key in 'REDIS_URL' 'VALKEY_URL'; do
  lang_export 'cmd' "${key}" "${val}" >> "${LIBSCRIPT_DATA_DIR}"'/dyn_env.cmd'
  lang_export 'sh' "${key}" "${val}" >> "${LIBSCRIPT_DATA_DIR}"'/dyn_env.sh'
  lang_export 'sqlite' "${key}" "${val}"
done

if [ -n "${VALKEY_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET:-}}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "unix:${VALKEY_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET}}" >/dev/null 2>&1 ; then
    true
  fi
elif [ -n "${VALKEY_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS:-}}" ] && [ -n "${VALKEY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "${VALKEY_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS}}:${VALKEY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 ; then
    true
  fi
elif [ -n "${VALKEY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "${VALKEY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 ; then
    true
  fi
fi
