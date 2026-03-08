#!/bin/sh
# shellcheck disable=SC3054,SC3040,SC2296,SC2128,SC2039,SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145


set -feu
if [ "${SCRIPT_NAME-}" ]; then this_file="${SCRIPT_NAME}"; else this_file="${0}"; fi
case "${STACK+x}" in *':'"${this_file}"':'*) if (return 0 2>/dev/null); then return; else exit 0; fi ;; esac
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
