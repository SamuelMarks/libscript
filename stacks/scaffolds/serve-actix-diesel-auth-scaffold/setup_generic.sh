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

for LIB in '_lib/_common/pkg_mgr.sh' '_lib/git-servers/git.sh' '_lib/languages/rust/setup.sh'; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  # shellcheck source=/dev/null
# shellcheck disable=SC1090,SC1091,SC2034
  . "${SCRIPT_NAME}"
done

PREVIOUS_WD="$(pwd)"
depends 'libpq-dev' 'libsqlite3-dev' 'default-libmysqlclient-dev'
git_get https://github.com/SamuelMarks/serve-actix-diesel-auth-scaffold "${SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_DEST}"
cd -- "${SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_DEST}"
D="$( dirname -- "${SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_DEST}" )"'/rust-actix-diesel-auth-scaffold'
depends 'libpq-dev' 'libsqlite3-dev' 'default-libmysqlclient-dev'
git_get https://github.com/offscale/rust-actix-diesel-auth-scaffold "${D}"
rustup toolchain install nightly || true
RUSTC_BOOTSTRAP=1 cargo +nightly check || RUSTC_BOOTSTRAP=1 cargo check
if [ ! "${SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_DEST}" = "${SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_BUILD_DIR}" ]; then
  cp -r -- "${SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_DEST}"'/target' "${SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_BUILD_DIR}"'/' || true
fi
cd -- "${PREVIOUS_WD}"
