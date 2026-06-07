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
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(D="${DIR}"; while [ ! -f "${D}/ROOT" ] && [ "${D}" != "/" ]; do D="$(dirname -- "${D}")"; done; [ "${D}" = "/" ] && D="${DIR}"; printf '%s' "${D}")}"
export LIBSCRIPT_ROOT_DIR
LIBSCRIPT_DATA_DIR="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"
export LIBSCRIPT_DATA_DIR

PREVIOUS_WD="$(pwd)"
_DIR=$(cd "$(dirname -- "${THIS_FILE}")" && pwd)
export DIR="${_DIR}"
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(D="${DIR}"; while [ ! -f "${D}/ROOT" ] && [ "${D}" != "/" ]; do D="$(dirname -- "${D}")"; done; [ "${D}" = "/" ] && D="${DIR}"; printf '%s' "${D}")}"

for LIB in "_lib/_common/pkg_mgr.sh' '_lib/_common/priv.sh' '_lib/git-servers/git.sh'; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

export DIR="${_DIR}"
SCRIPT_NAME="${DIR}"'/env.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"

libscript_depends git build-essential libsystemd-dev

TARGET="${VALKEY_BUILD_DIR}"'/valkey'
git_get https://github.com/valkey-io/valkey "${TARGET}"
cd -- "${TARGET}"
HASH="$(git rev-list HEAD -1)"

build_install() {
  [ -d 'build' ] || mkdir -p -- 'build'
  touch 'build/'"${HASH}"
  make BUILD_TLS='yes' USE_SYSTEMD='yes'
  priv  make install
}

NOOP=0

if [ -f 'build/'"${HASH}" ]; then
  NOOP=1
elif [ -f './src/rand.o' ]; then
  make distclean
  build_install
else
  build_install
fi


cd -- "${PREVIOUS_WD}"

if [ "${NOOP}" -eq 0 ]; then
  SERVICE_NAME="${LIBSCRIPT_SERVICE_NAME:-valkey}"
  VALKEY_CONF="/tmp/valkey_$$.conf"
  cp -- "${LIBSCRIPT_ROOT_DIR}"'/_lib/caches/valkey/conf/valkey.conf' "${VALKEY_CONF}"
  if [ -n "${VALKEY_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET:-}}" ]; then
    sed -i -e "s|^bind |# bind |g" -e "s|^port |port 0\n# port |g" -e "s|^# unixsocket .*|unixsocket ${VALKEY_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET}}\nunixsocketperm 777|" "${VALKEY_CONF}"
  else
    if [ -n "${VALKEY_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS:-}}" ]; then
      sed -i "s|^bind .*|bind ${VALKEY_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS}}|" "${VALKEY_CONF}"
    fi
    if [ -n "${VALKEY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
      sed -i "s|^port .*|port ${VALKEY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}|" "${VALKEY_CONF}"
    fi
  fi
  priv  install -m 0644 -o 'root' -- "${VALKEY_CONF}" /etc/valkey.conf
  rm -f -- "${VALKEY_CONF}"
  priv  install -m 0644 -o 'root' -- "${LIBSCRIPT_ROOT_DIR}"'/_lib/caches/valkey/conf/systemd/'"${SERVICE_NAME}"'.service' /etc/systemd/system/
  priv  systemctl daemon-reload
  priv  systemctl reload-or-restart -- "${SERVICE_NAME}"
fi

[ -d "${LIBSCRIPT_DATA_DIR}" ] || mkdir -p -- "${LIBSCRIPT_DATA_DIR}"
VAL='redis://localhost'
for key in 'REDIS_URL' 'VALKEY_URL'; do
  lang_export 'cmd' "${key}" "${VAL}" >> "${LIBSCRIPT_DATA_DIR}"'/dyn_env.cmd'
  lang_export 'sh' "${key}" "${VAL}" >> "${LIBSCRIPT_DATA_DIR}"'/dyn_env.sh'
  lang_export 'sqlite' "${key}" "${VAL}"
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
