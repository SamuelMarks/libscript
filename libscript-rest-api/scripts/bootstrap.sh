#!/bin/sh
# ## Overview
# Dependency resolution script for bootstrapping the libscript REST API development environment.
#
# ## Usage
# Executes natively to detect the OS and install required dependencies (C compiler, git, cmake).
# Run via: `./scripts/bootstrap.sh`

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

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "/?" ] || [ "${1:-}" = "-?" ]; then
  printf '%s\n' "Usage: $(basename "$0")"
  printf '%s\n' 'Dependency resolution script for bootstrapping the libscript REST API development environment.'
  printf '\n'
  printf '%s\n' 'Options:'
  printf '%s\n' '  --help, -h, /?, -?  Show this help message.'
  exit 0
fi

_BOOTSTRAP_SCRIPT_DIR="${SCRIPT_DIR}"
# Import common logging if available
if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/_common/log.sh" ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/log.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
  unset SCRIPT_NAME || true
else
  # ## log_info
  # Outputs informational log messages.
  log_info() { printf '[INFO] %s\n' "$1"; }
  # ## log_error
  # Outputs error log messages.
  log_error() { printf '[ERROR] %s\n' "$1" >&2; }
fi
SCRIPT_DIR="${_BOOTSTRAP_SCRIPT_DIR}"

# ## detect_os
# Detects the host operating system, distribution, and CPU architecture.
detect_os() {
  OS="$(uname -s)"
  case "$OS" in
    Linux*)     printf '%s\n' "Linux" ;;
    Darwin*)    printf '%s\n' "macOS" ;;
    CYGWIN*|MINGW*|MSYS*) printf '%s\n' "Windows" ;;
    *)          printf '%s\n' "Unknown" ;;
  esac
}

# ## check_deps
# Verifies that required host tools and dependencies are available in PATH.
check_deps() {
  for cmd in gcc clang git cmake make jq pkg-config; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      if [ "$cmd" = "pkg-config" ] && command -v pkgconf >/dev/null 2>&1; then
        continue
      fi
      return 1
    fi
  done
  return 0
}

# ## install_deps_linux
# Performs the install_deps_linux operation and updates component state.
install_deps_linux() {
  log_info 'Detected Linux. Checking dependencies...'
  if check_deps; then
    log_info 'All dependencies are already installed.'
    return 0
  fi
  log_info 'Installing dependencies via libscript...'
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install c latest
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install git latest
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install cmake latest
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install jq latest
  for _env_f in "_lib/languages/c/env.sh" "_lib/git-servers/git/env.sh" "_lib/toolchains/cmake/env.sh" "_lib/utilities/jq/env.sh"; do
    if [ -f "${LIBSCRIPT_ROOT_DIR}/${_env_f}" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_env_f}"
      export SCRIPT_NAME
      # shellcheck disable=SC1090
      . "${SCRIPT_NAME}"
    fi
  done
}

# ## install_deps_macos
# Performs the install_deps_macos operation and updates component state.
install_deps_macos() {
  log_info 'Detected macOS. Checking dependencies...'
  if check_deps; then
    log_info 'All dependencies are already installed.'
    return 0
  fi
  log_info 'Installing dependencies via libscript...'
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install c latest
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install git latest
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install cmake latest
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install jq latest
  for _env_f in "_lib/languages/c/env.sh" "_lib/git-servers/git/env.sh" "_lib/toolchains/cmake/env.sh" "_lib/utilities/jq/env.sh"; do
    if [ -f "${LIBSCRIPT_ROOT_DIR}/${_env_f}" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_env_f}"
      export SCRIPT_NAME
      # shellcheck disable=SC1090
      . "${SCRIPT_NAME}"
    fi
  done
}

# ## install_deps_windows
# Performs the install_deps_windows operation and updates component state.
install_deps_windows() {
  log_info 'Detected Windows environment in shell. Suggesting use of bootstrap.cmd.'
  log_error "Please run scripts\bootstrap.cmd from a Command Prompt or PowerShell."
  exit 1
}

OS=$(detect_os)
case "$OS" in
  Linux)  install_deps_linux ;;
  macOS)  install_deps_macos ;;
  Windows) install_deps_windows ;;
  *)      log_error "Unsupported Operating System: $OS"; exit 1 ;;
esac

log_info 'Dependency resolution complete. C compiler, git, and cmake are ready.'
SCRIPT_DIR="${_BOOTSTRAP_SCRIPT_DIR}"

# Fetch c-rest-framework
VENDOR_DIR="${SCRIPT_DIR}/../vendor"
mkdir -p "$VENDOR_DIR"
if [ ! -d "$VENDOR_DIR/c-rest-framework/.git" ]; then
  log_info 'Cloning c-rest-framework into vendor directory...'
  git clone https://github.com/SamuelMarks/c-rest-framework "$VENDOR_DIR/c-rest-framework"
else
  log_info 'c-rest-framework already cloned. Pulling latest...'
  (cd "$VENDOR_DIR/c-rest-framework" && git fetch --all && git reset --hard '@{upstream}')
fi

log_info 'Framework acquisition complete.'
