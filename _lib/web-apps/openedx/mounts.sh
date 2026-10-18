#!/bin/sh
# ## Overview
# Host directory bind-mount manager for Open edX (Tutor `mounts` parity).
# Allows linking local host directories (e.g., openedx-platform, XBlocks, MFEs, themes)
# into the Docker-free Open edX installation environment.
#
# ## Usage
#   ./mounts.sh add <mount_spec>
#   ./mounts.sh remove <mount_spec>
#   ./mounts.sh list
#   ./mounts.sh clear
#   ./mounts.sh help

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

if [ -f "${LIBSCRIPT_ROOT_DIR}/env.sh" ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/env.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
fi

for LIB in "_lib/_common/log.sh" ${_LIBSCRIPT_DUMMY_NO_RUN:-}; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR:-${LIBSCRIPT_HOME:-$HOME/.libscript}/openedx}"
MOUNTS_DIR="${OPENEDX_INSTALL_DIR}/mounts"
MOUNTS_FILE="${OPENEDX_INSTALL_DIR}/config/mounts.txt"

# ## mounts_add
# Registers and links a local host directory into the Open edX runtime environment.
#
# Inputs:
#   $1 - Mount specification (/path/to/dir or service:/host/path:/target/path)
mounts_add() {
  _spec="${1:-}"
  if [ -z "${_spec}" ]; then
    log_err "Mount specification is required (e.g., /path/to/openedx-platform)."
    exit 1
  fi

  mkdir -p "${MOUNTS_DIR}" "${OPENEDX_INSTALL_DIR}/config"
  touch "${MOUNTS_FILE}"

  if ! grep -qxF "${_spec}" "${MOUNTS_FILE}" 2>/dev/null; then
    printf '%s
' "${_spec}" >> "${MOUNTS_FILE}"
  fi

  # Extract host path if formatted as service:/host/path:/target/path or /host/path
  _host_path="${_spec}"
  case "${_spec}" in
    *:*:*)
      _host_path=$(printf '%s' "${_spec}" | cut -d':' -f2)
      ;;
  esac

  if [ -d "${_host_path}" ]; then
    _base=$(basename "${_host_path}")
    ln -sf "${_host_path}" "${MOUNTS_DIR}/${_base}"
    if [ "${_base}" = "openedx-platform" ] || [ -f "${_host_path}/manage.py" ]; then
      ln -sf "${_host_path}" "${OPENEDX_INSTALL_DIR}/codebase_mount"
    fi
  fi

  log_success "Added mount: ${_spec}"
}

# ## mounts_remove
# Removes a registered mount specification and its symlink.
#
# Inputs:
#   $1 - Mount specification or basename
mounts_remove() {
  _spec="${1:-}"
  if [ -z "${_spec}" ]; then
    log_err "Mount specification is required."
    exit 1
  fi

  if [ -f "${MOUNTS_FILE}" ]; then
    _tmp=$(mktemp)
    grep -vxF "${_spec}" "${MOUNTS_FILE}" > "${_tmp}" 2>/dev/null || true
    mv "${_tmp}" "${MOUNTS_FILE}"
  fi

  _base=$(basename "${_spec}")
  rm -f "${MOUNTS_DIR}/${_base}"
  log_success "Removed mount: ${_spec}"
}

# ## mounts_list
# Lists all active host bind mounts.
mounts_list() {
  if [ -f "${MOUNTS_FILE}" ] && [ -s "${MOUNTS_FILE}" ]; then
    cat "${MOUNTS_FILE}"
  else
    log_info "No mounts currently configured."
  fi
}

# ## mounts_clear
# Clears all configured mounts.
mounts_clear() {
  rm -f "${MOUNTS_FILE}"
  rm -rf "${MOUNTS_DIR}"
  mkdir -p "${MOUNTS_DIR}"
  log_success "Cleared all mounts."
}

# ## show_help
# Displays usage instructions for mounts.sh.
show_help() {
  cat <<EOF
Open edX Host Directory Mounts Manager (Tutor Parity)

Usage:
  $0 add <mount_spec>
  $0 remove <mount_spec>
  $0 list
  $0 clear
  $0 help

Commands:
  add       Add a local host directory mount (e.g., ../openedx-platform)
  remove    Remove a configured mount
  list      List all configured mounts
  clear     Remove all configured mounts
  help      Show this help message
EOF
}

COMMAND="${1:-list}"
shift || true

case "${COMMAND}" in
  add)
    mounts_add "$@"
    ;;
  remove|rm|del)
    mounts_remove "$@"
    ;;
  list|ls)
    mounts_list
    ;;
  clear)
    mounts_clear
    ;;
  help|--help|-h)
    show_help
    exit 0
    ;;
  *)
    log_err "Unknown mounts command: ${COMMAND}"
    show_help
    exit 1
    ;;
esac
