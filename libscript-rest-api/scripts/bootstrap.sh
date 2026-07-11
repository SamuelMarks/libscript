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
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
else
  THIS_FILE="${0}"
fi

SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"

# Import common logging if available
if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/_common/log.sh" ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/log.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
else
  log_info() { printf '[INFO] %s\n' "$1"; }
  log_error() { printf '[ERROR] %s\n' "$1" >&2; }
fi

detect_os() {
  OS="$(uname -s)"
  case "$OS" in
    Linux*)     printf '%s\n' "Linux" ;;
    Darwin*)    printf '%s\n' "macOS" ;;
    CYGWIN*|MINGW*|MSYS*) printf '%s\n' "Windows" ;;
    *)          printf '%s\n' "Unknown" ;;
  esac
}

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

install_deps_linux() {
  log_info "Detected Linux. Checking dependencies..."
  if check_deps; then
    log_info "All dependencies are already installed."
    return 0
  fi
  log_info "Installing dependencies..."
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y gcc clang git cmake make jq pkg-config
  elif command -v yum >/dev/null 2>&1; then
    sudo yum update -y
    sudo yum install -y gcc clang git cmake make jq pkgconfig
  elif command -v apk >/dev/null 2>&1; then
    sudo apk add --no-cache gcc clang git cmake make jq pkgconf musl-dev
  else
    log_error "Unsupported Linux package manager. Please install gcc, git, and cmake manually."
    exit 1
  fi
}

install_deps_macos() {
  log_info "Detected macOS. Checking dependencies..."
  if check_deps; then
    log_info "All dependencies are already installed."
    return 0
  fi
  log_info "Installing dependencies via Homebrew..."
  if ! command -v brew >/dev/null 2>&1; then
    log_error "Homebrew not found. Please install Homebrew first: https://brew.sh/"
    exit 1
  fi
  brew install gcc llvm git cmake make jq pkg-config
}

install_deps_windows() {
  log_info "Detected Windows environment in shell. Suggesting use of bootstrap.cmd."
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

log_info "Dependency resolution complete. C compiler, git, and cmake are ready."

# Fetch c-rest-framework
VENDOR_DIR="${SCRIPT_DIR}/../vendor"
mkdir -p "$VENDOR_DIR"
if [ ! -d "$VENDOR_DIR/c-rest-framework/.git" ]; then
  log_info "Cloning c-rest-framework into vendor directory..."
  git clone https://github.com/SamuelMarks/c-rest-framework "$VENDOR_DIR/c-rest-framework"
else
  log_info "c-rest-framework already cloned. Pulling latest..."
  (cd "$VENDOR_DIR/c-rest-framework" && git pull)
fi

log_info "Framework acquisition complete."
