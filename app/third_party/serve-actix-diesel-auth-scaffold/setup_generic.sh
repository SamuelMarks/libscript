#!/bin/sh
# shellcheck disable=SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145



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

for lib in 'env.sh' '_lib/_common/pkg_mgr.sh' '_lib/_git/git.sh' '_lib/_toolchain/rust/setup.sh'; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

previous_wd="$(pwd)"
depends 'libpq-dev' 'libsqlite3-dev' 'default-libmysqlclient-dev'
git_get https://github.com/SamuelMarks/serve-actix-diesel-auth-scaffold "${SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_DEST}"
cd -- "${SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_DEST}"
d="$( dirname -- "${SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_DEST}" )"'/rust-actix-diesel-auth-scaffold'
depends 'libpq-dev' 'libsqlite3-dev' 'default-libmysqlclient-dev'
git_get https://github.com/offscale/rust-actix-diesel-auth-scaffold "${d}"
rustup toolchain install nightly
cargo +nightly check
if [ ! "${SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_DEST}" = "${SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_BUILD_DIR}" ]; then
  cp -r -- "${SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_DEST}"'/target' "${SERVE_ACTIX_DIESEL_AUTH_SCAFFOLD_BUILD_DIR}"'/' || true
fi
cd -- "${previous_wd}"
