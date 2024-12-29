#!/bin/sh

realpath -- "${0}"
set -x
guard='H_'"$(realpath -- "${0}" | sed 's/[^a-zA-Z0-9_]/_/g')"
if env | grep -qF "${guard}"'=1'; then return ; fi
export "${guard}"=1
if [ -n "${ZSH_VERSION}" ] || [ -n "${BASH_VERSION}" ]; then
  set -xeuo pipefail
fi

SCRIPT_ROOT_DIR="${SCRIPT_ROOT_DIR:-$( dirname -- "$( dirname -- "$( dirname -- "${0}" )" )" )}"

# shellcheck disable=SC1091
. "${SCRIPT_ROOT_DIR}"'/conf.env.sh'

if [ ! -d "${PYTHON_VENV}" ]; then
  # shellcheck disable=SC1091
  . "${SCRIPT_ROOT_DIR}"'/_lib/_toolchain/python/setup.sh'

  uv venv --python "${PYTHON_VERSION}" "${PYTHON_VENV}"
fi

if [ -d '/etc/systemd/system' ]; then
  if [ ! -d '/home/celery/' ]; then
    mkdir -p /var/run/celery /var/log/celery
    adduser "${JUPYTER_NOTEBOOK_SERVICE_USER}" --home '/home/'"${JUPYTER_NOTEBOOK_SERVICE_USER}"'/' --gecos ''
    chown -R celery:celery /var/run/celery /var/log/celery
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
  >&2 echo 'TODO: macOS service'
  exit 3
else
  "${PYTHON_VENV}"'/bin/celery' &
fi
