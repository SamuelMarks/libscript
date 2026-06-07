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
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR:-..}"'/_lib/_common/pkg_mgr.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"

if ! command -v java >/dev/null 2>&1; then
  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/languages/java/setup.sh" ]; then
    "${LIBSCRIPT_ROOT_DIR}/_lib/languages/java/setup.sh"
  else
    if ! libscript_depends java ; then
      true
    fi
  fi
fi

if ! command -v gradle >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    brew install gradle
  elif command -v sdk >/dev/null 2>&1 || [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
    if [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
      # shellcheck disable=SC1091
# shellcheck disable=SC1090,SC1091
      . "$HOME/.sdkman/bin/sdkman-init.sh"
    fi
    sdk install gradle
  else
    if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/sdkman/setup.sh" ]; then
      "${LIBSCRIPT_ROOT_DIR}/_lib/package-managers/sdkman/setup.sh"
      if [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
        # shellcheck disable=SC1091
# shellcheck disable=SC1090,SC1091
        . "$HOME/.sdkman/bin/sdkman-init.sh"
      fi
      sdk install gradle
    elif command -v apt >/dev/null 2>&1; then
      pkg_mgr update
      pkg_mgr install gradle
    elif command -v dnf >/dev/null 2>&1; then
      pkg_mgr install gradle
    elif command -v pacman >/dev/null 2>&1; then
      libscript_depends gradle
    else
      printf "Error: Could not install gradle via standard package managers or SDKMAN!.\n" >&2
      exit 1
    fi
  fi
fi
