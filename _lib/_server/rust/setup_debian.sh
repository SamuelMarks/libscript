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
LIBSCRIPT_DATA_DIR="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"

for lib in 'env.sh' '_lib/_common/environ.sh' '_lib/_common/pkg_mgr.sh' '_lib/_git/git.sh' '_lib/_toolchain/rust/setup.sh'; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

previous_wd="$(pwd)"
service_name=''
if [ -z "${DEST+x}" ]; then
  rand="$(env LC_CTYPE='C' tr -cd '[:lower:]' < '/dev/urandom' | head -c 8)"
  DEST="${LIBSCRIPT_DATA_DIR}"'/'"${rand}"
  export DEST
  mkdir -p -- "${DEST}"
  service_name='rust-'"${rand}"
else
  service_name="$(basename -- "${DEST}")"
fi
name=' '"${service_name}"
cd -- "${DEST}"
# shellcheck disable=SC1091
. "${HOME}"'/.cargo/env'

cargo build --release

if [ ! -z "${VARS+x}" ]; then
  object2key_val "${VARS}" 'export ' "'" >> "${LIBSCRIPT_DATA_DIR}"'/dyn_env.sh'
fi
ENV=''
if [ -f "${LIBSCRIPT_DATA_DIR}"'/dyn_env.sh' ]; then
  chmod +x "${LIBSCRIPT_DATA_DIR}"'/dyn_env.sh'
  ENV="$(cut -c8- "${LIBSCRIPT_DATA_DIR}"'/dyn_env.sh' | awk '{arr[i++]=$0} END {while (i>0) print arr[--i] }' | tr -d "'" | awk -F= '!seen[$1]++' | xargs printf 'Environment="%s"\n')"
fi
EXEC_START="$(pwd)"'/'"$(find target/release -depth -maxdepth 1 -type f -executable -print -quit)"

name_file="$(mktemp)"
env -i DESCRIPTION='Rust server'"${name}" \
       WORKING_DIR="${DEST}" \
       ENV="${ENV}" \
       EXEC_START="${EXEC_START}" \
      "$(which envsubst)" < "${LIBSCRIPT_ROOT_DIR}"'/_lib/_daemon/systemd/simple.service' > "${name_file}"
"${PRIV}" install -m 0644 -o 'root' -- "${name_file}" '/etc/systemd/system/'"${service_name}"'.service'

rm -- "${name_file}"

cd -- "${previous_wd}"
