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

if ! command -v perl >/dev/null 2>&1; then
  depends perl || true
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
