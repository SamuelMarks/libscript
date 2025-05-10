#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE+x}" ]; then
  this_file="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION+x}" ]; then
  this_file="${(%):-%x}"
  set -o pipefail
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

if [ "${FIRECRAWL_DEST-}" ]; then
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

if [ "${VARS-}" ]; then
  object2key_val "${VARS}" 'export ' "'" >> "${LIBSCRIPT_DATA_DIR}"'/dyn_env.sh'
  object2key_val "${VARS}" 'setenv ' "'" >> "${LIBSCRIPT_DATA_DIR}"'/dyn_env.csh'
fi
ENV=''
if [ -f "${LIBSCRIPT_DATA_DIR}"'/dyn_env.sh' ]; then
  chmod +x "${LIBSCRIPT_DATA_DIR}"'/dyn_env.sh'
  ENV="$(cut -c8- "${LIBSCRIPT_DATA_DIR}"'/dyn_env.sh' | awk -- '{arr[i++]=$0} END {while (i>0) print arr[--i] }' | tr -d "'" | awk -F= '!seen[$1]++' | xargs printf 'Environment="%s"\n')"
fi

if [ -d '/etc/systemd/system' ]; then
  name_file="$(mktemp)"
  trap 'rm -f -- "${name_file}"' EXIT HUP INT QUIT TERM
  service_name='firecrawl_workers'
  env -i DESCRIPTION='Firecrawl workers' \
         ENV="${ENV}" \
         WORKING_DIR="${DEST}"'/apps/api' \
         EXEC_START="$(which pnpm)"' run workers' \
        "$(which envsubst)" < "${LIBSCRIPT_ROOT_DIR}"'/_lib/_daemon/systemd/simple.service' > "${name_file}"
  priv  install -m 0644 -o 'root' -- "${name_file}" '/etc/systemd/system/'"${service_name}"'.service'
  priv  systemctl daemon-reload
  priv  systemctl reload-or-restart -- "${service_name}"

  name_file="$(mktemp)"
  trap 'rm -f -- "${name_file}"' EXIT HUP INT QUIT TERM
  service_name='firecrawl_serve'
  env -i DESCRIPTION='Firecrawl serve' \
         ENV="${ENV}" \
         WORKING_DIR="${DEST}"'/apps/api' \
         EXEC_START="$(which pnpm)"' run start' \
        "$(which envsubst)" < "${LIBSCRIPT_ROOT_DIR}"'/_lib/_daemon/systemd/simple.service' > "${name_file}"
  priv  install -m 0644 -o 'root' -- "${name_file}" '/etc/systemd/system/'"${service_name}"'.service'
  priv  systemctl daemon-reload
  priv  systemctl reload-or-restart -- "${service_name}"
fi

cd -- "${previous_wd}"
