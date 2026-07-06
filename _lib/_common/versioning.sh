#!/bin/sh
# ## Overview
# Provides common utilities for managing component versions and aliases on Unix systems.
# It defines functions (`libscript_get_version_dir`, `libscript_symlink_alias`) to
# resolve installation paths and create symlinks for version aliasing within
# the local libscript environment.
# 
# ## Usage
# Source this file to utilize its version path resolution and aliasing utilities.

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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)

# versioning.sh
# Common utilities for managing native libscript installations and version aliases.

libscript_get_version_dir() {
  component="$1"
  version="$2"
  printf '%s\n' "${LIBSCRIPT_HOME:-$HOME/.libscript}/${component}/${version}"
}

libscript_symlink_alias() {
  component="$1"
  alias_name="$2"
  exact_version="$3"
  
  base_dir="${LIBSCRIPT_HOME:-$HOME/.libscript}/${component}"
  mkdir -p "${base_dir}"
  
  if [ "${alias_name}" != "${exact_version}" ]; then
    (cd "${base_dir}" && rm -f "${alias_name}" && ln -s "${exact_version}" "${alias_name}")
  fi
}
