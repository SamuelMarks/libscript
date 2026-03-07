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

if ! command -v java >/dev/null 2>&1; then
  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/_toolchain/java/setup.sh" ]; then
    "${LIBSCRIPT_ROOT_DIR}/_lib/_toolchain/java/setup.sh"
  else
    depends java || true
  fi
fi

if ! command -v gradle >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    brew install gradle
  elif command -v sdk >/dev/null 2>&1 || [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
    if [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
      # shellcheck disable=SC1091
      . "$HOME/.sdkman/bin/sdkman-init.sh"
    fi
    sdk install gradle
  else
    if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/_bootstrap/sdkman/setup.sh" ]; then
      "${LIBSCRIPT_ROOT_DIR}/_lib/_bootstrap/sdkman/setup.sh"
      if [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
        # shellcheck disable=SC1091
        . "$HOME/.sdkman/bin/sdkman-init.sh"
      fi
      sdk install gradle
    elif command -v apt-get >/dev/null 2>&1; then
      sudo apt-get update -y
      sudo apt-get install -y gradle
    elif command -v dnf >/dev/null 2>&1; then
      sudo dnf install -y gradle
    elif command -v pacman >/dev/null 2>&1; then
      sudo pacman -S --noconfirm gradle
    else
      printf "Error: Could not install gradle via standard package managers or SDKMAN!.\n" >&2
      exit 1
    fi
  fi
fi
