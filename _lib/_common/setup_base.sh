#!/bin/sh
# ## Overview
# Provides the foundational setup logic for a component. It aggregates essential common libraries (logging, OS detection, package manager utilities, paths), loads the component's environment, delegates to OS-specific installers, and handles network port registrations.
# ## Usage
# Source or execute this file internally as the core implementation of `setup.sh`.
set -feu
_setup_base_caller_this="${THIS_FILE:-}"; _setup_base_caller_dir="${SCRIPT_DIR:-}"
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
    [ -n "$_setup_base_caller_this" ] && THIS_FILE="$_setup_base_caller_this"
    [ -n "$_setup_base_caller_dir" ] && SCRIPT_DIR="$_setup_base_caller_dir"
    unset SCRIPT_NAME || true; if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
# Resolve component directory and LibScript root
DIR="${SCRIPT_DIR:-$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)}"
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR
_setup_base_this="${THIS_FILE}"
_setup_base_dir="${DIR}"

# Source logging
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/log.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"

# Source common OS info
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/os_info.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"

# Source package manager utilities (includes libscript_depends and libscript_download)
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/pkg_mgr.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"

# Source versioning and generic lifecycle action helpers
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/versioning.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"

# Source path resolution
_SCRIPT_DIR_NAME="${_setup_base_dir}"
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/paths.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
THIS_FILE="${_setup_base_this}"
DIR="${_setup_base_dir}"
SCRIPT_DIR="${_setup_base_dir}"
resolve_component_paths


# ## libscript_install_binary
# Helper for installing a binary to a local or system bin directory
libscript_install_binary() {
  src_path="$1"
  bin_name="$2"

  dest_dir="${PREFIX:-${HOME:-/root}/.local/bin}"
  mkdir -p "$dest_dir"

  if [ -w "/usr/local/bin" ] && [ "${LIBSCRIPT_DEFAULT_INSTALL_METHOD:-}" = "system" ]; then
    dest_dir='/usr/local/bin'
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
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
  unset SCRIPT_NAME || true
  STACK="${STACK%"${ENV_SCRIPT}":}"
  export STACK
  THIS_FILE="${_setup_base_this}"
  DIR="${_setup_base_dir}"
  SCRIPT_DIR="${_setup_base_dir}"
fi

# OS-specific delegation logic
STACK="${STACK%"${_setup_base_this}":}"
if [ -n "${_setup_base_caller_this:-}" ]; then
  STACK="${STACK%"${_setup_base_caller_this}":}"
fi
export STACK
OS_SETUP_SCRIPT="${DIR}"'/setup_'"${TARGET_OS}"'.sh'
if [ "${LIBSCRIPT_DEFAULT_INSTALL_METHOD:-${LIBSCRIPT_INSTALL_METHOD:-}}" = "from-source" ] && [ -f "${DIR}/setup_generic.sh" ]; then
  _delegated_setup="${DIR}"'/setup_generic.sh'
elif [ -f "${OS_SETUP_SCRIPT}" ]; then
  _delegated_setup="${OS_SETUP_SCRIPT}"
else
  _delegated_setup="${DIR}"'/setup_generic.sh'
fi
SCRIPT_NAME="${_delegated_setup}"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true
STACK="${STACK%"${_delegated_setup}":}"
export STACK
unset _delegated_setup || true
THIS_FILE="${_setup_base_this}"
DIR="${_setup_base_dir}"
SCRIPT_DIR="${_setup_base_dir}"


# Automated netctl registration for services
_PKG_UPPER=$(basename "${DIR}" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
if [ "$_PKG_UPPER" = "7ZIP" ]; then _PKG_UPPER="SEVENZIP"; fi
case "$_PKG_UPPER" in [0-9]*) _PKG_UPPER="_${_PKG_UPPER}" ;; esac

_LISTEN_SOCKET=$(printenv "${_PKG_UPPER}_LISTEN_SOCKET" 2>/dev/null || true)
: "${_LISTEN_SOCKET:=${LIBSCRIPT_LISTEN_SOCKET:-}}"

_LISTEN_ADDRESS=$(printenv "${_PKG_UPPER}_LISTEN_ADDRESS" 2>/dev/null || true)
: "${_LISTEN_ADDRESS:=${LIBSCRIPT_LISTEN_ADDRESS:-}}"

_LISTEN_PORT=$(printenv "${_PKG_UPPER}_LISTEN_PORT" 2>/dev/null || true)
: "${_LISTEN_PORT:=${LIBSCRIPT_LISTEN_PORT:-}}"

if [ -n "${_LISTEN_SOCKET}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/_lib/networking/netctl/cli.sh" --listen "unix:${_LISTEN_SOCKET}" >/dev/null 2>&1 ; then
    true
  fi
elif [ -n "${_LISTEN_ADDRESS}" ] && [ -n "${_LISTEN_PORT}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/_lib/networking/netctl/cli.sh" --listen "${_LISTEN_ADDRESS}:${_LISTEN_PORT}" >/dev/null 2>&1 ; then
    true
  fi
elif [ -n "${_LISTEN_PORT}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/_lib/networking/netctl/cli.sh" --listen "${_LISTEN_PORT}" >/dev/null 2>&1 ; then
    true
  fi
fi

STACK="${STACK%"${THIS_FILE}":}"
export STACK
[ -n "${_setup_base_caller_dir:-}" ] && SCRIPT_DIR="$_setup_base_caller_dir"
[ -n "${_setup_base_caller_this:-}" ] && THIS_FILE="$_setup_base_caller_this"
unset SCRIPT_NAME _setup_base_caller_this _setup_base_caller_dir || true
