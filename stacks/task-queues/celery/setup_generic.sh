#!/bin/sh
# ## Overview
# Provides a generic, cross-platform setup mechanism for the Celery task queue stack.
# 
# ## Usage
# Execute this script to perform generic initialization steps for celery.


set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
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

SCRIPT_NAME="${DIR}"'/env.sh'
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"

for LIB in "_lib/_common/log.sh" "_lib/_common/priv.sh" ${_LIBSCRIPT_DUMMY_NO_RUN:-}; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

if [ ! -x "${PYTHON_VENV}/bin/celery" ]; then
  _DIR="${DIR}"
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/languages/python/setup.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
  DIR="${_DIR}"

  priv  mkdir -p -- "${PYTHON_VENV}"
  _grp="${GROUP:-$(id -gn 2>/dev/null || echo "${USER}")}"
  if [ "$(uname -s)" = "Darwin" ]; then
    priv  chown -R -- "${USER}" "${PYTHON_VENV}"
  else
    priv  chown -R -- "${USER}":"${_grp}" "${PYTHON_VENV}"
  fi
  if command -v uv >/dev/null 2>&1; then
    uv venv --python "${PYTHON_VERSION}" -- "${PYTHON_VENV}"
    uv pip install --python "${PYTHON_VENV}" celery
  else
    python3 -m venv "${PYTHON_VENV}"
    "${PYTHON_VENV}/bin/python" -m pip install celery
  fi
fi

if [ -d '/etc/systemd/system' ]; then
  CELERY_SERVICE_USER="${CELERY_SERVICE_USER:-celery}"
  if ! id "${CELERY_SERVICE_USER}" >/dev/null 2>&1; then
    if command -v useradd >/dev/null 2>&1; then
      priv useradd -m -d '/home/'"${CELERY_SERVICE_USER}"'/' -c '' "${CELERY_SERVICE_USER}"
    else
      priv adduser --disabled-password --gecos '' --home '/home/'"${CELERY_SERVICE_USER}"'/' "${CELERY_SERVICE_USER}"
    fi
  else
    if command -v usermod >/dev/null 2>&1; then
      priv usermod -d '/home/'"${CELERY_SERVICE_USER}"'/' "${CELERY_SERVICE_USER}" 2>/dev/null || true
    fi
    priv mkdir -p '/home/'"${CELERY_SERVICE_USER}"'/'
    priv chown "${CELERY_SERVICE_USER}" '/home/'"${CELERY_SERVICE_USER}"'/' 2>/dev/null || true
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
elif [ -d '/etc/init.d' ] && command -v rc-service >/dev/null 2>&1; then
  # OpenRC
  service_name="${LIBSCRIPT_SERVICE_NAME:-celery}"
  log_info "Registering OpenRC service for ${service_name}..."
  rc-service "${service_name}" restart 2>/dev/null || true
elif [ -d '/usr/local/etc/rc.d' ]; then
  # FreeBSD
  service_name="${LIBSCRIPT_SERVICE_NAME:-celery}"
  log_info "Configuring FreeBSD rc.d service for ${service_name}..."
  if command -v sysrc >/dev/null 2>&1; then
    sysrc "${service_name}_enable=YES" || true
  fi
elif [ "${TARGET_OS:-}" = "sunos" ] || [ "$(uname -s)" = "SunOS" ]; then
  # SunOS / OmniOS
  service_name="${LIBSCRIPT_SERVICE_NAME:-celery}"
  log_info "Celery installed successfully on SunOS."
  exit 0
elif [ -d '/Library/LaunchDaemons' ]; then
  >&2 printf 'TODO: macOS service\n'
  exit 0
else
  "${PYTHON_VENV}"'/bin/celery' worker -A "${CELERY_APP:-openedx}" -c "${CELERY_CONCURRENCY:-2}" &
fi
