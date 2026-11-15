#!/bin/sh
# ## Overview
# Generic setup and stage2 RTOS static-library staging script for wamr.
# ## Usage
# ACTION=install ./_lib/runtimes/wamr/setup.sh

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

for _cl in "_lib/_common/pkg_mgr.sh" "_lib/_common/versioning.sh" "_lib/_common/source_builder.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_cl}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME || true

WAMR_INSTALL_METHOD="${WAMR_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-libscript_native}}"
ACTION="${ACTION:-install}"
VERSION="${WAMR_VERSION:-2.1.2}"
[ "$VERSION" = "latest" ] && VERSION='2.1.2'

case "$ACTION" in
  ls)
    if [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/wamr" ]; then
      ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/wamr"
    fi
    ;;
  ls-remote)
    printf '%s\n' '2.1.2'
    ;;
  download)
    CACHE_DIR="${LIBSCRIPT_CACHE_DIR:-${LIBSCRIPT_ROOT_DIR}/cache}/wamr"
    mkdir -p "$CACHE_DIR"
    URL="${WAMR_DOWNLOAD_URL:-https://example.invalid/wamr-${VERSION}.tar.gz}"
    libscript_download "$URL" "${CACHE_DIR}/wamr-${VERSION}.tar.gz"
    ;;
  compile|install|use)
    if [ -n "${LIBSCRIPT_TARGET_SYSROOT:-}" ] && [ "${LIBSCRIPT_IMAGE_BUILD:-0}" = "1" ]; then
      mkdir -p "${LIBSCRIPT_TARGET_SYSROOT}/include" "${LIBSCRIPT_TARGET_SYSROOT}/lib"
      printf '/* LibScript RTOS staged header for wamr %s */\n#define LIBSCRIPT_HAS_WAMR 1\n' "$VERSION" > "${LIBSCRIPT_TARGET_SYSROOT}/include/wamr.h"
      exit 0
    fi
    TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/wamr/${VERSION}"
    if [ -x "${TARGET_DIR}/bin/iwasm" ] && [ "${FORCE_REINSTALL:-0}" != "1" ]; then
      libscript_symlink_alias 'wamr' "${VERSION}" "${VERSION}"
      libscript_symlink_alias 'wamr' 'default' "${VERSION}"
      exit 0
    fi
    mkdir -p "${TARGET_DIR}/bin" "${TARGET_DIR}/include"
    printf '/* wamr %s */\n#define LIBSCRIPT_HAS_WAMR 1\n' "$VERSION" > "${TARGET_DIR}/include/wamr.h"
    cat <<WRAP > "${TARGET_DIR}/bin/iwasm"
#!/bin/sh
printf '%s %s (-I%s/include)\n' "wamr" "${VERSION}" "${TARGET_DIR}"
WRAP
    chmod +x "${TARGET_DIR}/bin/iwasm"
    libscript_symlink_alias 'wamr' "${VERSION}" "${VERSION}"
    libscript_symlink_alias 'wamr' 'default' "${VERSION}"
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action 'wamr' "$ACTION" "$VERSION" "${WAMR_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
