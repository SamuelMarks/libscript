#!/bin/sh

realpath -- "${0}"
set -xv
guard='H_'"$(realpath -- "${0}" | sed 's/[^a-zA-Z0-9_]/_/g')"
if env | grep -qF "${guard}"'=1'; then return ; fi
export "${guard}"=1

SCRIPT_ROOT_DIR="${SCRIPT_ROOT_DIR:-$( dirname -- "$( dirname -- "$( dirname -- "${0}" )" )" )}"

#DIR="$( dirname -- "$( readlink -nf -- "${0}" )")"
# shellcheck disable=SC1091
. "${SCRIPT_ROOT_DIR}"'/_lib/_common/os_info.sh'

get_priv() {
    if [ -n "${PRIV}" ]; then
      true;
    elif [ "$(id -u)" = "0" ]; then
      PRIV='';
    elif cmd_avail sudo; then
      PRIV='sudo';
    else
      >&2 echo "Error: This script must be run as root or with sudo privileges."
      exit 1
    fi
    export PRIV;
}

ensure_available() {
  case "${PKG_MGR}" in
    'apk') apk add "${0}" ;;
    'apt-get') apt_depends "${0}" ;;
    'dnf') dnf install "${0}" ;;
    *) >&2 printf 'Unimplemented, package manager %s\n' "${PKG_MGR}"
  esac
}

cmd_avail() {
  command -v "${1}" >/dev/null 2>&1
}
