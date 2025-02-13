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

for lib in 'env.sh' '_lib/_common/pkg_mgr.sh' '_lib/_toolchain/nodejs/setup.sh' '_lib/_git/git.sh'; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

SCRIPT_NAME="${DIR}"'/env.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

if [ ! -z "${FIRECRAWL_DEST+x}" ]; then
  DEST="${FIRECRAWL_DEST}"
elif [ -z "${DEST+x}" ]; then
  rand="$(env LC_CTYPE='C' tr -cd '[:lower:]' < '/dev/urandom' | head -c 8)"
  DEST="${LIBSCRIPT_DATA_DIR}"'/'"${rand}"
  export DEST
  mkdir -p -- "${DEST}"
fi

if ! cmd_avail pnpm; then
  npm install -g pnpm@latest-10
fi

previous_wd="$(pwd)"
git_get https://github.com/mendableai/firecrawl "${DEST}"
cd -- "${DEST}"

hash="$(git rev-list HEAD -1)"
hash_loc="${DEST}"'/apps/api/node_modules/'"${hash}"
if [ ! -f "${hash_loc}" ]; then
  touch -- "${hash_loc}"
  cd -- apps/api
  pnpm install
  cd -- "${DEST}"
fi

if [ ! -z "${VARS+x}" ]; then
  object2key_val "${VARS}" 'export ' "'" >> "${LIBSCRIPT_DATA_DIR}"'/dyn_env.sh'
fi
ENV=''
if [ -f "${LIBSCRIPT_DATA_DIR}"'/dyn_env.sh' ]; then
  chmod +x "${LIBSCRIPT_DATA_DIR}"'/dyn_env.sh'
  ENV="$(cut -c8- "${LIBSCRIPT_DATA_DIR}"'/dyn_env.sh' | awk '{arr[i++]=$0} END {while (i>0) print arr[--i] }' | tr -d "'" | awk -F= '!seen[$1]++' | xargs printf 'Environment="%s"\n')"
fi

if [ -d '/etc/systemd/system' ]; then
  name_file="$(mktemp)"
  service_name='firecrawl_workers'
  env -i DESCRIPTION='Firecrawl workers' \
         ENV="${ENV}" \
         WORKING_DIR="${DEST}"'/apps/api' \
         EXEC_START="$(which pnpm)"' run workers' \
        "$(which envsubst)" < "${LIBSCRIPT_ROOT_DIR}"'/_lib/_daemon/systemd/simple.service' > "${name_file}"
  "${PRIV}" install -m 0644 -o 'root' -- "${name_file}" '/etc/systemd/system/'"${service_name}"'.service'
  "${PRIV}" systemctl daemon-reload
  "${PRIV}" systemctl reload-or-restart -- "${service_name}"

  rm "${name_file}"

  name_file="$(mktemp)"
  service_name='firecrawl_serve'
  env -i DESCRIPTION='Firecrawl serve' \
         ENV="${ENV}" \
         WORKING_DIR="${DEST}"'/apps/api' \
         EXEC_START="$(which pnpm)"' run start' \
        "$(which envsubst)" < "${LIBSCRIPT_ROOT_DIR}"'/_lib/_daemon/systemd/simple.service' > "${name_file}"
  "${PRIV}" install -m 0644 -o 'root' -- "${name_file}" '/etc/systemd/system/'"${service_name}"'.service'
  "${PRIV}" systemctl daemon-reload
  "${PRIV}" systemctl reload-or-restart -- "${service_name}"
fi

cd -- "${previous_wd}"
