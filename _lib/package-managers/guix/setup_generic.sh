#!/bin/sh

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
DIR=$(CDPATH='' cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(D="${DIR}"; while [ ! -f "${D}"'/ROOT' ]; do D="$(dirname -- "${D}")"; done; printf '%s' "${D}")}"

for LIB in '_lib/_common/pkg_mgr.sh' ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

if ! command -v guix >/dev/null 2>&1; then
  log_info "Installing GNU Guix..."
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
