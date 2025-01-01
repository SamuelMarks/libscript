#!/bin/sh

# shellcheck disable=SC2236
if [ ! -z "${SCRIPT_NAME+x}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ ! -z "${BASH_VERSION+x}" ]; then
  # shellcheck disable=SC3028 disable=SC3054
  this_file="${BASH_SOURCE[0]}"
  # shellcheck disable=SC3040
  set -o pipefail
elif [ ! -z "${ZSH_VERSION+x}" ]; then
  # shellcheck disable=SC2296
  this_file="${(%):-%x}"
  # shellcheck disable=SC3040
  set -o pipefail
else
  this_file="${0}"
fi
set -feu

STACK="${STACK:-:}"
case "${STACK}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    return ;;
  *)
    printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
STACK="${STACK}${this_file}"':'
export STACK

SCRIPT_NAME="${SCRIPT_ROOT_DIR}"'/_lib/_common/priv.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

export DEBIAN_FRONTEND='noninteractive'

is_installed() {
    # dpkg-query --showformat='${Version}' --show "${1}" 2>/dev/null;
    dpkg -s "${1}" >/dev/null 2>&1
}

apt_depends() {
    pkgs2install=""
    for pkg in "$@"; do
        if ! is_installed "${pkg}"; then
            pkgs2install="${pkgs2install:+${pkgs2install} }${pkg}"
        fi
    done
    if [ -n "${pkgs2install}" ]; then
        "${PRIV}" apt-get install -y -- "${pkgs2install}"
    fi
}
