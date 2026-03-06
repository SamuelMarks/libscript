#!/bin/sh
# shellcheck disable=SC2016,SC1090,SC1091,SC2034,SC2018,SC2019,SC2221,SC2222,SC2129,SC2209,SC2089,SC2090,SC2086,SC2154,SC2044,SC2181,SC2038,SC2155,SC2046,SC2002,SC1003,SC2295,SC2145



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

SCRIPT_NAME="${DIR}"'/env.sh'
export SCRIPT_NAME
. "${SCRIPT_NAME}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/priv.sh'
export SCRIPT_NAME
. "${SCRIPT_NAME}"

if [ ! -d "${PYTHON_VENV}" ]; then
  _DIR="${DIR}"
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_toolchain/python/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
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
  if [ ! -d '/home/celery/' ]; then
  CELERY_SERVICE_USER="${CELERY_SERVICE_USER:-celery}"
    priv mkdir -p -- '/var/run/celery' '/var/log/celery'
    if command -v useradd >/dev/null 2>&1; then
      priv useradd -m -d '/home/'"${CELERY_SERVICE_USER}"'/' -c '' "${CELERY_SERVICE_USER}"
    else
      priv adduser --disabled-password --gecos '' --home '/home/'"${CELERY_SERVICE_USER}"'/' "${CELERY_SERVICE_USER}"
    fi
    if [ "$(uname -s)" = "Darwin" ]; then
      priv chown -R -- "${CELERY_SERVICE_USER}" '/var/run/celery' '/var/log/celery' "${PYTHON_VENV}"
    else
      priv chown -R -- "${CELERY_SERVICE_USER}":"${CELERY_SERVICE_USER}" '/var/run/celery' '/var/log/celery' "${PYTHON_VENV}"
    fi
  fi

  service_name="${LIBSCRIPT_SERVICE_NAME:-celery}"
  service='/etc/systemd/system/'"${service_name}"'.service'
  envsubst < "${DIR}"'/conf/systemd/celery.service' > '/tmp/'"${service_name}"

  priv  install -m 0644 -- '/tmp/'"${service_name}" "${service}"
  priv mkdir -p /etc/conf.d
  priv install -D -m 0644 -- "${DIR}"'/conf/celery_env' /etc/conf.d/"${service_name}"
  priv systemctl daemon-reload || true
  priv systemctl reload-or-restart -- "${service_name}" || true
elif [ -d '/Library/LaunchDaemons' ]; then
  >&2 printf 'TODO: macOS service\n'
  exit 0
else
  "${PYTHON_VENV}"'/bin/celery' &
fi
