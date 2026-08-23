#!/bin/sh
# ## Overview
# Provides specialized installation and configuration logic for a Rust Server on Debian/Ubuntu systems.
# It initializes a Cargo binary project if needed, compiles it in release mode, generates
# environment variable injections, builds a Systemd service file targeting the compiled binary,
# installs it, and registers listening ports via `netctl`.
# 
# ## Usage
# Typically called automatically by `setup.sh` when running on a Debian-like operating system.


set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  eval 'THIS_FILE="${BASH_SOURCE[0]}"'
  eval 'set -o pipefail'
elif [ "${ZSH_VERSION-}" ]; then
  eval 'THIS_FILE="${(%):-%x}"'
  eval 'set -o pipefail'
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
export DIR="${SCRIPT_DIR}"
LIBSCRIPT_DATA_DIR="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"

for LIB in "_lib/_common/environ.sh" "_lib/_common/pkg_mgr.sh" \
            "_lib/git-servers/git.sh" "_lib/languages/rust/setup.sh" "_lib/_common/envsubst_safe.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

PREVIOUS_WD="$(pwd)"
SERVICE_NAME=''
if [ -z "${DEST+x}" ]; then
  if [ -f "${LIBSCRIPT_DATA_DIR}/.rust_server_dest" ]; then
    DEST="$(cat "${LIBSCRIPT_DATA_DIR}/.rust_server_dest")"
    RAND="$(basename -- "${DEST}")"
  else
    RAND="$(env LC_CTYPE='C' tr -cd '[:lower:]' < '/dev/urandom' | head -c 8)"
    DEST="${LIBSCRIPT_DATA_DIR}"'/'"${RAND}"
    mkdir -p -- "${LIBSCRIPT_DATA_DIR}"
    printf '%s\n' "${DEST}" > "${LIBSCRIPT_DATA_DIR}/.rust_server_dest"
  fi
  export DEST
  mkdir -p -- "${RUST_SERVER_DEST}"
  SERVICE_NAME='rust-'"${RAND}"
else
  SERVICE_NAME="$(basename -- "${RUST_SERVER_DEST}")"
fi
NAME=' '"${SERVICE_NAME}"
cd -- "${RUST_SERVER_DEST}"
# shellcheck disable=SC1090,SC1091
. "${HOME}"'/.cargo/env'

[ -f Cargo.toml ] || cargo init --bin
cargo build --release

if [ "${RUST_SERVER_VARS-}" ]; then
  if [ -f "${LIBSCRIPT_DATA_DIR}/dyn_env.sh" ]; then
    tmp_env=$(mktemp)
    libscript_object2key_val "${RUST_SERVER_VARS}" 'export ' "'" | awk -F= '{print $1}' | while read -r key_prefix; do
      key=$(printf '%s\n' "${key_prefix}" | awk '{print $2}')
      grep -v "^export ${key}=" "${LIBSCRIPT_DATA_DIR}/dyn_env.sh" > "${tmp_env}" || true
      cat "${tmp_env}" > "${LIBSCRIPT_DATA_DIR}/dyn_env.sh"
    done
  fi
  if [ -f "${LIBSCRIPT_DATA_DIR}/dyn_env.csh" ]; then
    tmp_env=$(mktemp)
    libscript_object2key_val "${RUST_SERVER_VARS}" 'setenv ' "'" | awk '{print $2}' | while read -r key; do
      grep -v "^setenv ${key} " "${LIBSCRIPT_DATA_DIR}/dyn_env.csh" > "${tmp_env}" || true
      cat "${tmp_env}" > "${LIBSCRIPT_DATA_DIR}/dyn_env.csh"
    done
    rm -f "${tmp_env}"
  fi
  libscript_object2key_val "${RUST_SERVER_VARS}" 'export ' "'" >> "${LIBSCRIPT_DATA_DIR}"'/dyn_env.sh'
  libscript_object2key_val "${RUST_SERVER_VARS}" 'setenv ' "'" >> "${LIBSCRIPT_DATA_DIR}"'/dyn_env.csh'
fi
ENV=''
if [ -f "${LIBSCRIPT_DATA_DIR}"'/dyn_env.sh' ]; then
  chmod +x "${LIBSCRIPT_DATA_DIR}"'/dyn_env.sh'
  ENV="$(cut -c8- "${LIBSCRIPT_DATA_DIR}"'/dyn_env.sh' | awk -- '{arr[i++]=$0} END {while (i>0) print arr[--i] }' | tr -d "'" | awk -F= '!seen[$1]++' | xargs printf 'Environment="%s"\n')"
fi
EXEC_START="$(pwd)"'/'"$(find target/release -depth -maxdepth 1 -type f -executable -print -quit)"

NAME_FILE="$(mktemp)"
trap 'rm -f -- "${NAME_FILE}"' EXIT HUP INT QUIT TERM
env -i DESCRIPTION='Rust server'"${NAME}" \
        WORKING_DIR="${RUST_SERVER_DEST}" \
        ENV="${ENV}" \
        EXEC_START="${EXEC_START}" \
        "$(command -v envsubst)" < "${LIBSCRIPT_ROOT_DIR}"'/_lib/init-systems/systemd/simple.service' > "${NAME_FILE}"
priv  install -m 0644 -o 'root' -- "${NAME_FILE}" '/etc/systemd/system/'"${SERVICE_NAME}"'.service'

cd -- "${PREVIOUS_WD}"

if [ -n "${RUST_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET:-}}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "unix:${RUST_LISTEN_SOCKET:-${LIBSCRIPT_LISTEN_SOCKET}}" >/dev/null 2>&1 ; then
    true
  fi
elif [ -n "${RUST_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS:-}}" ] && [ -n "${RUST_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "${RUST_LISTEN_ADDRESS:-${LIBSCRIPT_LISTEN_ADDRESS}}:${RUST_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 ; then
    true
  fi
elif [ -n "${RUST_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT:-}}" ]; then
  if ! "${LIBSCRIPT_ROOT_DIR}/netctl/netctl.sh" --listen "${RUST_LISTEN_PORT:-${LIBSCRIPT_LISTEN_PORT}}" >/dev/null 2>&1 ; then
    true
  fi
fi
