#!/bin/sh
# cspell:words SHIMEOF
# ## Overview
# Generic setup and installation script for the nssm component.
# Provides a cross-platform shim on POSIX and manages NSSM on Windows.
#
# ## Usage
# Called internally by setup.sh / cli.sh.

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
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/env.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
fi

for LIB in "_lib/_common/pkg_mgr.sh" "_lib/_common/versioning.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

NSSM_VERSION="${NSSM_VERSION:-2.24}"
[ "${NSSM_VERSION}" = "latest" ] && NSSM_VERSION="2.24"
ACTION="${ACTION:-install}"

case "$ACTION" in
  ls)
    ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/nssm/" 2>/dev/null || true
    exit 0
    ;;
  ls-remote)
    printf '2.24
2.23
'
    exit 0
    ;;
  use)
    libscript_symlink_alias "nssm" "${NSSM_VERSION}" "2.24"
    libscript_symlink_alias "nssm" "default" "2.24"
    exit 0
    ;;
  download)
    mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/nssm"
    if [ -n "${NSSM_DOWNLOAD_URL:-}" ]; then
      libscript_download "${NSSM_DOWNLOAD_URL}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/nssm/nssm-${NSSM_VERSION}.zip"
    fi
    exit 0
    ;;
  install)
    TARGET_DIR="${NSSM_INSTALL_DIR:-${LIBSCRIPT_HOME:-$HOME/.libscript}/nssm/${NSSM_VERSION}}"
    if [ -x "${TARGET_DIR}/bin/nssm" ]; then
      log_info "nssm ${NSSM_VERSION} is already installed at ${TARGET_DIR}."
      libscript_symlink_alias "nssm" "latest" "${NSSM_VERSION}"
      exit 0
    fi
    mkdir -p "${TARGET_DIR}/bin"
    cat << 'SHIMEOF' > "${TARGET_DIR}/bin/nssm"
#!/bin/sh
printf 'NSSM 2.24 (POSIX compatibility stub - native Windows service manager)
'
exit 0
SHIMEOF
    chmod +x "${TARGET_DIR}/bin/nssm"
    libscript_symlink_alias "nssm" "latest" "${NSSM_VERSION}"
    exit 0
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "nssm" "$ACTION" "${NSSM_VERSION}" "libscript_native" "" "" "" "$@"
    ;;
esac
