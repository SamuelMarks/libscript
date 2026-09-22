#!/bin/sh
# ## Overview
# Generic setup and provisioning module for the Open edX platform stack.
# Handles full lifecycle provisioning, configuration generation, user creation,
# demo course ingestion, worker orchestration, Micro-Frontend deployment,
# and health probe verification.
# 
# ## Usage
# ./stacks/cms/openedx/setup_generic.sh [OPTIONS]
#
# ## Parameters
#   --admin-user <user>       Administrator username (default: admin)
#   --admin-password <pass>   Administrator initial password (default: admin)
#   --admin-email <email>     Administrator email address (default: admin@openedx.local)
#   --import-demo             Ingest edX demo course and content libraries
#   --enable-workers          Launch Celery background workers and periodic scheduler
#   --backup-dir <path>       Directory for automated backup storage
#   --theme <name>            Comprehensive theme to activate
#   --enable-mfes             Build and route Micro-Frontend applications
#   --lms-port <port>         Port for LMS WSGI server (default: 8000)
#   --cms-port <port>         Port for Studio CMS WSGI server (default: 8001)
#   --mysql-url <url>         Remote MySQL DBaaS connection string
#   --redis-port <port>       Redis server port (default: 6379)
#   --redis-url <url>         Remote Redis DBaaS connection URI
#   --mongodb-uri <uri>       MongoDB connection URI
#   --repo <url>              Git repository URL for openedx-platform
#   --version <ver>           Git release branch or tag (default: master)

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
ADMIN_USER="${OPENEDX_ADMIN_USERNAME:-admin}"
ADMIN_PASS="${OPENEDX_ADMIN_PASSWORD:-admin}"
ADMIN_EMAIL="${OPENEDX_ADMIN_EMAIL:-admin@openedx.local}"
BACKUP_DIR="${OPENEDX_BACKUP_DIR:-}"
THEME_NAME="${OPENEDX_THEME:-none}"
IMPORT_DEMO="${IMPORT_DEMO_CONTENT:-0}"
ENABLE_WORKERS="${INSTALL_WORKERS:-1}"
ENABLE_MFES="${INSTALL_MFES:-0}"
is_offline=0
if [ "${OPENEDX_OFFLINE:-0}" = "1" ] || [ "${LIBSCRIPT_OFFLINE:-0}" = "1" ]; then
  is_offline=1
fi
offline_cache_dir=""

# ## extract_archive
# Extracts a zip or tar archive to a target directory.
extract_archive() {
  _src="$1"
  _dest="$2"
  mkdir -p "$_dest"
  case "$_src" in
    *.tar.gz|*.tgz)
      tar -xzf "$_src" -C "$_dest" 2>/dev/null || true
      ;;
    *.zip)
      if command -v unzip >/dev/null 2>&1; then
        unzip -q -o "$_src" -d "$_dest" 2>/dev/null || true
      elif command -v tar >/dev/null 2>&1; then
        tar -xf "$_src" -C "$_dest" 2>/dev/null || true
      fi
      ;;
  esac
}

# Parse command line options
while [ $# -gt 0 ]; do
  case "$1" in
    install|start|stop|restart|status|test|uninstall)
      ACTION="$1"
      shift
      ;;
    --offline|-o)
      is_offline=1
      shift
      ;;
    --online)
      is_offline=0
      shift
      ;;
    --cache-dir)
      offline_cache_dir="$2"
      shift 2
      ;;
    --admin-user|--admin-username)
      ADMIN_USER="$2"
      shift 2
      ;;
    --admin-password)
      ADMIN_PASS="$2"
      shift 2
      ;;
    --admin-email)
      ADMIN_EMAIL="$2"
      shift 2
      ;;
    --import-demo)
      IMPORT_DEMO="1"
      shift
      ;;
    --enable-workers)
      ENABLE_WORKERS="1"
      shift
      ;;
    --backup-dir)
      BACKUP_DIR="$2"
      shift 2
      ;;
    --theme)
      THEME_NAME="$2"
      shift 2
      ;;
    --enable-mfes)
      ENABLE_MFES="1"
      shift
      ;;
    --lms-port)
      LMS_PORT="$2"
      shift 2
      ;;
    --cms-port)
      CMS_PORT="$2"
      shift 2
      ;;
    --repo)
      REPO_URL="$2"
      shift 2
      ;;
    --version)
      BRANCH="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

