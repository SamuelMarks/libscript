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
# Resolve component directory and LibScript root
DIR=$(CDPATH='' cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(D="${DIR}"; while [ ! -f "${D}"'/ROOT' ]; do D="$(dirname -- "${D}")"; done; printf '%s' "${D}")}"
export LIBSCRIPT_ROOT_DIR

# Source logging
. "${LIBSCRIPT_ROOT_DIR}/_lib/_common/log.sh"

# Source common OS info
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/os_info.sh'
export SCRIPT_NAME
. "${SCRIPT_NAME}"

# Source package manager utilities (includes libscript_depends and libscript_download)
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/pkg_mgr.sh'
export SCRIPT_NAME
. "${SCRIPT_NAME}"

# Source path resolution
SCRIPT_DIR_NAME="$(dirname -- "${THIS_FILE}")"
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/paths.sh'
export SCRIPT_NAME
. "${SCRIPT_NAME}"
resolve_component_paths

# Source schema validation
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/validate_schema.sh'
export SCRIPT_NAME
. "${SCRIPT_NAME}"

# Run schema validation if exists
if [ -f "${DIR}/vars.schema.json" ]; then
  validate_schema "${DIR}/vars.schema.json"
fi

# Helper for installing a binary to a local or system bin directory
libscript_install_binary() {
  src_path="$1"
  bin_name="$2"

  dest_dir="${PREFIX:-$HOME/.local/bin}"
  mkdir -p "$dest_dir"

  if [ -w "/usr/local/bin" ] && [ "${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-}" = "system" ]; then
    dest_dir="/usr/local/bin"
  fi

  log_info "Installing $bin_name to $dest_dir..."
  cp -f "$src_path" "$dest_dir/$bin_name"
  chmod +x "$dest_dir/$bin_name"

  # Update PATH in current session if needed
  case ":$PATH:" in
    *":$dest_dir:"*) ;;
    *) export PATH="$dest_dir:$PATH" ;;
  esac
}

# Source component-specific environment if exists
ENV_SCRIPT="${DIR}"'/env.sh'
if [ -f "${ENV_SCRIPT}" ]; then
  SCRIPT_NAME="${ENV_SCRIPT}"
  export SCRIPT_NAME
  . "${SCRIPT_NAME}"
fi

# OS-specific delegation logic
OS_SETUP_SCRIPT="${DIR}"'/setup_'"${TARGET_OS}"'.sh'
if [ -f "${OS_SETUP_SCRIPT}" ]; then
  SCRIPT_NAME="${OS_SETUP_SCRIPT}"
  export SCRIPT_NAME
  . "${SCRIPT_NAME}"
else
  SCRIPT_NAME="${DIR}"'/setup_generic.sh'
  export SCRIPT_NAME
  . "${SCRIPT_NAME}"
fi


# Automated netctl registration for services
_PKG_UPPER=$(basename "${DIR}" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
eval "_LISTEN_SOCKET=\${${_PKG_UPPER}_LISTEN_SOCKET:-\${LIBSCRIPT_LISTEN_SOCKET:-}}"
eval "_LISTEN_ADDRESS=\${${_PKG_UPPER}_LISTEN_ADDRESS:-\${LIBSCRIPT_LISTEN_ADDRESS:-}}"
eval "_LISTEN_PORT=\${${_PKG_UPPER}_LISTEN_PORT:-\${LIBSCRIPT_LISTEN_PORT:-}}"

if [ -n "${_LISTEN_SOCKET}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "unix:${_LISTEN_SOCKET}" >/dev/null 2>&1 ; then
    true
  fi
elif [ -n "${_LISTEN_ADDRESS}" ] && [ -n "${_LISTEN_PORT}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "${_LISTEN_ADDRESS}:${_LISTEN_PORT}" >/dev/null 2>&1 ; then
    true
  fi
elif [ -n "${_LISTEN_PORT}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "${_LISTEN_PORT}" >/dev/null 2>&1 ; then
    true
  fi
fi
