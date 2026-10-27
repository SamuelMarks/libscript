#!/bin/sh
# ## Overview
# Generic setup module for Gunicorn WSGI server.
# 
# ## Usage
# Execute this script to install, manage, and daemonize Gunicorn across operating systems.

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

GUNICORN_INSTALL_METHOD="$(libscript_resolve_install_method "GUNICORN")"
ACTION="${ACTION:-install}"
VERSION="${GUNICORN_VERSION:-latest}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ]; then
    EXACT_VERSION='26.2.0'
  else
    EXACT_VERSION="${VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if command -v gunicorn >/dev/null 2>&1; then
      gunicorn --version
    else
      printf 'gunicorn not installed\n'
    fi
    exit 0
    ;;
  ls-remote)
    printf '21.2.0
22.0.0
26.2.0
'
    exit 0
    ;;
  install)
    if [ -x "${LIBSCRIPT_HOME:-$HOME/.libscript}/gunicorn/${VERSION:-latest}/bin/gunicorn" ]; then
      log_info "gunicorn ${VERSION:-latest} is already installed."
      exit 0
    fi
    resolve_exact_version
    log_info "Installing Gunicorn (${VERSION}) via ${GUNICORN_INSTALL_METHOD}..."
    if [ "$GUNICORN_INSTALL_METHOD" = "libscript_native" ]; then
      if ! command -v uv >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
        log_info 'Python runtime required for gunicorn. Installing python...'
        libscript_depends 'python' || true
      fi
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/gunicorn/${EXACT_VERSION}"
      mkdir -p "${TARGET_DIR}"
      if [ "$(uname -s)" = "FreeBSD" ]; then
        libscript_depends 'gunicorn'
        if command -v gunicorn >/dev/null 2>&1; then
          mkdir -p "${TARGET_DIR}/bin"
          ln -sf "$(command -v gunicorn)" "${TARGET_DIR}/bin/gunicorn"
        fi
      elif command -v uv >/dev/null 2>&1; then
        uv venv --allow-existing "${TARGET_DIR}"
        if [ "${VERSION}" = "latest" ]; then
          uv pip install --python "${TARGET_DIR}/bin/python" gunicorn
        else
          uv pip install --python "${TARGET_DIR}/bin/python" "gunicorn==${EXACT_VERSION}"
        fi
      else
        python3 -m venv "${TARGET_DIR}"
        if [ "${VERSION}" = "latest" ]; then
          "${TARGET_DIR}/bin/python" -m pip install --no-cache-dir gunicorn
        else
          "${TARGET_DIR}/bin/python" -m pip install --no-cache-dir "gunicorn==${EXACT_VERSION}"
        fi
      fi
      libscript_symlink_alias "gunicorn" "$VERSION" "${EXACT_VERSION}"
    else
      if command -v gunicorn >/dev/null 2>&1; then
        log_info "Gunicorn is already available on the system: $(gunicorn --version 2>/dev/null || true)"
      elif command -v uv >/dev/null 2>&1; then
        uv tool install gunicorn 2>/dev/null || uv pip install gunicorn
      elif command -v pipx >/dev/null 2>&1; then
        pipx install gunicorn
      elif command -v pip3 >/dev/null 2>&1; then
        pip3 install --user gunicorn
      elif command -v pip >/dev/null 2>&1; then
        pip install --user gunicorn
      else
        libscript_depends 'python'
        pip3 install --user gunicorn || true
      fi
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "gunicorn" "$ACTION" "$VERSION" "${GUNICORN_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
