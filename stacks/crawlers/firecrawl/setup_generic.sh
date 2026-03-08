#!/bin/sh
# shellcheck disable=SC3054,SC3040,SC2296,SC2128,SC2039,SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145



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

_DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${_DIR}"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"

for lib in '_lib/_common/pkg_mgr.sh' '_lib/languages/nodejs/setup.sh' '_lib/git-servers/git.sh'; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  # shellcheck source=/dev/null
# shellcheck disable=SC1090,SC1091,SC2034
  . "${SCRIPT_NAME}"
done

DIR="${_DIR}"
SCRIPT_NAME="${DIR}"'/env.sh'
export SCRIPT_NAME
# shellcheck source=/dev/null
# shellcheck disable=SC1090,SC1091,SC2034
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
  priv npm install -g pnpm@latest-10
fi

previous_wd="$(pwd)"
git_get https://github.com/mendableai/firecrawl "${DEST}"
cd -- "${DEST}"

hash="$(git rev-list HEAD -1)"
hash_loc="${DEST}"'/apps/api/node_modules/'"${hash}"
if [ ! -f "${hash_loc}" ]; then
  mkdir -p -- "$(dirname -- "${hash_loc}")"
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
        "$(which envsubst)" < "${LIBSCRIPT_ROOT_DIR}"'/_lib/init-systems/systemd/simple.service' > "${name_file}"
  priv  install -m 0644 -o 'root' -- "${name_file}" '/etc/systemd/system/'"${service_name}"'.service'
  priv systemctl daemon-reload || true
  priv systemctl reload-or-restart -- "${service_name}" || true

  name_file="$(mktemp)"
  trap 'rm -f -- "${name_file}"' EXIT HUP INT QUIT TERM
  service_name='firecrawl_serve'
  env -i DESCRIPTION='Firecrawl serve' \
         ENV="${ENV}" \
         WORKING_DIR="${DEST}"'/apps/api' \
         EXEC_START="$(which pnpm)"' run start' \
        "$(which envsubst)" < "${LIBSCRIPT_ROOT_DIR}"'/_lib/init-systems/systemd/simple.service' > "${name_file}"
  priv  install -m 0644 -o 'root' -- "${name_file}" '/etc/systemd/system/'"${service_name}"'.service'
  priv systemctl daemon-reload || true
  priv systemctl reload-or-restart -- "${service_name}" || true
fi

cd -- "${previous_wd}"
