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

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR:-..}"'/_lib/_common/pkg_mgr.sh'
export SCRIPT_NAME
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
    if command -v curl >/dev/null 2>&1; then
      curl -L https://cpanmin.us | priv perl - App::cpanminus
    elif command -v wget >/dev/null 2>&1; then
      wget -O- https://cpanmin.us | priv perl - App::cpanminus
    else
      printf "Error: curl or wget is required to bootstrap cpanm.\n" >&2
      exit 1
    fi
  fi
fi
