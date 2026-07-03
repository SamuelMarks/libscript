#!/bin/sh
# ## Overview
# Generic setup script for the nix component.
# It provides fallback installation logic and cross-platform installation steps
# when a more specific OS/distribution setup script is not available.
#
# ## Usage
# This script is typically called internally by the component lifecycle.


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
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR:-$(cd "$(dirname "$THIS_FILE")/../../.." && pwd)}/_lib/_common/pkg_mgr.sh"
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"

if ! command -v nix >/dev/null 2>&1; then
  log_info "Bootstrapping Nix package manager..."
  libscript_download "https://nixos.org/nix/install" "/tmp/install-nix.sh"

  if [ "$(uname -s)" = "Darwin" ]; then
      log_info "Running multi-user nix install for macOS..."
      sh "/tmp/install-nix.sh" --daemon --yes
  elif [ "$(id -u)" -eq 0 ]; then
      log_info "Running multi-user nix install..."
      sh "/tmp/install-nix.sh" --daemon --yes
  else
      log_info "Running single-user nix install..."
      sh "/tmp/install-nix.sh" --no-daemon --yes
  fi

  # Ensure the environment is sourced for the current shell
  if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
# shellcheck disable=SC1090,SC1091
      . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
  elif [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
# shellcheck disable=SC1090,SC1091
      . "$HOME/.nix-profile/etc/profile.d/nix.sh"
  fi
fi
