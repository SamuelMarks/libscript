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

UVICORN_INSTALL_METHOD="$(libscript_resolve_install_method "UVICORN")"
ACTION="${ACTION:-install}"
export VERSION="${UVICORN_VERSION:-latest}"

case "$ACTION" in
  ls)
    if command -v uvicorn >/dev/null 2>&1; then
      uvicorn --version
    else
      printf 'uvicorn not installed
'
    fi
    exit 0
    ;;
  install)
    log_info "Installing Uvicorn ASGI server via ${UVICORN_INSTALL_METHOD}..."
    if command -v uvicorn >/dev/null 2>&1; then
      log_info "uvicorn is already available on the system."
    elif command -v uv >/dev/null 2>&1; then
      uv tool install uvicorn 2>/dev/null || uv pip install uvicorn
    elif command -v pipx >/dev/null 2>&1; then
      pipx install uvicorn
    elif command -v pip3 >/dev/null 2>&1; then
      pip3 install --user uvicorn
    elif command -v pip >/dev/null 2>&1; then
      pip install --user uvicorn
    else
      libscript_depends "python"
      pip3 install --user uvicorn || true
    fi
    ;;
  uninstall)
    log_info "Uninstalling Uvicorn..."
    command -v uv >/dev/null 2>&1 && uv tool uninstall uvicorn 2>/dev/null || true
    command -v pipx >/dev/null 2>&1 && pipx uninstall uvicorn 2>/dev/null || true
    command -v pip3 >/dev/null 2>&1 && pip3 uninstall -y uvicorn 2>/dev/null || true
    exit 0
    ;;
  test)
    if command -v uvicorn >/dev/null 2>&1; then
      uvicorn --version
      exit 0
    else
      printf 'uvicorn not found in PATH
' >&2
      exit 1
    fi
    ;;
esac
