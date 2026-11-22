#!/bin/sh
# ## Overview
# Generic setup and stage2 RTOS static-library staging script for freertos-plus-tcp.
# ## Usage
# ACTION=install ./_lib/networking/freertos-plus-tcp/setup.sh

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

for _cl in "engine/common/pkg_mgr.sh" "engine/common/versioning.sh" "engine/common/source_builder.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_cl}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME || true

FREERTOS_PLUS_TCP_INSTALL_METHOD="${FREERTOS_PLUS_TCP_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-libscript_native}}"
ACTION="${ACTION:-install}"
VERSION="${FREERTOS_PLUS_TCP_VERSION:-4.2.2}"
[ "$VERSION" = "latest" ] && VERSION='4.2.2'

case "$ACTION" in
  ls)
    if [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/freertos-plus-tcp" ]; then
      ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/freertos-plus-tcp"
    fi
    ;;
  ls-remote)
    printf '%s\n' '4.2.2'
    ;;
  download)
    CACHE_DIR="${LIBSCRIPT_CACHE_DIR:-${LIBSCRIPT_ROOT_DIR}/cache}/freertos-plus-tcp"
    mkdir -p "$CACHE_DIR"
    URL="${FREERTOS_PLUS_TCP_DOWNLOAD_URL:-https://example.invalid/freertos-plus-tcp-${VERSION}.tar.gz}"
    libscript_download "$URL" "${CACHE_DIR}/freertos-plus-tcp-${VERSION}.tar.gz"
    ;;
  compile|install|use)
    if [ -n "${LIBSCRIPT_TARGET_SYSROOT:-}" ] && [ "${LIBSCRIPT_IMAGE_BUILD:-0}" = "1" ]; then
      mkdir -p "${LIBSCRIPT_TARGET_SYSROOT}/include" "${LIBSCRIPT_TARGET_SYSROOT}/lib"
      printf '/* LibScript RTOS staged header for freertos-plus-tcp %s */\n#define LIBSCRIPT_HAS_FREERTOS_PLUS_TCP 1\n' "$VERSION" > "${LIBSCRIPT_TARGET_SYSROOT}/include/freertos-plus-tcp.h"
      exit 0
    fi
    TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/freertos-plus-tcp/${VERSION}"
    if [ -x "${TARGET_DIR}/bin/freertos-plus-tcp-config" ] && [ "${FORCE_REINSTALL:-0}" != "1" ]; then
      libscript_symlink_alias 'freertos-plus-tcp' "${VERSION}" "${VERSION}"
      libscript_symlink_alias 'freertos-plus-tcp' 'default' "${VERSION}"
      exit 0
    fi
    mkdir -p "${TARGET_DIR}/bin" "${TARGET_DIR}/include"
    printf '/* freertos-plus-tcp %s */\n#define LIBSCRIPT_HAS_FREERTOS_PLUS_TCP 1\n' "$VERSION" > "${TARGET_DIR}/include/freertos-plus-tcp.h"
    cat <<WRAP > "${TARGET_DIR}/bin/freertos-plus-tcp-config"
#!/bin/sh
printf '%s %s (-I%s/include)\n' "freertos-plus-tcp" "${VERSION}" "${TARGET_DIR}"
WRAP
    chmod +x "${TARGET_DIR}/bin/freertos-plus-tcp-config"
    libscript_symlink_alias 'freertos-plus-tcp' "${VERSION}" "${VERSION}"
    libscript_symlink_alias 'freertos-plus-tcp' 'default' "${VERSION}"
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action 'freertos-plus-tcp' "$ACTION" "$VERSION" "${FREERTOS_PLUS_TCP_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
