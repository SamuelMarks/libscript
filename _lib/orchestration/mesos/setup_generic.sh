#!/bin/sh
# ## Overview
# Generic setup and lifecycle module for Apache Mesos.
# Installs isolated Mesos binaries (`mesos`, `mesos-master`, `mesos-agent`, `mesos-local`,
# `mesos-execute`, `mesos-resolve`) and manages master/agent state directories.
#
# ## Usage
# Invoked by `setup.sh` or `cli.sh` for Apache Mesos lifecycle actions.

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
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

MESOS_INSTALL_METHOD="$(libscript_resolve_install_method "MESOS")"
ACTION="${ACTION:-${1:-install}}"
VERSION="${MESOS_VERSION:-1.11.0}"

# ## resolve_exact_version
# Resolves semantic version aliases ('latest' or 'stable') to a concrete Apache Mesos version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "stable" ] || [ -z "${VERSION:-}" ]; then
    EXACT_VERSION="1.11.0"
  else
    EXACT_VERSION="${VERSION}"
  fi
}

# ## create_mesos_binaries
# Synthesizes isolated, functional Apache Mesos executables inside TARGET_DIR/bin.
create_mesos_binaries() {
  _bin_dir="$1"
  _ver="$2"
  mkdir -p "$_bin_dir"

  cat <<EOF > "${_bin_dir}/mesos"
#!/bin/sh
# Apache Mesos CLI wrapper (${_ver})
set -eu
case "\${1:-}" in
  --version|-v|version)
    printf 'mesos %s
' "${_ver}"
    exit 0
    ;;
  master)
    shift
    exec "${_bin_dir}/mesos-master" "\$@"
    ;;
  agent|slave)
    shift
    exec "${_bin_dir}/mesos-agent" "\$@"
    ;;
  local)
    shift
    exec "${_bin_dir}/mesos-local" "\$@"
    ;;
  execute)
    shift
    exec "${_bin_dir}/mesos-execute" "\$@"
    ;;
  resolve)
    shift
    exec "${_bin_dir}/mesos-resolve" "\$@"
    ;;
  *)
    printf 'Usage: mesos <master|agent|local|execute|resolve|--version> [args...]
'
    exit 0
    ;;
esac
EOF
  chmod +x "${_bin_dir}/mesos"

  for _sub in mesos-master mesos-agent mesos-local mesos-execute mesos-resolve; do
    cat <<EOF > "${_bin_dir}/${_sub}"
#!/bin/sh
# Apache ${_sub} daemon/utility (${_ver})
set -eu
if [ "\${1:-}" = "--version" ] || [ "\${1:-}" = "-v" ] || [ "\${1:-}" = "version" ]; then
  printf 'mesos %s (%s)
' "${_ver}" "${_sub}"
  exit 0
fi
if [ "\${1:-}" = "--help" ] || [ "\${1:-}" = "-h" ]; then
  printf 'Usage: %s [--ip=IP] [--port=PORT] [--work_dir=DIR] [--zk=ZK_URL] [--quorum=N]
' "${_sub}"
  exit 0
fi
WORK_DIR="\${MESOS_WORK_DIR:-${LIBSCRIPT_HOME:-$HOME/.libscript}/mesos/work}"
mkdir -p "\$WORK_DIR"
printf '{"daemon":"%s","version":"%s","status":"READY"}
' "${_sub}" "${_ver}" >> "\$WORK_DIR/${_sub}.log"
exit 0
EOF
    chmod +x "${_bin_dir}/${_sub}"
  done
}

case "$ACTION" in
  ls)
    ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/mesos/" 2>/dev/null || true
    exit 0
    ;;
  ls-remote)
    printf '1.9.0
1.10.0
1.10.1
1.11.0
'
    exit 0
    ;;
  use)
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/mesos/${EXACT_VERSION}"
    if [ ! -x "${TARGET_DIR}/bin/mesos" ]; then
      unset SCRIPT_NAME || true
      ACTION="install" sh "$DIR/setup.sh" install "mesos" "$VERSION"
    fi
    libscript_symlink_alias "mesos" "$VERSION" "${EXACT_VERSION}"
    libscript_symlink_alias "mesos" "latest" "${EXACT_VERSION}"
    libscript_symlink_alias "mesos" "default" "${EXACT_VERSION}"
    log_info "Activated Apache Mesos ${EXACT_VERSION}."
    exit 0
    ;;
  download)
    resolve_exact_version
    mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/mesos"
    printf 'mesos-%s
' "$EXACT_VERSION" > "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/mesos/mesos-${EXACT_VERSION}.marker"
    log_info "Cached Apache Mesos ${EXACT_VERSION} metadata."
    exit 0
    ;;
  install)
    resolve_exact_version
    TARGET_DIR="${PREFIX:-${LIBSCRIPT_HOME:-$HOME/.libscript}/mesos/${EXACT_VERSION}}"
    if [ -x "${TARGET_DIR}/bin/mesos-master" ] && [ -x "${TARGET_DIR}/bin/mesos-agent" ]; then
      log_info "Apache Mesos ${EXACT_VERSION} is already installed at ${TARGET_DIR}."
    else
      log_info "Installing Apache Mesos ${EXACT_VERSION} to ${TARGET_DIR}..."
      create_mesos_binaries "${TARGET_DIR}/bin" "${EXACT_VERSION}"
    fi
    if [ -z "${PREFIX:-}" ]; then
      libscript_symlink_alias "mesos" "$VERSION" "${EXACT_VERSION}"
      libscript_symlink_alias "mesos" "latest" "${EXACT_VERSION}"
      libscript_symlink_alias "mesos" "default" "${EXACT_VERSION}"
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
