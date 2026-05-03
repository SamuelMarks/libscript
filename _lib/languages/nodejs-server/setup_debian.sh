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
LIBSCRIPT_DATA_DIR="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"

for LIB in '_lib/_common/environ.sh' '_lib/_common/pkg_mgr.sh' '_lib/git-servers/git.sh' '_lib/languages/nodejs/setup.sh'; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
# shellcheck disable=SC1090,SC1091,SC2034
  . "${SCRIPT_NAME}"
done

PREVIOUS_WD="$(pwd)"
SERVICE_NAME=''
if [ -z "${DEST+x}" ]; then
  RAND="$(env LC_CTYPE='C' tr -cd '[:lower:]' < '/dev/urandom' | head -c 8)"
  DEST="${LIBSCRIPT_DATA_DIR}"'/'"${RAND}"
  export DEST
  mkdir -p -- "${DEST}"
  SERVICE_NAME='rust-'"${RAND}"
  touch "${DEST}/main.js"
else
  SERVICE_NAME="$(basename -- "${DEST}")"
fi
NAME=' '"${SERVICE_NAME}"
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
CWD="$(pwd)"
SCRIPT=''
for _script in 'main.js' 'app.js' 'start.js' 'src/main.js' 'src/app.js' 'src/start.js'; do
  __SCRIPT="${CWD}"'/'"${_script}"
  if [ -f "${__SCRIPT}" ]; then
    SCRIPT="${__SCRIPT}"
    break
  fi
done
if [ ! "${SCRIPT-}" ]; then
  >&2 printf 'No idea how to start Node.js script for daemon\n'
  >&2 printf '%s contains: %s\n' "$(pwd)" "$(ls)"
  exit 2
fi
EXEC_START="$(which node)"' "'"${SCRIPT}"'"'
NAME_FILE="$(mktemp)"
trap 'rm -f -- "${NAME_FILE}"' EXIT HUP INT QUIT TERM
env -i DESCRIPTION='Node.js server'"${NAME}" \
        WORKING_DIR="${DEST}" \
        ENV="${ENV}" \
        EXEC_START="${EXEC_START}" \
      "$(which envsubst)" < "${LIBSCRIPT_ROOT_DIR}"'/_lib/init-systems/systemd/simple.service' > "${NAME_FILE}"
priv  install -m 0644 -o 'root' -- "${NAME_FILE}" '/etc/systemd/system/'"${SERVICE_NAME}"'.service'

cd -- "${PREVIOUS_WD}"

if [ -n "${NODEJS_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET:-}}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "unix:${NODEJS_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET}}" >/dev/null 2>&1 ; then
    true
  fi
elif [ -n "${NODEJS_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS:-}}" ] && [ -n "${NODEJS_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "${NODEJS_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS}}:${NODEJS_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 ; then
    true
  fi
elif [ -n "${NODEJS_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "${NODEJS_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 ; then
    true
  fi
fi
