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

DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)

LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${DIR}"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"

for lib in 'env.sh' '_lib/_common/pkg_mgr.sh' '_lib/_git/git.sh' '_lib/_toolchain/rust/setup.sh'; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

previous_wd="$(pwd)"
git_get https://github.com/SamuelMarks/serve-actix-diesel-auth-scaffold "${SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_DEST}"
cd -- "${SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_DEST}"
d="$( dirname -- "${SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_DEST}" )"'/rust-actix-diesel-auth-scaffold'
git_get https://github.com/offscale/rust-actix-diesel-auth-scaffold "${d}"
~/.cargo/bin/cargo build --release
if [ ! "${SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_DEST}" = "${SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_BUILD_DIR}" ]; then
  cp -r -- "${SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_DEST}"'/target' "${SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_BUILD_DIR}"'/'
fi
cd -- "${previous_wd}"
