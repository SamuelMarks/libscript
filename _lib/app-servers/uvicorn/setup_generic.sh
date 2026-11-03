#!/bin/sh
# ## Overview
# Generic setup module for Uvicorn ASGI server.
# 
# ## Usage
# Execute this script to install, manage, and execute Uvicorn.

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

UVICORN_INSTALL_METHOD="$(libscript_resolve_install_method "UVICORN")"
ACTION="${ACTION:-install}"
export VERSION="${UVICORN_VERSION:-latest}"

case "$ACTION" in
  ls)
    if command -v uvicorn >/dev/null 2>&1; then
      uvicorn --version
    else
      printf 'uvicorn not installed\n'
    fi
    exit 0
    ;;
  install)
    _uv_target="${LIBSCRIPT_HOME:-$HOME/.libscript}/uvicorn/${VERSION:-latest}"
    if [ -x "${_uv_target}/bin/uvicorn" ]; then
      log_info "uvicorn ${VERSION:-latest} is already installed."
      exit 0
    fi
    log_info "Installing Uvicorn ASGI server via ${UVICORN_INSTALL_METHOD}..."
    if command -v uvicorn >/dev/null 2>&1; then
      log_info 'uvicorn is already available on the system.'
      mkdir -p "${_uv_target}/bin"
      ln -sf "$(command -v uvicorn)" "${_uv_target}/bin/uvicorn"
    elif [ "$(uname -s)" = "FreeBSD" ]; then
      libscript_depends 'uvicorn'
    else
      if ! command -v uv >/dev/null 2>&1; then
        if ! command -v python3 >/dev/null 2>&1 || ! python3 -c 'import ensurepip' >/dev/null 2>&1; then
          libscript_depends 'python'
        fi
      fi
      mkdir -p "${_uv_target}"
      if command -v uv >/dev/null 2>&1; then
        uv venv "${_uv_target}" --seed 2>/dev/null || python3 -m venv "${_uv_target}"
        uv pip install --python "${_uv_target}/bin/python" uvicorn 2>/dev/null || "${_uv_target}/bin/pip" install uvicorn
      else
        python3 -m venv "${_uv_target}"
        "${_uv_target}/bin/pip" install uvicorn
      fi
      if [ -x "${_uv_target}/bin/uvicorn" ]; then
        priv ln -sf "${_uv_target}/bin/uvicorn" /usr/local/bin/uvicorn 2>/dev/null || true
      fi
    fi
    libscript_symlink_alias "uvicorn" "default" "${VERSION:-latest}" 2>/dev/null || true
    libscript_symlink_alias "uvicorn" "latest" "${VERSION:-latest}" 2>/dev/null || true
    ;;
  uninstall)
    log_info 'Uninstalling Uvicorn...'
    if command -v uv >/dev/null 2>&1; then uv tool uninstall uvicorn 2>/dev/null || true; fi
    if command -v pipx >/dev/null 2>&1; then pipx uninstall uvicorn 2>/dev/null || true; fi
    if command -v pip3 >/dev/null 2>&1; then pip3 uninstall -y uvicorn 2>/dev/null || true; fi
    exit 0
    ;;
  test)
    if command -v uvicorn >/dev/null 2>&1; then
      uvicorn --version
      exit 0
    else
      printf 'uvicorn not found in PATH\n' >&2
      exit 1
    fi
    ;;
esac
