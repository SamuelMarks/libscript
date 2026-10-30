#!/bin/sh
# ## Overview
# Provides specialized installation logic for Valkey on Debian/Ubuntu systems.
# It handles reusing an existing Valkey/Redis server, installing via apt or compiling
# from source with TLS and Systemd support, ensuring the daemon is running, and
# setting connection string environment exports.
# 
# ## Usage
# Typically called automatically by `setup.sh` when running on a Debian-like operating system.

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR
LIBSCRIPT_DATA_DIR="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"
export LIBSCRIPT_DATA_DIR

PREVIOUS_WD="$(pwd)"
_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
export DIR="${_DIR}"

for LIB in "_lib/_common/log.sh" "_lib/_common/pkg_mgr.sh" "_lib/_common/priv.sh" "_lib/_common/environ.sh" "_lib/_common/settings_updater.sh" "_lib/git-servers/utils/git.sh"; do
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

# ## _valkey_debian_is_active
# Checks whether a Valkey or Redis server is already accepting connections on the target port.
_valkey_debian_is_active() {
  _vk_port="${VALKEY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-6379}}"
  for _vk_cli in valkey-cli redis-cli; do
    if command -v "$_vk_cli" >/dev/null 2>&1; then
      _vk_pong=$("$_vk_cli" -h 127.0.0.1 -p "$_vk_port" ping 2>/dev/null || true)
      if [ "$_vk_pong" = "PONG" ]; then
        return 0
      fi
    fi
  done
  return 1
}

# ## _valkey_debian_ensure_started
# Ensures an installed Valkey or Redis service is enabled and running under systemd or init.d.
_valkey_debian_ensure_started() {
  if _valkey_debian_is_active; then
    return 0
  fi
  if [ "$(ps -q 1 -o comm= 2>/dev/null || true)" = 'systemd' ] && command -v systemctl >/dev/null 2>&1; then
    for _vk_svc in "${LIBSCRIPT_SERVICE_NAME:-}" valkey-server valkey redis-server redis; do
      [ -n "$_vk_svc" ] || continue
      if [ -f "/lib/systemd/system/${_vk_svc}.service" ] || [ -f "/etc/systemd/system/${_vk_svc}.service" ]; then
        priv systemctl enable "$_vk_svc" >/dev/null 2>&1 || true
        priv systemctl start "$_vk_svc" >/dev/null 2>&1 || true
        if _valkey_debian_is_active; then
          return 0
        fi
      fi
    done
  fi
  if command -v service >/dev/null 2>&1; then
    for _vk_svc in "${LIBSCRIPT_SERVICE_NAME:-}" valkey-server valkey redis-server redis; do
      [ -n "$_vk_svc" ] || continue
      if [ -x "/etc/init.d/${_vk_svc}" ]; then
        priv service "$_vk_svc" start >/dev/null 2>&1 || true
        if _valkey_debian_is_active; then
          return 0
        fi
      fi
    done
  fi
  return 0
}

# ## build_install
# Performs the build_install operation from source and updates component state.
build_install() {
  [ -d 'build' ] || mkdir -p -- 'build'
  touch 'build/'"${HASH}"
  make BUILD_TLS='yes' USE_SYSTEMD='yes'
  priv make install
}

if [ "${FORCE_REINSTALL:-0}" != "1" ] && _valkey_debian_is_active; then
  log_info "[REUSE] Valkey/Redis server already active on port ${VALKEY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-6379}}."
  _valkey_debian_ensure_started
  NOOP=1
else
  NOOP=0
  if [ "${FORCE_REINSTALL:-0}" != "1" ] && { command -v valkey-server >/dev/null 2>&1 || command -v redis-server >/dev/null 2>&1; }; then
    _valkey_debian_ensure_started
    log_info '[REUSE] Valkey/Redis binary already installed.'
    NOOP=1
  elif [ "${VALKEY_BUILD_FROM_SOURCE:-0}" = "1" ]; then
    libscript_depends git build-essential libsystemd-dev libssl-dev pkg-config
    TARGET="${VALKEY_BUILD_DIR}"'/valkey'
    git_get https://github.com/valkey-io/valkey "${TARGET}"
    cd -- "${TARGET}"
    HASH="$(git rev-list HEAD -1)"
    if [ -f 'build/'"${HASH}" ]; then
      NOOP=1
    elif [ -f './src/rand.o' ]; then
      make distclean
      build_install
    else
      build_install
    fi
    cd -- "${PREVIOUS_WD}"
  else
    if libscript_depends valkey >/dev/null 2>&1; then
      _valkey_debian_ensure_started
      NOOP=1
    elif libscript_depends valkey-server >/dev/null 2>&1; then
      _valkey_debian_ensure_started
      NOOP=1
    elif libscript_depends redis-server >/dev/null 2>&1; then
      _valkey_debian_ensure_started
      NOOP=1
    else
      libscript_depends git build-essential libsystemd-dev libssl-dev pkg-config
      TARGET="${VALKEY_BUILD_DIR}"'/valkey'
      git_get https://github.com/valkey-io/valkey "${TARGET}"
      cd -- "${TARGET}"
      HASH="$(git rev-list HEAD -1)"
      build_install
      cd -- "${PREVIOUS_WD}"
    fi
  fi
