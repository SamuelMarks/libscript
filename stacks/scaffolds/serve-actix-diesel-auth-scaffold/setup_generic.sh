#!/bin/sh
# ## Overview
# Provides a generic, cross-platform setup mechanism for the Actix+Diesel authentication scaffold stack.
# 
# ## Usage
# Execute this script to perform generic initialization steps for serve-actix-diesel-auth-scaffold.


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
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
DIR="${SCRIPT_DIR}"

for LIB in "_lib/_common/pkg_mgr.sh" "_lib/git-servers/git.sh" "_lib/languages/rust/setup.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  # shellcheck source=/dev/null
# shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

libscript_depends 'libpq-dev' 'libsqlite3-dev' 'default-libmysqlclient-dev'
git_get https://github.com/SamuelMarks/serve-actix-diesel-auth-scaffold "${SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_DEST}"
D="$( dirname -- "${SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_DEST}" )"'/rust-actix-diesel-auth-scaffold'
libscript_depends 'libpq-dev' 'libsqlite3-dev' 'default-libmysqlclient-dev'
git_get https://github.com/offscale/rust-actix-diesel-auth-scaffold "${D}"
rustup toolchain install nightly || true
(
  cd -- "${SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_DEST}" || exit 1
  RUSTC_BOOTSTRAP=1 cargo +nightly check || RUSTC_BOOTSTRAP=1 cargo check
)
if [ ! "${SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_DEST}" = "${SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_BUILD_DIR}" ]; then
  cp -r -- "${SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_DEST}"'/target' "${SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_BUILD_DIR}"'/' || true
fi
