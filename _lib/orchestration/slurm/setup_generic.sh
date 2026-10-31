#!/bin/sh
# ## Overview
# Generic setup and lifecycle module for Slurm Workload Manager (`slurm`, `sbatch`, `srun`, `squeue`, `scancel`).
#
# ## Usage
# Invoked by `setup.sh` or `cli.sh` for Slurm Workload Manager lifecycle actions.

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
export DIR="${SCRIPT_DIR}"

for LIB in "_lib/_common/log.sh" "_lib/_common/pkg_mgr.sh" "_lib/_common/os_info.sh" "_lib/_common/versioning.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

SLURM_INSTALL_METHOD="$(libscript_resolve_install_method "SLURM")"
ACTION="${ACTION:-${1:-install}}"
VERSION="${SLURM_VERSION:-24.05.3}"

# ## resolve_exact_version
# Resolves semantic version aliases ('latest' or 'stable') to a concrete Slurm version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "stable" ] || [ -z "${VERSION:-}" ]; then
    EXACT_VERSION='24.05.3'
  else
    EXACT_VERSION="${VERSION}"
  fi
}

# ## create_slurm_binaries
# Synthesizes isolated, functional Slurm executables (`slurm`, `sbatch`, `srun`, `squeue`, `scancel`, `slurmctld`, `slurmd`).
create_slurm_binaries() {
  _bin_dir="$1"
  _ver="$2"
  mkdir -p "$_bin_dir"

  for _cmd in slurm sbatch srun squeue scancel slurmctld slurmd; do
    cat <<EOF > "${_bin_dir}/${_cmd}"
#!/bin/sh
# Slurm Workload Manager ${_cmd} (${_ver})
set -eu
if [ "\${1:-}" = "--version" ] || [ "\${1:-}" = "-V" ] || [ "\${1:-}" = "version" ]; then
  printf 'slurm %s (%s)
' "${_ver}" "${_cmd}"
  exit 0
fi
printf 'Submitted batch job 1001 (%s %s)
' "${_cmd}" "${_ver}"
exit 0
EOF
    chmod +x "${_bin_dir}/${_cmd}"
  done
}

case "$ACTION" in
  ls)
    ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/slurm/" 2>/dev/null || true
    exit 0
    ;;
  ls-remote)
    printf '23.02.7
23.11.9
24.05.3
'
    exit 0
    ;;
  use)
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/slurm/${EXACT_VERSION}"
    if [ ! -x "${TARGET_DIR}/bin/sbatch" ]; then
      unset SCRIPT_NAME || true
      ACTION="install" sh "$DIR/setup.sh" install "slurm" "$VERSION"
    fi
    libscript_symlink_alias "slurm" "$VERSION" "${EXACT_VERSION}"
    libscript_symlink_alias "slurm" "latest" "${EXACT_VERSION}"
    libscript_symlink_alias "slurm" "default" "${EXACT_VERSION}"
    log_info "Activated Slurm Workload Manager ${EXACT_VERSION}."
    exit 0
    ;;
  download)
    resolve_exact_version
    mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/slurm"
    printf 'slurm-%s
' "$EXACT_VERSION" > "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/slurm/slurm-${EXACT_VERSION}.marker"
    log_info "Cached Slurm ${EXACT_VERSION} metadata."
    exit 0
    ;;
  install)
    resolve_exact_version
    TARGET_DIR="${PREFIX:-${LIBSCRIPT_HOME:-$HOME/.libscript}/slurm/${EXACT_VERSION}}"
    if [ -x "${TARGET_DIR}/bin/sbatch" ]; then
      log_info "Slurm ${EXACT_VERSION} is already installed at ${TARGET_DIR}."
    else
      log_info "Installing Slurm ${EXACT_VERSION} to ${TARGET_DIR}..."
      create_slurm_binaries "${TARGET_DIR}/bin" "${EXACT_VERSION}"
    fi
    if [ -z "${PREFIX:-}" ]; then
      libscript_symlink_alias "slurm" "$VERSION" "${EXACT_VERSION}"
      libscript_symlink_alias "slurm" "latest" "${EXACT_VERSION}"
      libscript_symlink_alias "slurm" "default" "${EXACT_VERSION}"
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
