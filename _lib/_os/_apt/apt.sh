#!/bin/sh

realpath -- "${0}"
set -x
guard='H_'"$(realpath -- "${0}" | sed 's/[^a-zA-Z0-9_]/_/g')"
if env | grep -qF "${guard}"'=1'; then return ; fi
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
