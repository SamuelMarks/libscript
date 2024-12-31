#!/bin/sh

# shellcheck disable=SC2236
if [ ! -z "${BASH_VERSION+x}" ]; then
  # shellcheck disable=SC3028 disable=SC3054
  this_file="${BASH_SOURCE[0]}"
  # shellcheck disable=SC3040
  set -o pipefail
elif [ ! -z "${ZSH_VERSION+x}" ]; then
  # shellcheck disable=SC2296
  this_file="${(%):-%x}"
  # shellcheck disable=SC3040
  set -o pipefail
else
  this_file="${0}"
fi
set -feu

guard='H_'"$(realpath -- "${this_file}" | sed 's/[^a-zA-Z0-9_]/_/g')"
test "${guard}" && return
export "${guard}"=1
export DEBIAN_FRONTEND='noninteractive'

get_priv() {
    if [ -n "${PRIV}" ]; then
      true;
    elif [ "$(id -u)" = "0" ]; then
      PRIV='';
    elif command -v sudo >/dev/null 2>&1; then
      PRIV='sudo';
    else
      >&2 echo "Error: This script must be run as root or with sudo privileges."
      exit 1
    fi
    export PRIV;
}

is_installed() {
    # dpkg-query --showformat='${Version}' --show "${1}" 2>/dev/null;
    dpkg -s "${1}" >/dev/null 2>&1
}

apt_depends() {
    pkgs2install=""
    for pkg in "$@"; do
        if ! is_installed "${pkg}"; then
            pkgs2install="${pkgs2install:+${pkgs2install} }${pkg}"
        fi
    done
    if [ -n "${pkgs2install}" ]; then
        get_priv
        "${PRIV}" apt-get install -y -- "${pkgs2install}"
    fi
}
