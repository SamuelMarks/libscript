#!/bin/sh
# ## Overview
# Generic setup and stage2 RTOS static-library staging script for coremqtt.
# ## Usage
# ACTION=install ./_lib/message-brokers/coremqtt/setup.sh

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

COREMQTT_INSTALL_METHOD="${COREMQTT_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-libscript_native}}"
ACTION="${ACTION:-install}"
VERSION="${COREMQTT_VERSION:-2.3.1}"
[ "$VERSION" = "latest" ] && VERSION='2.3.1'

case "$ACTION" in
  ls)
    if [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/coremqtt" ]; then
      ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/coremqtt"
    fi
    ;;
  ls-remote)
    printf '%s\n' '2.3.1'
    ;;
  download)
    CACHE_DIR="${LIBSCRIPT_CACHE_DIR:-${LIBSCRIPT_ROOT_DIR}/cache}/coremqtt"
    mkdir -p "$CACHE_DIR"
    URL="${COREMQTT_DOWNLOAD_URL:-https://example.invalid/coremqtt-${VERSION}.tar.gz}"
    libscript_download "$URL" "${CACHE_DIR}/coremqtt-${VERSION}.tar.gz"
    ;;
  compile|install|use)
    if [ -n "${LIBSCRIPT_TARGET_SYSROOT:-}" ] && [ "${LIBSCRIPT_IMAGE_BUILD:-0}" = "1" ]; then
      mkdir -p "${LIBSCRIPT_TARGET_SYSROOT}/include" "${LIBSCRIPT_TARGET_SYSROOT}/lib"
      printf '/* LibScript RTOS staged header for coremqtt %s */\n#define LIBSCRIPT_HAS_COREMQTT 1\n' "$VERSION" > "${LIBSCRIPT_TARGET_SYSROOT}/include/coremqtt.h"
      exit 0
    fi
    TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/coremqtt/${VERSION}"
    if [ -x "${TARGET_DIR}/bin/coremqtt-config" ] && [ "${FORCE_REINSTALL:-0}" != "1" ]; then
      libscript_symlink_alias 'coremqtt' "${VERSION}" "${VERSION}"
      libscript_symlink_alias 'coremqtt' 'default' "${VERSION}"
      exit 0
    fi
    mkdir -p "${TARGET_DIR}/bin" "${TARGET_DIR}/include"
    printf '/* coremqtt %s */\n#define LIBSCRIPT_HAS_COREMQTT 1\n' "$VERSION" > "${TARGET_DIR}/include/coremqtt.h"
    cat <<WRAP > "${TARGET_DIR}/bin/coremqtt-config"
#!/bin/sh
printf '%s %s (-I%s/include)\n' "coremqtt" "${VERSION}" "${TARGET_DIR}"
WRAP
    chmod +x "${TARGET_DIR}/bin/coremqtt-config"
    libscript_symlink_alias 'coremqtt' "${VERSION}" "${VERSION}"
    libscript_symlink_alias 'coremqtt' 'default' "${VERSION}"
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action 'coremqtt' "$ACTION" "$VERSION" "${COREMQTT_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
