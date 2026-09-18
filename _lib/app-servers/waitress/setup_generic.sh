#!/bin/sh
# ## Overview
# Generic setup module for Waitress WSGI server.
# 
# ## Usage
# Execute this script to install, manage, and execute Waitress.

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

WAITRESS_INSTALL_METHOD="$(libscript_resolve_install_method "WAITRESS")"
ACTION="${ACTION:-install}"
export VERSION="${WAITRESS_VERSION:-latest}"

case "$ACTION" in
  ls)
    if command -v waitress-serve >/dev/null 2>&1; then
      printf 'waitress installed
'
    else
      printf 'waitress not installed
'
    fi
    exit 0
    ;;
  install)
    log_info "Installing Waitress WSGI server via ${WAITRESS_INSTALL_METHOD}..."
    if command -v waitress-serve >/dev/null 2>&1; then
      log_info "waitress is already available on the system."
    elif command -v uv >/dev/null 2>&1; then
      uv tool install waitress 2>/dev/null || uv pip install waitress
    elif command -v pipx >/dev/null 2>&1; then
      pipx install waitress
    elif command -v pip3 >/dev/null 2>&1; then
      pip3 install --user waitress
    elif command -v pip >/dev/null 2>&1; then
      pip install --user waitress
    else
      libscript_depends "python"
      pip3 install --user waitress || true
    fi
    ;;
  uninstall)
    log_info "Uninstalling Waitress..."
    command -v uv >/dev/null 2>&1 && uv tool uninstall waitress 2>/dev/null || true
    command -v pipx >/dev/null 2>&1 && pipx uninstall waitress 2>/dev/null || true
    command -v pip3 >/dev/null 2>&1 && pip3 uninstall -y waitress 2>/dev/null || true
    exit 0
    ;;
  test)
    if command -v waitress-serve >/dev/null 2>&1; then
      waitress-serve --help >/dev/null 2>&1
      printf 'waitress verified
'
      exit 0
    else
      printf 'waitress-serve not found in PATH
' >&2
      exit 1
    fi
    ;;
esac
