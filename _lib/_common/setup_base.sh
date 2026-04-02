#!/bin/sh
# # LibScript Common Setup Entrypoint
#
# ## Overview
# This script provides a standardized entrypoint for component installation.
# It resolves the target operating system and delegates to the appropriate 
# `setup_<os>.sh` or `setup_generic.sh` within the component directory.
#
# ## Usage
# Sourced by a component's `setup.sh`:
#
# ```sh
# #!/bin/sh
# . "$(dirname "$0")/../../_common/setup_base.sh"
# ```

set -feu

# Boilerplate for finding this file and root
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  this_file="${0}"
else
  this_file="${0}"
fi

# Prevent circular or double execution
case "${STACK+x}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
export STACK="${STACK:-}${this_file}"':'

# Resolve component directory and LibScript root
DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${DIR}"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"
export LIBSCRIPT_ROOT_DIR

# Source logging
. "${LIBSCRIPT_ROOT_DIR}/_lib/_common/log.sh"

# Source common OS info
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/os_info.sh'
export SCRIPT_NAME
. "${SCRIPT_NAME}"

# Source package manager utilities (includes depends and libscript_download)
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/pkg_mgr.sh'
export SCRIPT_NAME
. "${SCRIPT_NAME}"

# Source path resolution
SCRIPT_DIR_NAME="$(dirname -- "${this_file}")"
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
env_script="${DIR}"'/env.sh'
if [ -f "${env_script}" ]; then
  SCRIPT_NAME="${env_script}"
  export SCRIPT_NAME
  . "${SCRIPT_NAME}"
fi

# OS-specific delegation logic
os_setup_script="${DIR}"'/setup_'"${TARGET_OS}"'.sh'
if [ -f "${os_setup_script}" ]; then
  SCRIPT_NAME="${os_setup_script}"
  export SCRIPT_NAME
  . "${SCRIPT_NAME}"
else
  SCRIPT_NAME="${DIR}"'/setup_generic.sh'
  export SCRIPT_NAME
  . "${SCRIPT_NAME}"
fi

# Automated netctl registration for services
if [ -n "${CADDY_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET:-}}" ]; then
  "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "unix:${CADDY_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET}}" >/dev/null 2>&1 || true
elif [ -n "${CADDY_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS:-}}" ] && [ -n "${CADDY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
  "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "${CADDY_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS}}:${CADDY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 || true
elif [ -n "${CADDY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
  "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "${CADDY_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 || true
fi
