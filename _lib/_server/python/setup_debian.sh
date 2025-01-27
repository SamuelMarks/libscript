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

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/env.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/common.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_git/git.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_toolchain/nodejs/setup.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

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

if [ -f 'package.json' ]; then
  npm i
fi

ENV=''
if [ -f "${LIBSCRIPT_DATA_DIR}"'/dyn_env.sh' ]; then
  ENV="$(cut -c8- "${LIBSCRIPT_DATA_DIR}"'/dyn_env.sh' | tr -d "'" | sort -u | xargs printf 'Environment="%s"\n')"
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
python_out="$(mktemp)"
if which python > "${python_out}" ; then
  python_executable="$(cat -- "${python_out}"; printf 'a')"
  python_executable="${python_executable%a}"
  >&2 printf 'taking from cat\n'
  rm -- "${python_out}"
else
  python_executable="$(find "$(pwd)" -name python -executable)"
fi
if [ "${python_executable}" = '' ]; then
  >&2 printf 'python_executable could not be found, only got "%s"\n' "${python_executable}"
  exit 2
fi
EXEC_START="${python_executable}"' "'"${script}"'"'
name_file="$(mktemp)"
env -i DESCRIPTION='Python server'"${name}" \
       WORKING_DIR="${DEST}" \
       ENV="${ENV}" \
       EXEC_START="${EXEC_START}" \
       "$(which envsubst)" < "${LIBSCRIPT_ROOT_DIR}"'/_lib/_daemon/systemd/simple.service' > "${name_file}"
"${PRIV}" install -m 0644 -o 'root' -- "${name_file}" '/etc/systemd/system/'"${service_name}"'.service'

rm -- "${name_file}"

cd -- "${previous_wd}"
