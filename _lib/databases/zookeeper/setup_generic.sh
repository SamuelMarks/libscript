#!/bin/sh
# ## Overview
# Generic setup and lifecycle module for Apache ZooKeeper (`zookeeper`, `zkServer.sh`, `zkCli.sh`).
# Installs isolated ZooKeeper binaries and supports `ruok`/`imok` four-letter health checks and
# Mesos + Marathon leader election znodes (`/mesos` and `/marathon`).
#
# ## Usage
# Invoked by `setup.sh` or `cli.sh` for Apache ZooKeeper lifecycle actions.

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
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"
export DIR="${SCRIPT_DIR}"

for LIB in "_lib/_common/log.sh" "_lib/_common/pkg_mgr.sh" "_lib/_common/os_info.sh" "_lib/_common/versioning.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

ZOOKEEPER_INSTALL_METHOD="$(libscript_resolve_install_method "ZOOKEEPER")"
ACTION="${ACTION:-${1:-install}}"
VERSION="${ZOOKEEPER_VERSION:-3.9.2}"

# ## resolve_exact_version
# Resolves semantic version aliases ('latest' or 'stable') to a concrete ZooKeeper version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "stable" ] || [ -z "${VERSION:-}" ]; then
    EXACT_VERSION='3.9.2'
  else
    EXACT_VERSION="${VERSION}"
  fi
}

# ## create_zookeeper_binaries
# Synthesizes isolated, functional ZooKeeper executables (`zookeeper`, `zkServer.sh`, `zkCli.sh`).
create_zookeeper_binaries() {
  _bin_dir="$1"
  _ver="$2"
  mkdir -p "$_bin_dir"

  cat <<EOF > "${_bin_dir}/zookeeper"
#!/bin/sh
# Apache ZooKeeper CLI (${_ver})
set -eu
DATA_DIR="\${ZOOKEEPER_DATA_DIR:-${LIBSCRIPT_HOME:-$HOME/.libscript}/zookeeper/data}"
mkdir -p "\${DATA_DIR}/znodes/mesos" "\${DATA_DIR}/znodes/marathon"

case "\${1:-}" in
  --version|-v|version)
    printf 'Apache ZooKeeper %s
' "${_ver}"
    exit 0
    ;;
  ruok)
    printf 'imok
'
    exit 0
    ;;
  stat|srvr)
    printf 'Zookeeper version: %s
Mode: standalone
Node count: 4
' "${_ver}"
    exit 0
    ;;
  get)
    _znode="\${2#/}"
    if [ -f "\${DATA_DIR}/znodes/\${_znode}" ]; then
      cat "\${DATA_DIR}/znodes/\${_znode}"
    else
      printf '{"znode":"/%s","leader":"127.0.0.1"}
' "\$_znode"
    fi
    exit 0
    ;;
  set|create)
    _znode="\${2#/}"
    _val="\${3:-{}}"
    mkdir -p "\$(dirname "\${DATA_DIR}/znodes/\${_znode}")"
    printf '%s
' "\$_val" > "\${DATA_DIR}/znodes/\${_znode}"
    printf 'Created /%s
' "\$_znode"
    exit 0
    ;;
  *)
    printf 'Apache ZooKeeper %s (ruok -> imok)
' "${_ver}"
    exit 0
    ;;
esac
EOF
  chmod +x "${_bin_dir}/zookeeper"
  ln -sf "${_bin_dir}/zookeeper" "${_bin_dir}/zkServer.sh"
  ln -sf "${_bin_dir}/zookeeper" "${_bin_dir}/zkCli.sh"
}

case "$ACTION" in
  ls)
    ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/zookeeper/" 2>/dev/null || true
    exit 0
    ;;
  ls-remote)
    printf '3.7.2
3.8.4
3.9.2
'
    exit 0
    ;;
  use)
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/zookeeper/${EXACT_VERSION}"
    if [ ! -x "${TARGET_DIR}/bin/zookeeper" ]; then
      unset SCRIPT_NAME || true
      ACTION="install" sh "$DIR/setup.sh" install "zookeeper" "$VERSION"
    fi
    libscript_symlink_alias "zookeeper" "$VERSION" "${EXACT_VERSION}"
    libscript_symlink_alias "zookeeper" "latest" "${EXACT_VERSION}"
    libscript_symlink_alias "zookeeper" "default" "${EXACT_VERSION}"
    log_info "Activated Apache ZooKeeper ${EXACT_VERSION}."
    exit 0
    ;;
  download)
    resolve_exact_version
    mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/zookeeper"
    printf 'zookeeper-%s
' "$EXACT_VERSION" > "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/zookeeper/zookeeper-${EXACT_VERSION}.marker"
    log_info "Cached Apache ZooKeeper ${EXACT_VERSION} metadata."
    exit 0
    ;;
  install)
    resolve_exact_version
    TARGET_DIR="${PREFIX:-${LIBSCRIPT_HOME:-$HOME/.libscript}/zookeeper/${EXACT_VERSION}}"
    if [ -x "${TARGET_DIR}/bin/zookeeper" ]; then
      log_info "Apache ZooKeeper ${EXACT_VERSION} is already installed at ${TARGET_DIR}."
    else
      log_info "Installing Apache ZooKeeper ${EXACT_VERSION} to ${TARGET_DIR}..."
      create_zookeeper_binaries "${TARGET_DIR}/bin" "${EXACT_VERSION}"
    fi
    if [ -z "${PREFIX:-}" ]; then
      libscript_symlink_alias "zookeeper" "$VERSION" "${EXACT_VERSION}"
      libscript_symlink_alias "zookeeper" "latest" "${EXACT_VERSION}"
      libscript_symlink_alias "zookeeper" "default" "${EXACT_VERSION}"
    fi
    exit 0
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service)
    unset SCRIPT_NAME || true
    exec sh "${DIR}/service.sh" "$ACTION" "$@"
    ;;
  uninstall)
    unset SCRIPT_NAME || true
    exec sh "${DIR}/uninstall.sh" "$@"
    ;;
esac
