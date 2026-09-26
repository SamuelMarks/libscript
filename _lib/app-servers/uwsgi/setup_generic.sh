#!/bin/sh
# ## Overview
# Generic setup module for uWSGI application server.
# 
# ## Usage
# Execute this script to install, manage, and daemonize uWSGI across operating systems.

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

for LIB in "_lib/_common/pkg_mgr.sh" "_lib/_common/os_info.sh" "_lib/_common/versioning.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

UWSGI_INSTALL_METHOD="$(libscript_resolve_install_method "UWSGI")"
ACTION="${ACTION:-install}"
VERSION="${UWSGI_VERSION:-2.0.24}"

# ## resolve_exact_version
# Executes resolve_exact_version functionality.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ]; then
    EXACT_VERSION="2.0.24"
  else
    EXACT_VERSION="${VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if command -v uwsgi >/dev/null 2>&1; then
      uwsgi --version
    else
      printf 'uwsgi not installed
'
    fi
    exit 0
    ;;
  ls-remote)
    printf '2.0.22
2.0.24
'
    exit 0
    ;;
  install)
    resolve_exact_version
    log_info "Installing uWSGI (${VERSION}) via ${UWSGI_INSTALL_METHOD}..."
    if [ "$UWSGI_INSTALL_METHOD" = "libscript_native" ]; then
      if ! command -v uv >/dev/null 2>&1; then
        if ! command -v python3 >/dev/null 2>&1 || ! python3 -c 'import ensurepip' >/dev/null 2>&1; then
          log_info "Python runtime required for uwsgi. Installing python..."
          libscript_depends "python" || true
        fi
        if ! command -v gcc >/dev/null 2>&1 && ! command -v clang >/dev/null 2>&1; then
          libscript_depends "c" || true
        fi
      fi
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/uwsgi/${EXACT_VERSION}"
      mkdir -p "${TARGET_DIR}"
      export UWSGI_PROFILE_OVERRIDE="xml=no"
      if command -v uv >/dev/null 2>&1; then
        uv venv "${TARGET_DIR}"
        if [ "${VERSION}" = "latest" ]; then
          uv pip install --python "${TARGET_DIR}/bin/python" uwsgi
        else
          uv pip install --python "${TARGET_DIR}/bin/python" "uwsgi==${EXACT_VERSION}"
        fi
      else
        python3 -m venv "${TARGET_DIR}"
        if [ "${VERSION}" = "latest" ]; then
          "${TARGET_DIR}/bin/python" -m pip install --no-cache-dir uwsgi
        else
          "${TARGET_DIR}/bin/python" -m pip install --no-cache-dir "uwsgi==${EXACT_VERSION}"
        fi
      fi
      libscript_symlink_alias "uwsgi" "$VERSION" "${EXACT_VERSION}"
    else
      if command -v uwsgi >/dev/null 2>&1; then
        log_info "uWSGI is already available on the system: $(uwsgi --version 2>/dev/null || true)"
      elif [ "${UNAME_LOWER}" = "freebsd" ]; then
        libscript_depends "www/uwsgi" || libscript_depends "uwsgi"
      else
        export UWSGI_PROFILE_OVERRIDE="xml=no"
        if command -v pip3 >/dev/null 2>&1; then
          pip3 install --user uwsgi || python3 -m pip install --user uwsgi
        elif command -v pip >/dev/null 2>&1; then
          pip install --user uwsgi || python3 -m pip install --user uwsgi
        else
          libscript_depends "python"
          python3 -m pip install --user uwsgi || true
        fi
      fi
    fi
    ;;
  start|stop|restart|status|health|logs|up|down)
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
    export SCRIPT_NAME
    . "${SCRIPT_NAME}"
    service_name="${LIBSCRIPT_SERVICE_NAME:-uwsgi}"
    libscript_service "$ACTION" "$service_name" "$@"
    exit 0
    ;;
  install-service)
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
    export SCRIPT_NAME
    . "${SCRIPT_NAME}"
    service_name="${LIBSCRIPT_SERVICE_NAME:-uwsgi}"
    libscript_install_service "$service_name" "$@"
    exit 0
    ;;
  uninstall-service)
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
    export SCRIPT_NAME
    . "${SCRIPT_NAME}"
    service_name="${LIBSCRIPT_SERVICE_NAME:-uwsgi}"
    libscript_uninstall_service "$service_name" "$@"
    exit 0
    ;;
  uninstall)
    resolve_exact_version
    log_info "Uninstalling uWSGI ${EXACT_VERSION}..."
    rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/uwsgi/${EXACT_VERSION}"
    rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/uwsgi/${VERSION}"
    exit 0
    ;;
  test)
    if command -v uwsgi >/dev/null 2>&1; then
      uwsgi --version
      exit 0
    else
      printf 'uwsgi binary not found in PATH
' >&2
      exit 1
    fi
    ;;
esac