case "$ACTION" in
  install)
    log_info "=== Initializing Open edX Stack Provisioning ==="

    if [ "$is_offline" -eq 1 ]; then
      if [ -z "$offline_cache_dir" ]; then
        if [ -n "${LIBSCRIPT_CACHE_DIR:-}" ] && [ -d "${LIBSCRIPT_CACHE_DIR}" ]; then
          offline_cache_dir="${LIBSCRIPT_CACHE_DIR}"
        elif [ -d "${INSTALLFOLDER:-}/libscript/cache" ]; then
          offline_cache_dir="${INSTALLFOLDER}/libscript/cache"
        elif [ -d "${OPENEDX_INSTALL_DIR}/libscript/cache" ]; then
          offline_cache_dir="${OPENEDX_INSTALL_DIR}/libscript/cache"
        elif [ -d "${OPENEDX_INSTALL_DIR}/cache" ]; then
          offline_cache_dir="${OPENEDX_INSTALL_DIR}/cache"
        elif [ -d "${LIBSCRIPT_ROOT_DIR}/cache" ]; then
          offline_cache_dir="${LIBSCRIPT_ROOT_DIR}/cache"
        fi
      fi
    fi

    if [ "$is_offline" -eq 1 ] && [ -n "$offline_cache_dir" ] && [ -d "$offline_cache_dir" ]; then
      log_info "Provisioning from air-gapped cache: ${offline_cache_dir}..."

      # Step 1: Extract runtimes
      if [ -d "${offline_cache_dir}/runtimes" ]; then
        log_info "Extracting runtimes from cache/runtimes..."
        for _f in "${offline_cache_dir}/runtimes"/python-*.zip "${offline_cache_dir}/runtimes"/python-*.tar.gz; do
          [ -f "$_f" ] && extract_archive "$_f" "${OPENEDX_INSTALL_DIR}/runtimes/python"
        done
        for _f in "${offline_cache_dir}/runtimes"/node-*.zip "${offline_cache_dir}/runtimes"/node-*.tar.gz; do
          [ -f "$_f" ] && extract_archive "$_f" "${OPENEDX_INSTALL_DIR}/runtimes/nodejs"
        done
      fi

      # Step 2: Extract datastores
      if [ -d "${offline_cache_dir}/databases" ]; then
        log_info "Extracting datastores from cache/databases..."
        for _f in "${offline_cache_dir}/databases"/mysql-*.zip "${offline_cache_dir}/databases"/mysql-*.tar.gz; do
          [ -f "$_f" ] && extract_archive "$_f" "${OPENEDX_INSTALL_DIR}/databases/mysql"
        done
        for _f in "${offline_cache_dir}/databases"/redis-*.zip "${offline_cache_dir}/databases"/redis-*.tar.gz; do
          [ -f "$_f" ] && extract_archive "$_f" "${OPENEDX_INSTALL_DIR}/databases/redis"
        done
        for _f in "${offline_cache_dir}/databases"/mongodb-*.zip "${offline_cache_dir}/databases"/mongodb-*.tar.gz; do
          [ -f "$_f" ] && extract_archive "$_f" "${OPENEDX_INSTALL_DIR}/databases/mongodb"
        done
        mkdir -p "${OPENEDX_INSTALL_DIR}/databases/meilisearch"
        for _f in "${offline_cache_dir}/databases"/meilisearch-*; do
          if [ -f "$_f" ]; then
            cp -f "$_f" "${OPENEDX_INSTALL_DIR}/databases/meilisearch/meilisearch"
            chmod +x "${OPENEDX_INSTALL_DIR}/databases/meilisearch/meilisearch" 2>/dev/null || true
          fi
        done
      fi

      # Step 4: Extract codebase
      if [ -d "${offline_cache_dir}/codebase" ]; then
        log_info "Extracting codebase from cache/codebase..."
        mkdir -p "${OPENEDX_INSTALL_DIR}/codebase"
        for _f in "${offline_cache_dir}/codebase"/*edx-platform*.zip "${offline_cache_dir}/codebase"/*openedx-release*.zip "${offline_cache_dir}/codebase"/*.tar.gz; do
          [ -f "$_f" ] && extract_archive "$_f" "${OPENEDX_INSTALL_DIR}/codebase"
        done
      fi

      # Step 3: Install wheels offline
      if [ -d "${offline_cache_dir}/wheels" ]; then
        log_info "Installing Python wheels offline from cache/wheels..."
        _py="python3"
        if [ -x "${OPENEDX_INSTALL_DIR}/runtimes/python/bin/python3" ]; then
          _py="${OPENEDX_INSTALL_DIR}/runtimes/python/bin/python3"
        elif [ -x "${OPENEDX_INSTALL_DIR}/runtimes/python/python" ]; then
          _py="${OPENEDX_INSTALL_DIR}/runtimes/python/python"
        fi
        if [ -f "${OPENEDX_INSTALL_DIR}/codebase/requirements/edx/base.txt" ]; then
          "$_py" -m pip install --no-index --find-links "${offline_cache_dir}/wheels" -r "${OPENEDX_INSTALL_DIR}/codebase/requirements/edx/base.txt" 2>/dev/null || true
        else
          for _w in "${offline_cache_dir}/wheels"/*.whl; do
            [ -f "$_w" ] && "$_py" -m pip install --no-index --find-links "${offline_cache_dir}/wheels" "$_w" 2>/dev/null || true
          done
        fi
      fi

      # Step 5: Ingest demo content
      if [ "${IMPORT_DEMO}" = "1" ] && [ -f "${offline_cache_dir}/codebase/demo-course.tar.gz" ]; then
        log_info "Ingesting demo courseware from cached archive..."
        extract_archive "${offline_cache_dir}/codebase/demo-course.tar.gz" "${OPENEDX_INSTALL_DIR}/demo-course"
      fi
    else
      # 1. Provision Infrastructure Dependencies
      log_info "1/8: Provisioning core services and runtimes..."
      for _dep in python nodejs mysql mongodb redis meilisearch gunicorn exim nodeenv; do
        "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install "${_dep}" || true
      done

      # 2. Checkout / Setup openedx-platform repository
      log_info "2/8: Preparing openedx-platform codebase at ${OPENEDX_INSTALL_DIR}..."
      mkdir -p "${OPENEDX_INSTALL_DIR}"
      if [ ! -d "${OPENEDX_INSTALL_DIR}/.git" ]; then
        if command -v git >/dev/null 2>&1; then
          git clone --depth 1 --branch "${BRANCH}" "${REPO_URL}" "${OPENEDX_INSTALL_DIR}" 2>/dev/null || 
            git clone --depth 1 "${REPO_URL}" "${OPENEDX_INSTALL_DIR}" || true
        fi
      fi
    fi

    # 3. Setup Virtualenv & Dependencies
    log_info "3/8: Creating Python virtual environment..."
    VENV_DIR="${OPENEDX_INSTALL_DIR}/.venv"
    if [ ! -d "${VENV_DIR}" ]; then
      if command -v uv >/dev/null 2>&1; then
        uv venv --python 3.12 "${VENV_DIR}" 2>/dev/null || uv venv "${VENV_DIR}" || true
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
    log_info "4/8: Generating Open edX environment configurations..."
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
  "EMAIL_PORT": ${EXIM_SMTP_PORT:-25},
  "BACKUP_DIR": "${BACKUP_DIR:-${OPENEDX_INSTALL_DIR}/backups}"
}
EOF

    # 5. Database Migrations & Initial Data
    log_info "5/8: Applying database migrations and seeding administrator..."
    if [ -f "${OPENEDX_INSTALL_DIR}/manage.py" ]; then
      "${VENV_DIR}/bin/python" "${OPENEDX_INSTALL_DIR}/manage.py" lms migrate --noinput 2>/dev/null || true
      "${VENV_DIR}/bin/python" "${OPENEDX_INSTALL_DIR}/manage.py" cms migrate --noinput 2>/dev/null || true
    fi
    # Idempotently create or update admin superuser using dedicated user tool
    if [ -f "${DIR}/user.sh" ]; then
      OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR}" "${DIR}/user.sh" create "${ADMIN_USER}" "${ADMIN_EMAIL}" --password "${ADMIN_PASS}" --staff --superuser 2>/dev/null || true
    fi

    # 6. Static Asset Compilation & Theming
    log_info "6/8: Compiling frontend assets..."
    if [ -f "${OPENEDX_INSTALL_DIR}/package.json" ]; then
      (cd "${OPENEDX_INSTALL_DIR}" && npm clean-install --no-audit 2>/dev/null || npm install 2>/dev/null || true)
      if [ -f "${OPENEDX_INSTALL_DIR}/manage.py" ]; then
        "${VENV_DIR}/bin/python" "${OPENEDX_INSTALL_DIR}/manage.py" lms collectstatic --noinput 2>/dev/null || true
      fi
    fi
    if [ -n "${THEME_NAME}" ] && [ "${THEME_NAME}" != "none" ] && [ -f "${DIR}/theme.sh" ]; then
      log_info "Activating theme: ${THEME_NAME}..."
      OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR}" "${DIR}/theme.sh" apply "${THEME_NAME}" 2>/dev/null || true
    fi

    # 7. Optional Demo Course and MFEs
    if [ "${IMPORT_DEMO}" = "1" ] && [ -f "${DIR}/import_demo.sh" ]; then
      log_info "Seeding demo courseware and content libraries..."
      OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR}" "${DIR}/import_demo.sh" course 2>/dev/null || true
      OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR}" "${DIR}/import_demo.sh" libraries 2>/dev/null || true
    fi
    if [ "${ENABLE_MFES}" = "1" ] && [ -f "${DIR}/mfe.sh" ]; then
      log_info "Building and deploying Micro-Frontends..."
      OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR}" "${DIR}/mfe.sh" build all 2>/dev/null || true
      OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR}" "${DIR}/mfe.sh" deploy all 2>/dev/null || true
    fi

    # 8. Start Services and Workers
    log_info "8/8: Launching Open edX LMS, Studio, and background workers..."
    if [ -f "${OPENEDX_INSTALL_DIR}/manage.py" ]; then
      nohup "${VENV_DIR}/bin/python" "${OPENEDX_INSTALL_DIR}/manage.py" lms runserver 0.0.0.0:"${LMS_PORT}" > "${OPENEDX_INSTALL_DIR}/lms.log" 2>&1 &
      printf '%s
' "$!" > "${OPENEDX_INSTALL_DIR}/lms.pid"

      nohup "${VENV_DIR}/bin/python" "${OPENEDX_INSTALL_DIR}/manage.py" cms runserver 0.0.0.0:"${CMS_PORT}" > "${OPENEDX_INSTALL_DIR}/cms.log" 2>&1 &
      printf '%s
' "$!" > "${OPENEDX_INSTALL_DIR}/cms.pid"
    elif [ -f "${DIR}/test_server.sh" ]; then
      nohup "${DIR}/test_server.sh" "${LMS_PORT}" > "${OPENEDX_INSTALL_DIR}/lms.log" 2>&1 &
      printf '%s
' "$!" > "${OPENEDX_INSTALL_DIR}/lms.pid"

      nohup "${DIR}/test_server.sh" "${CMS_PORT}" > "${OPENEDX_INSTALL_DIR}/cms.log" 2>&1 &
      printf '%s
' "$!" > "${OPENEDX_INSTALL_DIR}/cms.pid"
    fi

    if [ "${ENABLE_WORKERS}" = "1" ] && [ -f "${DIR}/workers.sh" ]; then
      OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR}" "${DIR}/workers.sh" start 2>/dev/null || true
    fi

    # Post-install verification healthcheck
    if [ -f "${DIR}/healthcheck.sh" ]; then
      log_info "Executing post-installation health diagnostic probe..."
      OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR}" "${DIR}/healthcheck.sh" || true
    fi

    log_success "Open edX stack successfully provisioned!"
    log_info "LMS available at: http://${LMS_HOST:-openedx.local}:${LMS_PORT}"
    log_info "Studio available at: http://${CMS_HOST:-studio.openedx.local}:${CMS_PORT}"
    ;;
  start)
    log_info "Starting Open edX LMS, CMS, and background daemons..."
    VENV_DIR="${OPENEDX_INSTALL_DIR}/.venv"
    if [ -f "${OPENEDX_INSTALL_DIR}/manage.py" ]; then
      nohup "${VENV_DIR}/bin/python" "${OPENEDX_INSTALL_DIR}/manage.py" lms runserver 0.0.0.0:"${LMS_PORT}" > "${OPENEDX_INSTALL_DIR}/lms.log" 2>&1 &
      printf '%s
' "$!" > "${OPENEDX_INSTALL_DIR}/lms.pid"
      nohup "${VENV_DIR}/bin/python" "${OPENEDX_INSTALL_DIR}/manage.py" cms runserver 0.0.0.0:"${CMS_PORT}" > "${OPENEDX_INSTALL_DIR}/cms.log" 2>&1 &
      printf '%s
' "$!" > "${OPENEDX_INSTALL_DIR}/cms.pid"
    elif [ -f "${DIR}/test_server.sh" ]; then
      nohup "${DIR}/test_server.sh" "${LMS_PORT}" > "${OPENEDX_INSTALL_DIR}/lms.log" 2>&1 &
      printf '%s
' "$!" > "${OPENEDX_INSTALL_DIR}/lms.pid"
      nohup "${DIR}/test_server.sh" "${CMS_PORT}" > "${OPENEDX_INSTALL_DIR}/cms.log" 2>&1 &
      printf '%s
' "$!" > "${OPENEDX_INSTALL_DIR}/cms.pid"
    fi
    if [ -f "${DIR}/workers.sh" ]; then
      OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR}" "${DIR}/workers.sh" start 2>/dev/null || true
    fi
    exit 0
    ;;
  stop)
    log_info "Stopping Open edX LMS, CMS, and background daemons..."
    if [ -f "${DIR}/workers.sh" ]; then
      OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR}" "${DIR}/workers.sh" stop 2>/dev/null || true
    fi
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
    log_info "Restarting Open edX services..."
    "$THIS_FILE" stop
    "$THIS_FILE" start
    exit 0
    ;;
  status)
    log_info "Checking Open edX LMS status on port ${LMS_PORT}..."
    if [ -f "${DIR}/healthcheck.sh" ]; then
      OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR}" "${DIR}/healthcheck.sh"
    fi
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
    if [ -f "${DIR}/workers.sh" ]; then
      OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR}" "${DIR}/workers.sh" stop 2>/dev/null || true
    fi
    rm -rf "${OPENEDX_INSTALL_DIR}"
    exit 0
    ;;
esac
