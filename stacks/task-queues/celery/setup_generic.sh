#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
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

SCRIPT_NAME="${DIR}"'/env.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091,SC2034
. "${SCRIPT_NAME}"

for lib in '_lib/_common/priv.sh' ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${lib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

if [ ! -d "${PYTHON_VENV}" ]; then
  _DIR="${DIR}"
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/languages/python/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
# shellcheck disable=SC1090,SC1091,SC2034
  . "${SCRIPT_NAME}"
  DIR="${_DIR}"

  priv  mkdir -p -- "${PYTHON_VENV}"
  if [ "$(uname -s)" = "Darwin" ]; then
    priv  chown -R -- "${USER}" "${PYTHON_VENV}"
  else
    priv  chown -R -- "${USER}":"${GROUP:-${USER}}" "${PYTHON_VENV}"
  fi
  uv venv --python "${PYTHON_VERSION}" -- "${PYTHON_VENV}"
  uv pip install --python "${PYTHON_VENV}" celery
fi

if [ -d '/etc/systemd/system' ]; then
  CELERY_SERVICE_USER="${CELERY_SERVICE_USER:-celery}"
  if ! id "${CELERY_SERVICE_USER}" >/dev/null 2>&1; then
    if command -v useradd >/dev/null 2>&1; then
      priv useradd -m -d '/home/'"${CELERY_SERVICE_USER}"'/' -c '' "${CELERY_SERVICE_USER}"
    else
      priv adduser --disabled-password --gecos '' --home '/home/'"${CELERY_SERVICE_USER}"'/' "${CELERY_SERVICE_USER}"
    fi
  fi
  priv mkdir -p -- '/var/run/celery' '/var/log/celery'
  if [ "$(uname -s)" = "Darwin" ]; then
    priv chown -R -- "${CELERY_SERVICE_USER}" '/var/run/celery' '/var/log/celery' "${PYTHON_VENV}"
  else
    priv chown -R -- "${CELERY_SERVICE_USER}":"${CELERY_SERVICE_USER}" '/var/run/celery' '/var/log/celery' "${PYTHON_VENV}"
  fi

  service_name="${LIBSCRIPT_SERVICE_NAME:-celery}"
  service='/etc/systemd/system/'"${service_name}"'.service'
  envsubst < "${DIR}"'/conf/systemd/celery.service' > '/tmp/'"${service_name}"

  priv  install -m 0644 -- '/tmp/'"${service_name}" "${service}"
  priv mkdir -p /etc/conf.d
  priv install -D -m 0644 -- "${DIR}"'/conf/celery_env' /etc/conf.d/"${service_name}"
  if ! priv systemctl daemon-reload ; then
    true
  fi
  if ! priv systemctl reload-or-restart -- "${service_name}" ; then
    true
  fi
elif [ -d '/Library/LaunchDaemons' ]; then
  >&2 printf 'TODO: macOS service\n'
  exit 0
else
  "${PYTHON_VENV}"'/bin/celery' &
fi
