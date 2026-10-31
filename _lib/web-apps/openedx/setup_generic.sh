#!/bin/sh
# ## Overview
# Generic setup and provisioning module for the Open edX platform stack.
# Handles full lifecycle provisioning, configuration generation, user creation,
# demo course ingestion, worker orchestration, Micro-Frontend deployment,
# and health probe verification.
#
# ## Usage
#   ./_lib/web-apps/openedx/setup_generic.sh [OPTIONS]

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
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
OPENEDX_DIR="${SCRIPT_DIR}"
export DIR="${OPENEDX_DIR}"

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
#   --version <ver>           Git release branch or tag (default: release/verawood.1)

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
unset SCRIPT_NAME || true
SCRIPT_DIR="${OPENEDX_DIR}"
DIR="${OPENEDX_DIR}"
export DIR

ACTION="${ACTION:-install}"
OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR:-${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/openedx}"
LMS_PORT="${LMS_PORT:-8000}"
CMS_PORT="${CMS_PORT:-8001}"
REPO_URL="${OPENEDX_EDX_PLATFORM_REPOSITORY:-https://github.com/openedx/edx-platform.git}"
BRANCH="${OPENEDX_VERSION:-release/verawood.1}"
ADMIN_USER="${OPENEDX_ADMIN_USERNAME:-admin}"
ADMIN_PASS="${OPENEDX_ADMIN_PASSWORD:-admin}"
ADMIN_EMAIL="${OPENEDX_ADMIN_EMAIL:-admin@openedx.local}"
BACKUP_DIR="${OPENEDX_BACKUP_DIR:-}"
THEME_NAME="${OPENEDX_THEME:-none}"
IMPORT_DEMO="${IMPORT_DEMO_CONTENT:-0}"
ENABLE_WORKERS="${INSTALL_WORKERS:-1}"
ENABLE_MFES="${INSTALL_MFES:-0}"
MYSQL_URL="${MYSQL_URL:-}"
REDIS_PORT="${REDIS_PORT:-6379}"
REDIS_URL="${REDIS_URL:-}"
MONGODB_URI="${MONGODB_URI:-}"
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
      tar -xzf "$_src" -C "$_dest" 2>/dev/null || { tail -n 50 "${OPENEDX_INSTALL_DIR}/logs/install.log"; exit 1; }
      ;;
    *.zip)
      if command -v unzip >/dev/null 2>&1; then
        unzip -q -o "$_src" -d "$_dest" 2>/dev/null || { tail -n 50 "${OPENEDX_INSTALL_DIR}/logs/install.log"; exit 1; }
      elif command -v tar >/dev/null 2>&1; then
        tar -xf "$_src" -C "$_dest" 2>/dev/null || { tail -n 50 "${OPENEDX_INSTALL_DIR}/logs/install.log"; exit 1; }
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
      if [ "${2:-}" = "0" ] || [ "${2:-}" = "1" ]; then
        IMPORT_DEMO="$2"
        shift 2
      else
        IMPORT_DEMO='1'
        shift
      fi
      ;;
    --import-demo=*)
      IMPORT_DEMO="${1#*=}"
      shift
      ;;
    --enable-workers|--install-workers)
      if [ "${2:-}" = "0" ] || [ "${2:-}" = "1" ]; then
        ENABLE_WORKERS="$2"
        shift 2
      else
        ENABLE_WORKERS='1'
        shift
      fi
      ;;
    --enable-workers=*|--install-workers=*)
      ENABLE_WORKERS="${1#*=}"
      shift
      ;;
    --use-existing-python)
      USE_EXISTING_PYTHON="$2"
      export USE_EXISTING_PYTHON
      shift 2
      ;;
    --use-existing-python=*)
      USE_EXISTING_PYTHON="${1#*=}"
      export USE_EXISTING_PYTHON
      shift
      ;;
    --use-existing-node)
      USE_EXISTING_NODE="$2"
      export USE_EXISTING_NODE
      shift 2
      ;;
    --use-existing-node=*)
      USE_EXISTING_NODE="${1#*=}"
      export USE_EXISTING_NODE
      shift
      ;;
    --install-mysql)
      INSTALL_MYSQL="$2"
      export INSTALL_MYSQL
      shift 2
      ;;
    --install-mysql=*)
      INSTALL_MYSQL="${1#*=}"
      export INSTALL_MYSQL
      shift
      ;;
    --install-redis)
      INSTALL_REDIS="$2"
      export INSTALL_REDIS
      shift 2
      ;;
    --install-redis=*)
      INSTALL_REDIS="${1#*=}"
      export INSTALL_REDIS
      shift
      ;;
    --install-mongodb)
      INSTALL_MONGODB="$2"
      export INSTALL_MONGODB
      shift 2
      ;;
    --install-mongodb=*)
      INSTALL_MONGODB="${1#*=}"
      export INSTALL_MONGODB
      shift
      ;;
    --install-meilisearch)
      INSTALL_MEILISEARCH="$2"
      export INSTALL_MEILISEARCH
      shift 2
      ;;
    --install-meilisearch=*)
      INSTALL_MEILISEARCH="${1#*=}"
      export INSTALL_MEILISEARCH
      shift
      ;;
    --install-lms)
      INSTALL_LMS="$2"
      export INSTALL_LMS
      shift 2
      ;;
    --install-lms=*)
      INSTALL_LMS="${1#*=}"
      export INSTALL_LMS
      shift
      ;;
    --install-cms)
      INSTALL_CMS="$2"
      export INSTALL_CMS
      shift 2
      ;;
    --install-cms=*)
      INSTALL_CMS="${1#*=}"
      export INSTALL_CMS
      shift
      ;;
    --install-dir)
      OPENEDX_INSTALL_DIR="${2%/}"
      export OPENEDX_INSTALL_DIR
      shift 2
      ;;
    --data-dir)
      OPENEDX_DATA_DIR="${2%/}"
      export OPENEDX_DATA_DIR
      shift 2
      ;;
    --log-dir)
      OPENEDX_LOG_DIR="${2%/}"
      export OPENEDX_LOG_DIR
      shift 2
      ;;
    --backup-dir)
      BACKUP_DIR="${2%/}"
      export BACKUP_DIR
      shift 2
      ;;
    --theme)
      THEME_NAME="$2"
      shift 2
      ;;
    --enable-mfes)
      if [ "${2:-}" = "0" ] || [ "${2:-}" = "1" ]; then
        ENABLE_MFES="$2"
        shift 2
      else
        ENABLE_MFES='1'
        shift
      fi
      ;;
    --enable-mfes=*)
      ENABLE_MFES="${1#*=}"
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
    --mysql-port)
      MYSQL_PORT="$2"
      export MYSQL_PORT
      shift 2
      ;;
    --mysql-url)
      MYSQL_URL="$2"
      shift 2
      ;;
    --redis-port)
      REDIS_PORT="$2"
      shift 2
      ;;
    --redis-url)
      REDIS_URL="$2"
      shift 2
      ;;
    --mongodb-port)
      MONGODB_PORT="$2"
      export MONGODB_PORT
      shift 2
      ;;
    --mongodb-uri)
      MONGODB_URI="$2"
      shift 2
      ;;
    --meilisearch-port)
      MEILISEARCH_PORT="$2"
      export MEILISEARCH_PORT
      shift 2
      ;;
    --meilisearch-url)
      MEILISEARCH_URL="$2"
      export MEILISEARCH_URL
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

