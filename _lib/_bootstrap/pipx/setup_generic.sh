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

if ! command -v pipx >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    brew install pipx
    pipx ensurepath
  elif command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -y
    sudo apt-get install -y pipx || pip3 install --user pipx
    pipx ensurepath || python3 -m pipx ensurepath
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y pipx
    pipx ensurepath
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --noconfirm python-pipx
    pipx ensurepath
  else
    if command -v python3 >/dev/null 2>&1; then
      python3 -m pip install --user pipx
      python3 -m pipx ensurepath
    else
      if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/_toolchain/python/setup.sh" ]; then
        "${LIBSCRIPT_ROOT_DIR}/_lib/_toolchain/python/setup.sh"
        python3 -m pip install --user pipx
        python3 -m pipx ensurepath
      else
        depends python3 || true
        python3 -m pip install --user pipx
        python3 -m pipx ensurepath
      fi
    fi
  fi
fi
