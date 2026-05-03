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

if ! command -v perl >/dev/null 2>&1; then
  if ! depends perl ; then
    true
  fi
fi

if ! command -v cpanm >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    brew install cpanminus
  elif command -v apt-get >/dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive
    priv apt-get update -y
    priv apt-get install -y cpanminus
  elif command -v dnf >/dev/null 2>&1; then
    priv dnf install -y perl-App-cpanminus
  elif command -v pacman >/dev/null 2>&1; then
    priv pacman -S --noconfirm cpanminus
  else
    _tmp_script="/tmp/cpanm-bootstrap"
    libscript_download "https://cpanmin.us" "$_tmp_script"
    priv perl "$_tmp_script" -- App::cpanminus
    rm -f "$_tmp_script"
  fi
fi