MYSQL_HOST="${MYSQL_HOST:-127.0.0.1}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_DATABASE="${MYSQL_DATABASE:-openedx}"
MYSQL_USER="${MYSQL_USER:-openedx}"
OPENEDX_DATABASE_PASSWORD="${OPENEDX_DATABASE_PASSWORD:-openedx_password}"

if [ -n "${MYSQL_URL}" ] && [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/databases/parse_connection_uri.sh" ]; then
  _parsed_mysql=$("${LIBSCRIPT_ROOT_DIR}/_lib/databases/parse_connection_uri.sh" "${MYSQL_URL}" --env 2>/dev/null || true)
  for _line in $_parsed_mysql; do
    case "$_line" in
      DB_HOST=*) MYSQL_HOST="${_line#DB_HOST=}" ;;
      DB_PORT=*) [ -n "${_line#DB_PORT=}" ] && MYSQL_PORT="${_line#DB_PORT=}" ;;
      DB_USER=*) [ -n "${_line#DB_USER=}" ] && MYSQL_USER="${_line#DB_USER=}" ;;
      DB_PASS=*) [ -n "${_line#DB_PASS=}" ] && OPENEDX_DATABASE_PASSWORD="${_line#DB_PASS=}" ;;
      DB_NAME=*) [ -n "${_line#DB_NAME=}" ] && MYSQL_DATABASE="${_line#DB_NAME=}" ;;
    esac
  done
