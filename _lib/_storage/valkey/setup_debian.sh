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

LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${DIR}"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"
export LIBSCRIPT_ROOT_DIR
LIBSCRIPT_DATA_DIR="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"
export LIBSCRIPT_DATA_DIR

previous_wd="$(pwd)"
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${DIR}"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"

DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)

for lib in 'env.sh' '_lib/_common/pkg_mgr.sh' '_lib/_common/priv.sh' '_lib/_git/git.sh'; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

SCRIPT_NAME="${DIR}"'/env.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

depends git build-essential libsystemd-dev

target="${VALKEY_BUILD_DIR}"'/valkey'
git_get https://github.com/valkey-io/valkey "${target}"
# shellcheck disable=SC2164
cd -- "${target}"
hash="$(git rev-list HEAD -1)"

build_install() {
  [ -d 'build' ] || mkdir -p -- 'build'
  touch 'build/'"${hash}"
  make BUILD_TLS='yes' USE_SYSTEMD='yes'
  "${PRIV}" make install
}

noop=0

if [ -f 'build/'"${hash}" ]; then
  noop=1
elif [ -f './src/rand.o' ]; then
  make distclean
  build_install
else
  build_install
fi


# shellcheck disable=SC2164
cd -- "${previous_wd}"

if [ "${noop}" -eq 0 ]; then
  service_name='valkey'
  "${PRIV}" systemctl stop "${service_name}" || true
  "${PRIV}" install -m 0644 -o 'root' -- "${LIBSCRIPT_ROOT_DIR}"'/_lib/_storage/valkey/conf/valkey.conf' /etc/
  "${PRIV}" install -m 0644 -o 'root' -- "${LIBSCRIPT_ROOT_DIR}"'/_lib/_storage/valkey/conf/systemd/'"${service_name}"'.service' /etc/systemd/system/
  "${PRIV}" systemctl daemon-reload
  "${PRIV}" systemctl stop "${service_name}" || true
  "${PRIV}" systemctl start "${service_name}"
fi

[ -d "${LIBSCRIPT_DATA_DIR}" ] || mkdir -p -- "${LIBSCRIPT_DATA_DIR}"
val='redis://localhost'
for key in 'REDIS_URL' 'VALKEY_URL'; do
  lang_export 'cmd' "${key}" "${val}" >> "${LIBSCRIPT_DATA_DIR}"'/dyn_env.cmd'
  lang_export 'sh' "${key}" "${val}" >> "${LIBSCRIPT_DATA_DIR}"'/dyn_env.sh'
  lang_export 'sqlite' "${key}" "${val}"
done
