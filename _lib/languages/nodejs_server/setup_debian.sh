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

DIR=$(CDPATH='' cd -- "$(dirname -- "${this_file}")" && pwd)

LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$(d="${DIR}"; while [ ! -f "${d}"'/ROOT' ]; do d="$(dirname -- "${d}")"; done; printf '%s' "${d}")}"
LIBSCRIPT_DATA_DIR="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"

for lib in '_lib/_common/environ.sh' '_lib/_common/pkg_mgr.sh' '_lib/git-servers/git.sh' '_lib/languages/nodejs/setup.sh'; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
# shellcheck disable=SC1090,SC1091,SC2034
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
  touch "${DEST}/main.js"
else
  service_name="$(basename -- "${DEST}")"
fi
name=' '"${service_name}"
cd -- "${DEST}"

if [ -f 'package.json' ]; then
  if [ -f 'yarn.lock' ]; then
    yarn
  elif [ -f 'pnpm-lock.yaml' ]; then
    pnpm install
  else
    npm i
  fi
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
#EXEC_START="$(pwd)"'/'"$(find target/release -depth -maxdepth 1 -type f -executable -print -quit)"
# TODO: Check if there's a start for `npm start` then parse out that
cwd="$(pwd)"
script=''
for _script in 'main.js' 'app.js' 'start.js' 'src/main.js' 'src/app.js' 'src/start.js'; do
  __script="${cwd}"'/'"${_script}"
  if [ -f "${__script}" ]; then
    script="${__script}"
    break
  fi
done
if [ ! "${script-}" ]; then
  >&2 printf 'No idea how to start Node.js script for daemon\n'
  >&2 printf '%s contains: %s\n' "$(pwd)" "$(ls)"
  exit 2
fi
EXEC_START="$(which node)"' "'"${script}"'"'
name_file="$(mktemp)"
trap 'rm -f -- "${name_file}"' EXIT HUP INT QUIT TERM
env -i DESCRIPTION='Node.js server'"${name}" \
       WORKING_DIR="${DEST}" \
       ENV="${ENV}" \
       EXEC_START="${EXEC_START}" \
      "$(which envsubst)" < "${LIBSCRIPT_ROOT_DIR}"'/_lib/init-systems/systemd/simple.service' > "${name_file}"
priv  install -m 0644 -o 'root' -- "${name_file}" '/etc/systemd/system/'"${service_name}"'.service'

cd -- "${previous_wd}"

if [ -n "${NODEJS_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET:-}}" ]; then
  "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "unix:${NODEJS_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET}}" >/dev/null 2>&1 || true
elif [ -n "${NODEJS_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS:-}}" ] && [ -n "${NODEJS_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
  "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "${NODEJS_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS}}:${NODEJS_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 || true
elif [ -n "${NODEJS_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
  "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "${NODEJS_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 || true
fi
