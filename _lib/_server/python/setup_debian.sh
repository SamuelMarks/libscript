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
LIBSCRIPT_DATA_DIR="${LIBSCRIPT_DATA_DIR:-${TMPDIR:-/tmp}/libscript_data}"

for lib in 'env.sh' '_lib/_common/environ.sh' '_lib/_common/pkg_mgr.sh' '_lib/_git/git.sh' '_lib/_toolchain/python/setup.sh'; do
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

if [ ! -z "${VARS+x}" ]; then
  object2key_val "${VARS}" 'export ' "'" >> "${LIBSCRIPT_DATA_DIR}"'/dyn_env.sh'
fi
ENV=''
if [ -f "${LIBSCRIPT_DATA_DIR}"'/dyn_env.sh' ]; then
  chmod +x "${LIBSCRIPT_DATA_DIR}"'/dyn_env.sh'
  ENV="$(cut -c8- "${LIBSCRIPT_DATA_DIR}"'/dyn_env.sh' | awk -- '{arr[i++]=$0} END {while (i>0) print arr[--i] }' | tr -d "'" | awk -F= '!seen[$1]++' | xargs printf 'Environment="%s"\n')"
fi
#EXEC_START="$(pwd)"'/'"$(find target/release -depth -maxdepth 1 -type f -executable -print -quit)"
# TODO: Check if there a main in `setup.py` or `pyproject.toml` or `setup.cfg` then parse out that
cwd="$(pwd)"
script=''
for _script in 'main.py' 'app.py' 'start.py' 'server.py' \
               'src/main.py' 'src/app.py' 'src/start.py' 'src/server.py' \
               "${service_name}"'/main.py' "${service_name}"'/app.py' \
               "${service_name}"'/start.py' "${service_name}"'/server.py'; do
  __script="${cwd}"'/'"${_script}"
  if [ -f "${__script}" ]; then
    script="${__script}"
    break
  fi
done
if [ ! -n "${script}" ]; then
  >&2 printf 'No idea how to start Python script for daemon\n'
  >&2 printf '%s contains: %s\n' "$(pwd)" "$(ls)"
  exit 2
fi
# TODO: Should check PYTHONPATH VENV and other env vars first
if [ ! -z "${VENV+x}" ]; then
  true
else
  python_out="$(mktemp)"
  trap 'rm -f -- "${python_out}"' EXIT HUP INT QUIT TERM
  if which python > "${python_out}" ; then
    python_executable="$(cat -- "${python_out}"; printf 'a')"
    python_executable="${python_executable%a}"
  else
    python_executable="$(find "$(pwd)" -name python -executable)"
  fi
fi
if [ "${python_executable}" = '' ]; then
  >&2 printf 'python_executable could not be found, only got "%s"\n' "${python_executable}"
  exit 2
fi
EXEC_START="${python_executable}"' "'"${script}"'"'
name_file="$(mktemp)"
trap 'rm -f -- "${name_file}"' EXIT HUP INT QUIT TERM
env -i DESCRIPTION='Python server'"${name}" \
       WORKING_DIR="${DEST}" \
       ENV="${ENV}" \
       EXEC_START="${EXEC_START}" \
       "$(which envsubst)" < "${LIBSCRIPT_ROOT_DIR}"'/_lib/_daemon/systemd/simple.service' > "${name_file}"
priv  install -m 0644 -o 'root' -- "${name_file}" '/etc/systemd/system/'"${service_name}"'.service'

cd -- "${previous_wd}"
