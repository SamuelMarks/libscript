#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  this_file="${(%):-%x}"
  set -o pipefail
else
  this_file="${0}"
fi

case "${STACK+x}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
export STACK="${STACK:-}${this_file}"':'
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR:-$(cd "$(dirname "$this_file")/../../.." && pwd)}/_lib/_common/pkg_mgr.sh"
# shellcheck disable=SC1090,SC1091,SC2034
. "${SCRIPT_NAME}"

if ! command -v nix >/dev/null 2>&1; then
  echo "Bootstrapping Nix package manager..."
  libscript_download "https://nixos.org/nix/install" "/tmp/install-nix.sh"
  
  if [ "$(uname -s)" = "Darwin" ]; then
     echo "Running multi-user nix install for macOS..."
     sh "/tmp/install-nix.sh" --daemon --yes
  elif [ "$(id -u)" -eq 0 ]; then
     echo "Running multi-user nix install..."
     sh "/tmp/install-nix.sh" --daemon --yes
  else
     echo "Running single-user nix install..."
     sh "/tmp/install-nix.sh" --no-daemon --yes
  fi
  
  # Ensure the environment is sourced for the current shell
  if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
# shellcheck disable=SC1090,SC1091,SC2034
     . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
  elif [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
# shellcheck disable=SC1090,SC1091,SC2034
     . "$HOME/.nix-profile/etc/profile.d/nix.sh"
  fi
fi
