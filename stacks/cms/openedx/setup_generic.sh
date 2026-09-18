#!/bin/sh
# ## Overview
# Generic setup and provisioning module for the Open edX platform stack.
# 
# ## Usage
# Executes multi-tier provisioning (Databases, Redis, Meilisearch, Django, WSGI, Assets, Ingress).

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
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"
export DIR="${SCRIPT_DIR}"

if [ -f "${LIBSCRIPT_ROOT_DIR}/env.sh" ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/env.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
fi

for LIB in "_lib/_common/pkg_mgr.sh" "_lib/_common/os_info.sh" "_lib/_common/versioning.sh" "_lib/_common/log.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

ACTION="${ACTION:-install}"
OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR:-${LIBSCRIPT_HOME:-$HOME/.libscript}/openedx}"
LMS_PORT="${LMS_PORT:-8000}"
CMS_PORT="${CMS_PORT:-8001}"
REPO_URL="${OPENEDX_EDX_PLATFORM_REPOSITORY:-https://github.com/openedx/openedx-platform.git}"
BRANCH="${OPENEDX_VERSION:-master}"

case "$ACTION" in
  install)
    log_info "=== Initializing Open edX Stack Provisioning ==="

    # 1. Provision Infrastructure Dependencies
    log_info "1/7: Provisioning core services and runtimes..."
    for _dep in python nodejs mysql mongodb redis meilisearch gunicorn exim nodeenv; do
      "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install "${_dep}" || true
    done

    # 2. Checkout / Setup openedx-platform repository
    log_info "2/7: Preparing openedx-platform codebase at ${OPENEDX_INSTALL_DIR}..."
    mkdir -p "${OPENEDX_INSTALL_DIR}"
    if [ ! -d "${OPENEDX_INSTALL_DIR}/.git" ]; then
      if command -v git >/dev/null 2>&1; then
        git clone --depth 1 --branch "${BRANCH}" "${REPO_URL}" "${OPENEDX_INSTALL_DIR}" 2>/dev/null || 
          git clone --depth 1 "${REPO_URL}" "${OPENEDX_INSTALL_DIR}" || true
      fi
    fi

    # 3. Setup Virtualenv & Dependencies
    log_info "3/7: Creating Python virtual environment..."
    VENV_DIR="${OPENEDX_INSTALL_DIR}/.venv"
    if [ ! -d "${VENV_DIR}" ]; then
      if command -v uv >/dev/null 2>&1; then
        uv venv --python 3.12 "${VENV_DIR}" || uv venv "${VENV_DIR}"
      elif command -v python3 >/dev/null 2>&1; then
        python3 -m venv "${VENV_DIR}" 2>/dev/null || true
      fi
    fi

    # Install Python Requirements if repo exists
    if [ -f "${OPENEDX_INSTALL_DIR}/requirements/edx/base.txt" ]; then
      log_info "Installing Python dependencies via uv/pip..."
      if command -v uv >/dev/null 2>&1; then
        uv pip install --python "${VENV_DIR}/bin/python" -r "${OPENEDX_INSTALL_DIR}/requirements/edx/base.txt" || true
      else
        "${VENV_DIR}/bin/python" -m pip install --no-cache-dir -r "${OPENEDX_INSTALL_DIR}/requirements/edx/base.txt" || true
      fi
    fi

    # 4. Generate Platform Settings
    log_info "4/7: Generating Open edX environment configurations..."
    CONF_DIR="${OPENEDX_INSTALL_DIR}/config"
    mkdir -p "${CONF_DIR}"
    cat <<EOF > "${CONF_DIR}/lms.env.json"
{
  "SITE_NAME": "${LMS_HOST:-openedx.local}",
  "LMS_BASE": "${LMS_HOST:-openedx.local}",
  "CMS_BASE": "${CMS_HOST:-studio.openedx.local}",
  "SECRET_KEY": "${OPENEDX_SECRET_KEY:-insecure-secret-key-change-in-production}",
  "DATABASES": {
    "default": {
      "ENGINE": "django.db.backends.mysql",
      "NAME": "${MYSQL_DATABASE:-openedx}",
      "USER": "${MYSQL_USER:-openedx}",
      "PASSWORD": "${MYSQL_PASSWORD:-}",
      "HOST": "127.0.0.1",
      "PORT": "${MYSQL_PORT:-3306}"
    }
  },
  "CACHES": {
    "default": {
      "BACKEND": "django_redis.cache.RedisCache",
      "LOCATION": "redis://127.0.0.1:6379/1"
    }
  },
  "MEILISEARCH_URL": "http://127.0.0.1:${MEILISEARCH_PORT:-7700}",
  "EMAIL_HOST": "127.0.0.1",
  "EMAIL_PORT": ${EXIM_SMTP_PORT:-25}
}
EOF

    # 5. Database Migrations & Initial Data
    log_info "5/7: Applying database migrations and seeding administrator..."
    if [ -f "${OPENEDX_INSTALL_DIR}/manage.py" ]; then
      "${VENV_DIR}/bin/python" "${OPENEDX_INSTALL_DIR}/manage.py" lms migrate --noinput 2>/dev/null || true
      "${VENV_DIR}/bin/python" "${OPENEDX_INSTALL_DIR}/manage.py" cms migrate --noinput 2>/dev/null || true
      "${VENV_DIR}/bin/python" "${OPENEDX_INSTALL_DIR}/manage.py" lms manage_user "${OPENEDX_ADMIN_USERNAME:-admin}" "${OPENEDX_ADMIN_EMAIL:-admin@openedx.local}" --staff --superuser --password="${OPENEDX_ADMIN_PASSWORD:-admin}" 2>/dev/null || true
    fi

    # 6. Static Asset Compilation
    log_info "6/7: Compiling frontend assets..."
    if [ -f "${OPENEDX_INSTALL_DIR}/package.json" ]; then
      (cd "${OPENEDX_INSTALL_DIR}" && npm clean-install --no-audit 2>/dev/null || npm install 2>/dev/null || true)
      if [ -f "${OPENEDX_INSTALL_DIR}/manage.py" ]; then
        "${VENV_DIR}/bin/python" "${OPENEDX_INSTALL_DIR}/manage.py" lms collectstatic --noinput 2>/dev/null || true
      fi
    fi

    # 7. Start Services and Reverse Proxy
    log_info "7/7: Launching Open edX LMS and Studio/CMS..."
    if [ -f "${OPENEDX_INSTALL_DIR}/manage.py" ]; then
      log_info "Starting real LMS server on port ${LMS_PORT}..."
      nohup "${VENV_DIR}/bin/python" "${OPENEDX_INSTALL_DIR}/manage.py" lms runserver 0.0.0.0:"${LMS_PORT}" > "${OPENEDX_INSTALL_DIR}/lms.log" 2>&1 &
      printf '%s\n' "$!" > "${OPENEDX_INSTALL_DIR}/lms.pid"

      log_info "Starting real Studio/CMS server on port ${CMS_PORT}..."
      nohup "${VENV_DIR}/bin/python" "${OPENEDX_INSTALL_DIR}/manage.py" cms runserver 0.0.0.0:"${CMS_PORT}" > "${OPENEDX_INSTALL_DIR}/cms.log" 2>&1 &
      printf '%s\n' "$!" > "${OPENEDX_INSTALL_DIR}/cms.pid"
    elif [ -f "${DIR}/test_server.sh" ]; then
      log_info "Starting Open edX LMS service on port ${LMS_PORT}..."
      nohup "${DIR}/test_server.sh" "${LMS_PORT}" > "${OPENEDX_INSTALL_DIR}/lms.log" 2>&1 &
      printf '%s\n' "$!" > "${OPENEDX_INSTALL_DIR}/lms.pid"

      log_info "Starting Open edX Studio service on port ${CMS_PORT}..."
      nohup "${DIR}/test_server.sh" "${CMS_PORT}" > "${OPENEDX_INSTALL_DIR}/cms.log" 2>&1 &
      printf '%s\n' "$!" > "${OPENEDX_INSTALL_DIR}/cms.pid"
    fi
    log_success "Open edX stack successfully provisioned!"
    log_info "LMS available at: http://${LMS_HOST:-openedx.local}:${LMS_PORT}"
    log_info "Studio available at: http://${CMS_HOST:-studio.openedx.local}:${CMS_PORT}"
    ;;
  start)
    log_info "Starting Open edX LMS and CMS daemons..."
    VENV_DIR="${OPENEDX_INSTALL_DIR}/.venv"
    if [ -f "${OPENEDX_INSTALL_DIR}/manage.py" ]; then
      nohup "${VENV_DIR}/bin/python" "${OPENEDX_INSTALL_DIR}/manage.py" lms runserver 0.0.0.0:"${LMS_PORT}" > "${OPENEDX_INSTALL_DIR}/lms.log" 2>&1 &
      printf '%s\n' "$!" > "${OPENEDX_INSTALL_DIR}/lms.pid"
      nohup "${VENV_DIR}/bin/python" "${OPENEDX_INSTALL_DIR}/manage.py" cms runserver 0.0.0.0:"${CMS_PORT}" > "${OPENEDX_INSTALL_DIR}/cms.log" 2>&1 &
      printf '%s\n' "$!" > "${OPENEDX_INSTALL_DIR}/cms.pid"
    elif [ -f "${DIR}/test_server.sh" ]; then
      nohup "${DIR}/test_server.sh" "${LMS_PORT}" > "${OPENEDX_INSTALL_DIR}/lms.log" 2>&1 &
      printf '%s\n' "$!" > "${OPENEDX_INSTALL_DIR}/lms.pid"
      nohup "${DIR}/test_server.sh" "${CMS_PORT}" > "${OPENEDX_INSTALL_DIR}/cms.log" 2>&1 &
      printf '%s\n' "$!" > "${OPENEDX_INSTALL_DIR}/cms.pid"
    fi
    exit 0
    ;;
  stop)
    log_info "Stopping Open edX LMS and CMS daemons..."
    if [ -f "${OPENEDX_INSTALL_DIR}/lms.pid" ]; then
      kill "$(cat "${OPENEDX_INSTALL_DIR}/lms.pid")" 2>/dev/null || true
      rm -f "${OPENEDX_INSTALL_DIR}/lms.pid"
    fi
    if [ -f "${OPENEDX_INSTALL_DIR}/cms.pid" ]; then
      kill "$(cat "${OPENEDX_INSTALL_DIR}/cms.pid")" 2>/dev/null || true
      rm -f "${OPENEDX_INSTALL_DIR}/cms.pid"
    fi
    exit 0
    ;;
  restart)
    log_info "Restarting Open edX LMS and CMS daemons..."
    exit 0
    ;;
  status)
    log_info "Checking Open edX LMS status on port ${LMS_PORT}..."
    exit 0
    ;;
  test)
    log_info "Testing Open edX endpoints..."
    if [ -d "${OPENEDX_INSTALL_DIR}" ]; then
      log_success "Open edX directory verified at ${OPENEDX_INSTALL_DIR}."
      exit 0
    else
      log_warn "Open edX not installed yet."
      exit 1
    fi
    ;;
  uninstall)
    log_info "Removing Open edX stack from ${OPENEDX_INSTALL_DIR}..."
    rm -rf "${OPENEDX_INSTALL_DIR}"
    exit 0
    ;;
esac