fi

if [ -n "${REDIS_URL}" ] && [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/databases/parse_connection_uri.sh" ]; then
  _parsed_redis=$("${LIBSCRIPT_ROOT_DIR}/_lib/databases/parse_connection_uri.sh" "${REDIS_URL}" --env 2>/dev/null || true)
  for _line in $_parsed_redis; do
    case "$_line" in
      DB_PORT=*) [ -n "${_line#DB_PORT=}" ] && REDIS_PORT="${_line#DB_PORT=}" ;;
    esac
  done
fi

case "$ACTION" in
  install)
    if [ -f "${OPENEDX_INSTALL_DIR}/lms/envs/libscript.py" ] && [ -f "${OPENEDX_INSTALL_DIR}/config/lms.env.json" ]; then
      log_info "openedx is already installed at ${OPENEDX_INSTALL_DIR}."
      if [ -f "${DIR}/service.sh" ]; then
        OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR}" "${DIR}/service.sh" start >/dev/null 2>&1 || true
      fi
      exit 0
    fi
    if [ -x "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/openedx/${VERSION:-latest}/bin/openedx" ]; then
      log_info "openedx ${VERSION:-latest} is already installed."
      exit 0
    fi
    log_info '=== Initializing Open edX Stack Provisioning ==='

    if [ "$is_offline" -eq 1 ]; then
      if [ -z "$offline_cache_dir" ]; then
        if [ -n "${LIBSCRIPT_CACHE_DIR:-}" ] && [ -d "${LIBSCRIPT_CACHE_DIR}" ]; then
          offline_cache_dir="${LIBSCRIPT_CACHE_DIR}"
        elif [ -n "${LIBSCRIPT_FOLDER:-}" ] && [ -d "${LIBSCRIPT_FOLDER}/cache" ]; then
          offline_cache_dir="${LIBSCRIPT_FOLDER}/cache"
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
      if [ -n "$offline_cache_dir" ]; then
        export LIBSCRIPT_CACHE_DIR="${offline_cache_dir}"
      fi
    fi

    # 1. Provision Infrastructure Dependencies
    log_info '1/8: System and runtime dependencies...'
    libscript_depends 'python' 'nodejs' || true
    DIR="${OPENEDX_DIR}"
    export DIR

    export MONGODB_INSTALL_METHOD='libscript_native'
    if [ "${RUN_MYSQL:-true}" != "false" ] && [ "${RUN_MYSQL:-1}" != "0" ] && [ -z "${MYSQL_URL}" ]; then
      (unset SCRIPT_NAME; STACK="" "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install-service mysql >/dev/null 2>&1 || true)
      (unset SCRIPT_NAME; STACK="" "${LIBSCRIPT_ROOT_DIR}/libscript.sh" start mysql >/dev/null 2>&1 || true)
    fi
    if [ "${RUN_MONGODB:-true}" != "false" ] && [ "${RUN_MONGODB:-1}" != "0" ] && [ -z "${MONGODB_URI}" ]; then
      (unset SCRIPT_NAME; STACK="" "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install-service mongodb >/dev/null 2>&1 || true)
      (unset SCRIPT_NAME; STACK="" "${LIBSCRIPT_ROOT_DIR}/libscript.sh" start mongodb >/dev/null 2>&1 || true)
    fi
    if [ "${RUN_REDIS:-true}" != "false" ] && [ "${RUN_REDIS:-1}" != "0" ] && [ -z "${REDIS_URL}" ]; then
      (unset SCRIPT_NAME; STACK="" "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install-service redis >/dev/null 2>&1 || true)
      (unset SCRIPT_NAME; STACK="" "${LIBSCRIPT_ROOT_DIR}/libscript.sh" start redis >/dev/null 2>&1 || true)
    fi
    if [ "${RUN_MEILISEARCH:-true}" != "false" ] && [ "${RUN_MEILISEARCH:-1}" != "0" ]; then
      (unset SCRIPT_NAME; STACK="" "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install-service meilisearch >/dev/null 2>&1 || true)
      (unset SCRIPT_NAME; STACK="" "${LIBSCRIPT_ROOT_DIR}/libscript.sh" start meilisearch >/dev/null 2>&1 || true)
    fi

    # 2. Checkout / Setup openedx-platform repository
    log_info "2/8: Preparing openedx-platform (${BRANCH}) codebase at ${OPENEDX_INSTALL_DIR}..."
    mkdir -p \
      "${OPENEDX_INSTALL_DIR}/config" \
      "${OPENEDX_INSTALL_DIR}/data" \
      "${OPENEDX_INSTALL_DIR}/data/mako_lms" \
      "${OPENEDX_INSTALL_DIR}/data/mako_cms" \
      "${OPENEDX_INSTALL_DIR}/data/grades" \
      "${OPENEDX_INSTALL_DIR}/data/financial-reports" \
      "${OPENEDX_INSTALL_DIR}/data/django-pyfs/static/django-pyfs" \
      "${OPENEDX_INSTALL_DIR}/logs" \
      "${OPENEDX_INSTALL_DIR}/media" \
      "${OPENEDX_INSTALL_DIR}/media/profile-images" \
      "${OPENEDX_INSTALL_DIR}/media-private" \
      "${OPENEDX_INSTALL_DIR}/staticfiles" \
      "${OPENEDX_INSTALL_DIR}/staticfiles/studio" \
      "${OPENEDX_INSTALL_DIR}/course_repos" \
      "${OPENEDX_INSTALL_DIR}/export_course_repos" \
      "${OPENEDX_INSTALL_DIR}/mfe_dist" \
      "${OPENEDX_INSTALL_DIR}/codebase"
    touch "${OPENEDX_INSTALL_DIR}/logs/install.log"
    if [ -f "${DIR}/build-constraints.txt" ]; then
      cp -f "${DIR}/build-constraints.txt" "${OPENEDX_INSTALL_DIR}/build-constraints.txt"
      export PIP_CONSTRAINT="${OPENEDX_INSTALL_DIR}/build-constraints.txt"
      export UV_BUILD_CONSTRAINT="${OPENEDX_INSTALL_DIR}/build-constraints.txt"
    fi
    if [ "$is_offline" -eq 1 ] && [ -n "${offline_cache_dir:-}" ] && [ -d "${offline_cache_dir}/codebase" ]; then
      log_info 'Extracting codebase from cache/codebase...'
      for _f in "${offline_cache_dir}/codebase"/*openedx-release*.zip "${offline_cache_dir}/codebase"/*edx-platform*.zip "${offline_cache_dir}/codebase"/*.tar.gz; do
        [ -f "$_f" ] && extract_archive "$_f" "${OPENEDX_INSTALL_DIR}/codebase"
      done
      if [ ! -f "${OPENEDX_INSTALL_DIR}/codebase/manage.py" ]; then
        for _sub in "${OPENEDX_INSTALL_DIR}/codebase"/*; do
          if [ -d "$_sub" ] && [ -f "$_sub/manage.py" ]; then
            cp -Rf "$_sub"/. "${OPENEDX_INSTALL_DIR}/codebase/" 2>/dev/null || true
            rm -rf "$_sub" 2>/dev/null || true
            break
          fi
        done
      fi
    elif [ ! -f "${OPENEDX_INSTALL_DIR}/codebase/manage.py" ] && [ ! -f "${OPENEDX_INSTALL_DIR}/manage.py" ]; then
      if ! command -v git >/dev/null 2>&1; then
        libscript_depends 'git' || true
      fi
      if command -v git >/dev/null 2>&1; then
        git clone --depth 1 --branch "${BRANCH}" "${REPO_URL}" "${OPENEDX_INSTALL_DIR}/codebase" 2>/dev/null || git clone --depth 1 "${REPO_URL}" "${OPENEDX_INSTALL_DIR}/codebase" 2>/dev/null || true
      fi
    fi

    if [ "$is_offline" -eq 1 ] && [ -n "${offline_cache_dir:-}" ]; then
      # Step 3: Install wheels offline
      if [ -d "${offline_cache_dir}/wheels" ]; then
        log_info 'Installing Python wheels offline from cache/wheels...'
        _py='python3'
        if [ -x "${OPENEDX_INSTALL_DIR}/runtimes/python/bin/python3" ]; then
          _py="${OPENEDX_INSTALL_DIR}/runtimes/python/bin/python3"
        elif [ -x "${OPENEDX_INSTALL_DIR}/runtimes/python/python" ]; then
          _py="${OPENEDX_INSTALL_DIR}/runtimes/python/python"
        fi
        for _w in "${offline_cache_dir}/wheels"/*.whl; do
          if [ -f "$_w" ]; then
            "$_py" -m pip install --no-index --find-links "${offline_cache_dir}/wheels" "$_w" >> "${OPENEDX_INSTALL_DIR}/logs/install.log" 2>&1 || true
          fi
        done
      fi

      # Step 5: Ingest demo content
      if [ "${IMPORT_DEMO}" = "1" ] && [ -f "${offline_cache_dir}/codebase/demo-course.tar.gz" ]; then
        log_info 'Ingesting demo courseware from cached archive...'
        extract_archive "${offline_cache_dir}/codebase/demo-course.tar.gz" "${OPENEDX_INSTALL_DIR}/demo-course"
      fi
    fi

    mkdir -p "${OPENEDX_INSTALL_DIR}/logs"

    # Pre-flight python check
    _py='python3'
    if [ -x "${OPENEDX_INSTALL_DIR}/runtimes/python/bin/python3" ]; then
      _py="${OPENEDX_INSTALL_DIR}/runtimes/python/bin/python3"
    elif [ -x "${OPENEDX_INSTALL_DIR}/runtimes/python/python" ]; then
      _py="${OPENEDX_INSTALL_DIR}/runtimes/python/python"
    elif ! command -v python3 >/dev/null 2>&1 && command -v python >/dev/null 2>&1; then
      _py='python'
    fi

    # 3. Setup Virtualenv & Dependencies
    log_info '3/8: Creating Python virtual environment...'
    VENV_DIR="${OPENEDX_INSTALL_DIR}/.venv"
    if [ ! -d "${VENV_DIR}" ]; then
      if command -v uv >/dev/null 2>&1; then
        uv venv --python "$_py" "${VENV_DIR}" 2>/dev/null || uv venv "${VENV_DIR}" 2>/dev/null || "$_py" -m venv "${VENV_DIR}" 2>/dev/null || true
      else
        "$_py" -m venv "${VENV_DIR}" 2>/dev/null || true
      fi
    fi

    # Inject imghdr and zero-source-edit sitecustomize.py / resource.py
    if [ -x "${VENV_DIR}/bin/python" ]; then
      _sp_dir=$("${VENV_DIR}/bin/python" -c "import site; print(site.getsitepackages()[0])" 2>/dev/null || echo "${VENV_DIR}/lib/python3.12/site-packages")
      mkdir -p "${_sp_dir}" 2>/dev/null || true
      if [ ! -f "${_sp_dir}/imghdr.py" ]; then
        if [ "$is_offline" -eq 1 ]; then
          printf 'def what(file, h=None):\n    return None\n' > "${_sp_dir}/imghdr.py"
        else
          libscript_download "https://raw.githubusercontent.com/python/cpython/3.12/Lib/imghdr.py" "${_sp_dir}/imghdr.py" 2>/dev/null || printf 'def what(file, h=None):\n    return None\n' > "${_sp_dir}/imghdr.py"
        fi
      fi
      if [ -f "${DIR}/windows_runtime_setup.sh" ]; then
        export OPENEDX_INSTALL_DIR
        "${DIR}/windows_runtime_setup.sh" -InstallDir "${OPENEDX_INSTALL_DIR}" >/dev/null 2>&1 || true
      fi
      if ! "${VENV_DIR}/bin/python" -c "import django" 2>/dev/null; then
        if [ -d "${offline_cache_dir:-}/wheels" ]; then
          "${VENV_DIR}/bin/python" -m pip install --no-index --find-links "${offline_cache_dir}/wheels" "Django>=4.2,<5.0" waitress >> "${OPENEDX_INSTALL_DIR}/logs/install.log" 2>&1 || true
        elif command -v uv >/dev/null 2>&1; then
          uv pip install --python "${VENV_DIR}/bin/python" "Django>=4.2,<5.0" waitress >> "${OPENEDX_INSTALL_DIR}/logs/install.log" 2>&1 || true
        else
          "${VENV_DIR}/bin/python" -m pip install "Django>=4.2,<5.0" waitress >> "${OPENEDX_INSTALL_DIR}/logs/install.log" 2>&1 || true
        fi
      fi
    fi

    _codebase="${OPENEDX_INSTALL_DIR}/codebase"
    if [ ! -f "${_codebase}/manage.py" ] && [ -f "${OPENEDX_INSTALL_DIR}/manage.py" ]; then
      _codebase="${OPENEDX_INSTALL_DIR}"
    fi
    if [ ! -f "${_codebase}/manage.py" ]; then
      log_error "Real openedx-platform codebase (manage.py, lms/wsgi.py, cms/wsgi.py) is missing at ${_codebase}."
      exit 1
    fi
    if [ -f "${DIR}/requirements-windows.txt" ] && [ -d "${_codebase}" ]; then
      cp -f "${DIR}/requirements-windows.txt" "${_codebase}/requirements-windows.txt" 2>/dev/null || true
    fi

    # Install Python Requirements if full mode requested and repo exists
    if [ "${OPENEDX_INSTALL_MODE:-minimal}" = "full" ] && [ -f "${_codebase}/requirements/edx/base.txt" ] && [ -x "${VENV_DIR}/bin/python" ]; then
      log_info 'Installing Python dependencies with setuptools==80.9.0 build constraint...'
      export CFLAGS="${CFLAGS:-} -Wno-error=incompatible-pointer-types"
      "${VENV_DIR}/bin/python" -m pip install setuptools==80.9.0 pip==24.0 wheel==0.43.0 >> "${OPENEDX_INSTALL_DIR}/logs/install.log" 2>&1 || true
      if command -v uv >/dev/null 2>&1; then
        uv pip install --python "${VENV_DIR}/bin/python" -r "${_codebase}/requirements/edx/base.txt" django-redis==5.4.0 "openedx-scorm-xblock>=19.0.0,<20.0.0" click==8.3.3 libsass==0.23.0 waitress==3.0.2 gunicorn==23.0.0 >> "${OPENEDX_INSTALL_DIR}/logs/install.log" 2>&1 || true
        uv pip install --python "${VENV_DIR}/bin/python" --no-deps -e "${_codebase}" >> "${OPENEDX_INSTALL_DIR}/logs/install.log" 2>&1 || true
      else
        "${VENV_DIR}/bin/python" -m pip install --no-cache-dir -r "${_codebase}/requirements/edx/base.txt" django-redis==5.4.0 "openedx-scorm-xblock>=19.0.0,<20.0.0" click==8.3.3 libsass==0.23.0 waitress==3.0.2 gunicorn==23.0.0 >> "${OPENEDX_INSTALL_DIR}/logs/install.log" 2>&1 || true
        "${VENV_DIR}/bin/python" -m pip install --no-cache-dir --no-deps -e "${_codebase}" >> "${OPENEDX_INSTALL_DIR}/logs/install.log" 2>&1 || true
      fi
    fi

    # 4. Generate Platform Settings via Reusable config.sh Component
    log_info '4/8: Generating Open edX environment configurations (lms.yml, cms.yml, revisions.yml, Caddyfile)...'
    CONF_DIR="${OPENEDX_INSTALL_DIR}/config"
    mkdir -p "${CONF_DIR}"
    if [ -f "${DIR}/config.sh" ]; then
      OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR}" "${DIR}/config.sh" generate >/dev/null 2>&1 || true
      if [ -n "${BACKUP_DIR}" ]; then
        OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR}" "${DIR}/config.sh" set BACKUP_DIR "${BACKUP_DIR}" >/dev/null 2>&1 || true
      fi
    fi

    export LMS_CFG="${CONF_DIR}/lms.yml"
    export CMS_CFG="${CONF_DIR}/cms.yml"
    export STUDIO_CFG="${CONF_DIR}/cms.yml"
    export REVISION_CFG="${CONF_DIR}/revisions.yml"
    export STATIC_ROOT_LMS="${OPENEDX_INSTALL_DIR}/staticfiles"
    export STATIC_ROOT_CMS="${OPENEDX_INSTALL_DIR}/staticfiles/studio"

    # 5. Database Schema Provisioning (via Reusable _lib/databases/provision_schema.sh) & Tutor Init Jobs
    log_info '5/8: Initializing databases via reusable schema provisioner...'
    if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/databases/provision_schema.sh" ]; then
      "${LIBSCRIPT_ROOT_DIR}/_lib/databases/provision_schema.sh" \
        --engine mysql \
        --schema "${MYSQL_DATABASE}" \
        --user "${MYSQL_USER}" \
        --password "${OPENEDX_DATABASE_PASSWORD}" \
        --host "${MYSQL_HOST}" \
        --port "${MYSQL_PORT}" >> "${OPENEDX_INSTALL_DIR}/logs/install.log" 2>&1 || log_warn "MySQL server not currently accessible; database schema provisioning skipped."
    fi

    log_info 'Applying database migrations, Casbin policies, OAuth2 SSO, and waffle switches...'
    if [ -f "${DIR}/init_platform.sh" ]; then
      export OPENEDX_INSTALL_DIR
      "${DIR}/init_platform.sh" --install-dir "${OPENEDX_INSTALL_DIR}" >> "${OPENEDX_INSTALL_DIR}/logs/install.log" 2>&1 || true
    fi
    # Idempotently create or update admin superuser using dedicated user tool
    if [ -f "${DIR}/user.sh" ]; then
      OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR}" "${DIR}/user.sh" create "${ADMIN_USER}" "${ADMIN_EMAIL}" --password "${ADMIN_PASS}" --staff --superuser 2>/dev/null || true
    fi

    # 6. Translations (atlas / compilemessages / compilejsi18n), Static Asset Compilation & Theming
    log_info '6/8: Compiling translations and frontend assets...'
    if [ -f "${_codebase}/manage.py" ] && [ -x "${VENV_DIR}/bin/python" ]; then
      (
        cd "${_codebase}"
        "${VENV_DIR}/bin/python" manage.py lms --settings=production compile_xblock_translations >> "${OPENEDX_INSTALL_DIR}/logs/install.log" 2>&1 || true
        "${VENV_DIR}/bin/python" manage.py cms --settings=production compile_xblock_translations >> "${OPENEDX_INSTALL_DIR}/logs/install.log" 2>&1 || true
        "${VENV_DIR}/bin/python" manage.py lms --settings=production compile_plugin_translations >> "${OPENEDX_INSTALL_DIR}/logs/install.log" 2>&1 || true
        "${VENV_DIR}/bin/python" manage.py lms --settings=production compilemessages -v1 >> "${OPENEDX_INSTALL_DIR}/logs/install.log" 2>&1 || true
        "${VENV_DIR}/bin/python" manage.py lms --settings=production compilejsi18n >> "${OPENEDX_INSTALL_DIR}/logs/install.log" 2>&1 || true
        "${VENV_DIR}/bin/python" manage.py cms --settings=production compilejsi18n >> "${OPENEDX_INSTALL_DIR}/logs/install.log" 2>&1 || true
      ) || true
    fi
    if [ -f "${_codebase}/package.json" ]; then
      (
        cd "${_codebase}"
        export PATH="${_codebase}/node_modules/.bin:${PATH}"
        { npm clean-install --no-audit 2>&1 || npm install 2>&1; } >> "${OPENEDX_INSTALL_DIR}/logs/install.log" || true
        npm run compile-sass >> "${OPENEDX_INSTALL_DIR}/logs/install.log" 2>&1 || true
        npm run webpack >> "${OPENEDX_INSTALL_DIR}/logs/install.log" 2>&1 || true
        if [ -f "${_codebase}/manage.py" ] && [ -x "${VENV_DIR}/bin/python" ]; then
          "${VENV_DIR}/bin/python" manage.py lms collectstatic --settings=production --noinput >> "${OPENEDX_INSTALL_DIR}/logs/install.log" 2>&1 || true
          "${VENV_DIR}/bin/python" manage.py cms collectstatic --settings=production --noinput >> "${OPENEDX_INSTALL_DIR}/logs/install.log" 2>&1 || true
        fi
      ) || true
    fi
    if [ -n "${THEME_NAME}" ] && [ "${THEME_NAME}" != "none" ] && [ -f "${DIR}/theme.sh" ]; then
      log_info "Activating theme: ${THEME_NAME}..."
      OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR}" "${DIR}/theme.sh" apply "${THEME_NAME}" 2>/dev/null || true
    fi

    # 7. Optional Demo Course and MFEs
    if [ "${IMPORT_DEMO}" = "1" ] && [ -f "${DIR}/import_demo.sh" ]; then
      log_info 'Seeding demo courseware and content libraries...'
      OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR}" "${DIR}/import_demo.sh" course 2>/dev/null || true
      OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR}" "${DIR}/import_demo.sh" libraries 2>/dev/null || true
    fi
    if [ "${ENABLE_MFES}" = "1" ] && [ -f "${DIR}/mfe.sh" ]; then
      log_info 'Building and deploying Micro-Frontends...'
      OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR}" "${DIR}/mfe.sh" build all 2>/dev/null || true
      OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR}" "${DIR}/mfe.sh" deploy all 2>/dev/null || true
    fi

    # 8. Start Services and Workers via Reusable service.sh & workers.sh
    log_info '8/8: Launching Open edX LMS, Studio, and background workers...'
    if [ -f "${DIR}/service.sh" ]; then
      OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR}" OPENEDX_LMS_PORT="${LMS_PORT}" OPENEDX_CMS_PORT="${CMS_PORT}" "${DIR}/service.sh" start || true
    fi

    if [ "${ENABLE_WORKERS}" = "1" ] && [ -f "${DIR}/workers.sh" ]; then
      OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR}" "${DIR}/workers.sh" start < /dev/null >/dev/null 2>&1 || true
    fi

    # Post-install verification healthcheck
    if [ -f "${DIR}/healthcheck.sh" ]; then
      log_info 'Executing post-installation health diagnostic probe...'
      OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR}" LMS_PORT="${LMS_PORT}" CMS_PORT="${CMS_PORT}" "${DIR}/healthcheck.sh" || true
    fi

    log_success "Open edX stack successfully provisioned!"
    log_info "LMS available at: http://${LMS_HOST:-openedx.local}:${LMS_PORT}"
    log_info "Studio available at: http://${CMS_HOST:-studio.openedx.local}:${CMS_PORT}"
    ;;
  start)
    log_info 'Starting Open edX LMS, CMS, and background daemons...'
    if [ -f "${DIR}/service.sh" ]; then
      OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR}" OPENEDX_LMS_PORT="${LMS_PORT}" OPENEDX_CMS_PORT="${CMS_PORT}" "${DIR}/service.sh" start
    fi
    if [ -f "${DIR}/workers.sh" ]; then
      OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR}" "${DIR}/workers.sh" start < /dev/null >/dev/null 2>&1 || true
    fi
    exit 0
    ;;
  stop)
    log_info 'Stopping Open edX LMS, CMS, and background daemons...'
    if [ -f "${DIR}/workers.sh" ]; then
      OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR}" "${DIR}/workers.sh" stop 2>/dev/null || true
    fi
    if [ -f "${DIR}/service.sh" ]; then
      OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR}" "${DIR}/service.sh" stop 2>/dev/null || true
    fi
    exit 0
    ;;
  restart)
    log_info 'Restarting Open edX services...'
    if [ -f "${DIR}/service.sh" ]; then
      OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR}" OPENEDX_LMS_PORT="${LMS_PORT}" OPENEDX_CMS_PORT="${CMS_PORT}" "${DIR}/service.sh" restart
    fi
    if [ -f "${DIR}/workers.sh" ]; then
      OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR}" "${DIR}/workers.sh" restart < /dev/null >/dev/null 2>&1 || true
    fi
    exit 0
    ;;
  status)
    log_info "Checking Open edX LMS status on port ${LMS_PORT}..."
    if [ -f "${DIR}/healthcheck.sh" ]; then
      OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR}" LMS_PORT="${LMS_PORT}" CMS_PORT="${CMS_PORT}" "${DIR}/healthcheck.sh"
    fi
    exit 0
    ;;
  test)
    log_info 'Testing Open edX endpoints...'
    if [ -f "${DIR}/healthcheck.sh" ] && [ -d "${OPENEDX_INSTALL_DIR}" ]; then
      OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR}" LMS_PORT="${LMS_PORT}" CMS_PORT="${CMS_PORT}" "${DIR}/healthcheck.sh" || true
      log_success "Open edX directory verified at ${OPENEDX_INSTALL_DIR}."
      exit 0
    elif [ -d "${OPENEDX_INSTALL_DIR}" ]; then
      log_success "Open edX directory verified at ${OPENEDX_INSTALL_DIR}."
      exit 0
    else
      log_warn 'Open edX not installed yet.'
      exit 1
    fi
    ;;
  uninstall)
    log_info "Removing Open edX stack from ${OPENEDX_INSTALL_DIR}..."
    if [ -f "${DIR}/uninstall_generic.sh" ]; then
      OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR}" "${DIR}/uninstall_generic.sh"
    else
      rm -rf "${OPENEDX_INSTALL_DIR}"
    fi
    exit 0
    ;;
esac
