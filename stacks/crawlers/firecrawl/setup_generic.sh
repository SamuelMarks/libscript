#!/bin/sh
# ## Overview
# Provides a generic, cross-platform setup mechanism for the Firecrawl crawler stack.
# 
# ## Usage
# Execute this script to perform generic initialization steps for firecrawl.


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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
_DIR="${SCRIPT_DIR}"

for LIB in '_lib/_common/pkg_mgr.sh' '_lib/languages/nodejs/setup.sh' '_lib/git-servers/utils/git.sh'; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  # shellcheck source=/dev/null
# shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

DIR="${_DIR}"
SCRIPT_NAME="${DIR}"'/env.sh'
export SCRIPT_NAME
# shellcheck source=/dev/null
# shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"

if [ "${FIRECRAWL_DEST-}" ]; then
  DEST="${FIRECRAWL_DEST}"
elif [ -z "${DEST+x}" ]; then
  if [ -f "${LIBSCRIPT_DATA_DIR}/.firecrawl_dest" ]; then
    DEST="$(cat "${LIBSCRIPT_DATA_DIR}/.firecrawl_dest")"
  else
    rand="$(env LC_CTYPE='C' tr -cd '[:lower:]' < '/dev/urandom' | head -c 8)"
    DEST="${LIBSCRIPT_DATA_DIR}"'/'"${rand}"
    mkdir -p -- "${LIBSCRIPT_DATA_DIR}"
    printf '%s\n' "${DEST}" > "${LIBSCRIPT_DATA_DIR}/.firecrawl_dest"
  fi
  export DEST
  mkdir -p -- "${DEST}"
fi

if ! libscript_cmd_avail pnpm; then
  priv npm install -g pnpm@latest-10
fi

git_get https://github.com/mendableai/firecrawl "${DEST}"

HASH="$(cd -- "${DEST}" && git rev-list HEAD -1)"
HASH_LOC="${DEST}"'/apps/api/node_modules/'"${HASH}"
if [ ! -f "${HASH_LOC}" ]; then
  mkdir -p -- "$(dirname -- "${HASH_LOC}")"
  touch -- "${HASH_LOC}"
  (
    cd -- "${DEST}/apps/api" || exit 1
    pnpm install
  )
fi

if [ "${VARS-}" ]; then
  libscript_object2key_val "${VARS}" 'export ' "'" > "${LIBSCRIPT_DATA_DIR}"'/dyn_env.sh'
  libscript_object2key_val "${VARS}" 'setenv ' "'" > "${LIBSCRIPT_DATA_DIR}"'/dyn_env.csh'
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
          EXEC_START="$(command -v pnpm)"' run workers' \
        "$(command -v envsubst)" < "${LIBSCRIPT_ROOT_DIR}"'/_lib/init-systems/systemd/simple.service' > "${name_file}"
  priv  install -m 0644 -o 'root' -- "${name_file}" '/etc/systemd/system/'"${service_name}"'.service'
  if ! priv systemctl daemon-reload ; then
    true
  fi
  if ! priv systemctl reload-or-restart -- "${service_name}" ; then
    true
  fi

  name_file="$(mktemp)"
  trap 'rm -f -- "${name_file}"' EXIT HUP INT QUIT TERM
  service_name='firecrawl_serve'
  env -i DESCRIPTION='Firecrawl serve' \
          ENV="${ENV}" \
          WORKING_DIR="${DEST}"'/apps/api' \
          EXEC_START="$(command -v pnpm)"' run start' \
        "$(command -v envsubst)" < "${LIBSCRIPT_ROOT_DIR}"'/_lib/init-systems/systemd/simple.service' > "${name_file}"
  priv  install -m 0644 -o 'root' -- "${name_file}" '/etc/systemd/system/'"${service_name}"'.service'
  if ! priv systemctl daemon-reload ; then
    true
  fi
  if ! priv systemctl reload-or-restart -- "${service_name}" ; then
    true
  fi
fi
