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
export DIR

SCRIPT_ROOT_DIR="${SCRIPT_ROOT_DIR:-$(d="$(CDPATH='' cd -- "$(dirname -- "$(dirname -- "$( dirname -- "${DIR}" )" )" )")"; if [ -d "${d}" ]; then echo "${d}"; else echo './'"${d}"; fi)}"

SCRIPT_NAME="${SCRIPT_ROOT_DIR}"'/conf.env.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

SCRIPT_NAME="${SCRIPT_ROOT_DIR}"'/_lib/_common/priv.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

if [ ! -d "${PYTHON_VENV}" ]; then
  SCRIPT_NAME="${SCRIPT_ROOT_DIR}"'/_lib/_toolchain/python/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"

  "${PRIV}" mkdir -p -- "${PYTHON_VENV}"
  "${PRIV}" chown -R -- "${USER}":"${GROUP}" "${PYTHON_VENV}"
  uv venv --python "${PYTHON_VERSION}" -- "${PYTHON_VENV}"
fi

if [ -d '/etc/systemd/system' ]; then
  if [ ! -d '/home/celery/' ]; then
    mkdir -p '/var/run/celery' '/var/log/celery'
    adduser "${JUPYTERHUB_SERVICE_USER}" --home '/home/'"${JUPYTERHUB_SERVICE_USER}"'/' --gecos ''
    chown -R -- celery:celery '/var/run/celery' '/var/log/celery' "${PYTHON_VENV}"
  fi

  service_name='celery'
  service='/etc/systemd/system/'"${service_name}"'.service'
  envsubst < "${DIR}"'/conf/systemd/celery.service' > '/tmp/'"${service_name}"
  "${PRIV}" mv '/tmp/'"${service_name}" "${service}"
  "${PRIV}" chmod 0644 "${service}"
  "${PRIV}" mkdir -p /etc/conf.d/
  "${PRIV}" cp "${DIR}"'/conf/celery_env' /etc/conf.d/
  "${PRIV}" systemctl stop "${service_name}" || true
  "${PRIV}" systemctl daemon-reload
  "${PRIV}" systemctl start "${service_name}"
elif [ -d '/Library/LaunchDaemons' ]; then
  >&2 printf 'TODO: macOS service\n'
  exit 3
else
  "${PYTHON_VENV}"'/bin/celery' &
fi