fi

if [ "${NOOP}" -eq 0 ]; then
  SERVICE_NAME="${LIBSCRIPT_SERVICE_NAME:-valkey}"
  VALKEY_CONF="/tmp/valkey_$$.conf"
  cp -- "${LIBSCRIPT_ROOT_DIR}"'/_lib/caches/valkey/conf/valkey.conf' "${VALKEY_CONF}"
  if [ -n "${VALKEY_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET:-}}" ]; then
    grep -q "^port 0" "${VALKEY_CONF}" || {
      sed "s|^port |port 0\n# port |g" "${VALKEY_CONF}" > "${VALKEY_CONF}.tmp" && mv "${VALKEY_CONF}.tmp" "${VALKEY_CONF}"
    }
    sed -e "s|^bind |# bind |g" -e "s|^# unixsocket .*|unixsocket ${VALKEY_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET}}\nunixsocketperm 777|" "${VALKEY_CONF}" > "${VALKEY_CONF}.tmp" && mv "${VALKEY_CONF}.tmp" "${VALKEY_CONF}"
  else
    if [ -n "${VALKEY_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS:-}}" ]; then
      sed "s|^bind .*|bind ${VALKEY_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS}}|" "${VALKEY_CONF}" > "${VALKEY_CONF}.tmp" && mv "${VALKEY_CONF}.tmp" "${VALKEY_CONF}"
    fi
    if [ -n "${VALKEY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
      sed "s|^port .*|port ${VALKEY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}|" "${VALKEY_CONF}" > "${VALKEY_CONF}.tmp" && mv "${VALKEY_CONF}.tmp" "${VALKEY_CONF}"
    fi
  fi
  priv install -m 0644 -o 'root' -- "${VALKEY_CONF}" /etc/valkey.conf
  rm -f -- "${VALKEY_CONF}"
  priv install -m 0644 -o 'root' -- "${LIBSCRIPT_ROOT_DIR}"'/_lib/caches/valkey/conf/systemd/'"${SERVICE_NAME}"'.service' /etc/systemd/system/
  priv systemctl daemon-reload
  priv systemctl reload-or-restart -- "${SERVICE_NAME}"
fi

[ -d "${LIBSCRIPT_DATA_DIR}" ] || mkdir -p -- "${LIBSCRIPT_DATA_DIR}"
VAL='redis://localhost'
for key in 'REDIS_URL' 'VALKEY_URL'; do
  if [ -f "${LIBSCRIPT_DATA_DIR}/dyn_env.cmd" ]; then
    tmp_env=$(mktemp)
    grep -v "^SET \"${key}=" "${LIBSCRIPT_DATA_DIR}/dyn_env.cmd" > "$tmp_env" || true
    mv "$tmp_env" "${LIBSCRIPT_DATA_DIR}/dyn_env.cmd"
  fi
  if [ -f "${LIBSCRIPT_DATA_DIR}/dyn_env.sh" ]; then
    tmp_env=$(mktemp)
    grep -v "^export ${key}=" "${LIBSCRIPT_DATA_DIR}/dyn_env.sh" > "$tmp_env" || true
    mv "$tmp_env" "${LIBSCRIPT_DATA_DIR}/dyn_env.sh"
  fi
  lang_export 'cmd' "${key}" "${VAL}" >> "${LIBSCRIPT_DATA_DIR}"'/dyn_env.cmd'
  lang_export 'sh' "${key}" "${VAL}" >> "${LIBSCRIPT_DATA_DIR}"'/dyn_env.sh'
  lang_export 'sqlite' "${key}" "${VAL}"
done

if [ -n "${VALKEY_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET:-}}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/_lib/networking/netctl/cli.sh" --listen "unix:${VALKEY_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET}}" >/dev/null 2>&1 ; then
    true
  fi
elif [ -n "${VALKEY_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS:-}}" ] && [ -n "${VALKEY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/_lib/networking/netctl/cli.sh" --listen "${VALKEY_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS}}:${VALKEY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 ; then
    true
  fi
elif [ -n "${VALKEY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/_lib/networking/netctl/cli.sh" --listen "${VALKEY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 ; then
    true
  fi
fi
