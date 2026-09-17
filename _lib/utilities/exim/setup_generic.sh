#!/bin/sh
# ## Overview
# Generic setup module for Exim mail transfer agent and SMTP relay.
# 
# ## Usage
# Executes cross-platform installation and service management for Exim.

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

EXIM_INSTALL_METHOD="$(libscript_resolve_install_method "EXIM")"
ACTION="${ACTION:-install}"
VERSION="${EXIM_VERSION:-latest}"

case "$ACTION" in
  ls)
    if command -v exim >/dev/null 2>&1; then
      exim -bV
    elif command -v exim4 >/dev/null 2>&1; then
      exim4 -bV
    else
      printf 'exim not installed
'
    fi
    exit 0
    ;;
  ls-remote)
    printf '4.96
4.97
'
    exit 0
    ;;
  install)
    log_info "Installing Exim SMTP relay via ${EXIM_INSTALL_METHOD}..."
    if [ "${UNAME_LOWER}" = "freebsd" ]; then
      libscript_depends "mail/exim" || libscript_depends "exim"
      if command -v sysrc >/dev/null 2>&1; then
        sysrc exim_enable="YES" || true
      fi
    elif [ "${TARGET_OS:-}" = "sunos" ] || [ "${UNAME:-$(uname)}" = "SunOS" ]; then
      libscript_depends "exim" || true
    else
      libscript_depends "exim"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down)
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
    export SCRIPT_NAME
    . "${SCRIPT_NAME}"
    service_name="${LIBSCRIPT_SERVICE_NAME:-exim}"
    libscript_service "$ACTION" "$service_name" "$@"
    exit 0
    ;;
  install-service)
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
    export SCRIPT_NAME
    . "${SCRIPT_NAME}"
    service_name="${LIBSCRIPT_SERVICE_NAME:-exim}"
    libscript_install_service "$service_name" "$@"
    exit 0
    ;;
  uninstall-service)
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
    export SCRIPT_NAME
    . "${SCRIPT_NAME}"
    service_name="${LIBSCRIPT_SERVICE_NAME:-exim}"
    libscript_uninstall_service "$service_name" "$@"
    exit 0
    ;;
  uninstall)
    log_info "Uninstalling Exim..."
    exit 0
    ;;
  test)
    if command -v exim >/dev/null 2>&1; then
      exim -bV
      exit 0
    elif command -v exim4 >/dev/null 2>&1; then
      exim4 -bV
      exit 0
    else
      printf 'exim binary not found in PATH
' >&2
      exit 1
    fi
    ;;
esac
