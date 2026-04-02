#!/bin/sh
set -feu
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  this_file="${0}"
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

DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${DIR}"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/pkg_mgr.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091,SC2034
. "${SCRIPT_NAME}"

if ! command -v guix >/dev/null 2>&1; then
  echo "Installing GNU Guix..."
  if [ "$(id -u)" != "0" ] && ! command -v sudo >/dev/null 2>&1; then
    echo "Error: Root access or sudo is required to install Guix." >&2
    exit 1
  fi

  tmp_sh="/tmp/guix-install.sh"
  libscript_download "https://git.savannah.gnu.org/cgit/guix.git/plain/etc/guix-install.sh" "$tmp_sh"
  
  chmod +x "$tmp_sh"
  
  if [ "$(id -u)" = "0" ]; then
    yes '' | "$tmp_sh"
  else
    yes '' | sudo "$tmp_sh"
  fi
  
  rm -f "$tmp_sh"
fi
