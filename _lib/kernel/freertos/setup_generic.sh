#!/bin/sh
# ## Overview
# Generic setup and synthesis router for FreeRTOS (_lib/kernel/freertos/).
# Supports Version Manager Contract verbs and Tier 2 firmware/simulator synthesis actions.
#
# ## Usage
# ACTION=install FREERTOS_VERSION=11.1.0 ./_lib/kernel/freertos/setup.sh

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

for _flib in "engine/common/pkg_mgr.sh" "engine/common/versioning.sh" "engine/common/source_builder.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_flib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME || true

FREERTOS_INSTALL_METHOD="${FREERTOS_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-libscript_native}}"
ACTION="${ACTION:-install}"
VERSION="${FREERTOS_VERSION:-11.1.0}"

# ## resolve_exact_version
# Resolves latest and lts aliases to concrete FreeRTOS-Kernel release tags.
resolve_exact_version() {
  case "$VERSION" in
    lts) EXACT_VERSION='10.5.1' ;;
    latest) EXACT_VERSION='11.1.0' ;;
    *) EXACT_VERSION="$VERSION" ;;
  esac
}

case "$ACTION" in
  ls)
    if [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/freertos" ]; then
      ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/freertos"
    fi
    ;;
  ls-remote)
    RELEASES_URL="${FREERTOS_RELEASES_URL:-https://api.github.com/repos/FreeRTOS/FreeRTOS-Kernel/releases}"
    printf '10.5.1 (LTS)\n11.1.0\n'
    if [ "${LIBSCRIPT_OFFLINE:-0}" != "1" ]; then
      libscript_fetch_stdout "${RELEASES_URL}" | tr ',' '\n' | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 10 || true
    fi
    ;;
  download)
    resolve_exact_version
    CACHE_DIR="${LIBSCRIPT_CACHE_DIR:-${LIBSCRIPT_ROOT_DIR}/cache}/freertos"
    mkdir -p "$CACHE_DIR"
    URL="${FREERTOS_DOWNLOAD_URL:-https://github.com/FreeRTOS/FreeRTOS-Kernel/archive/refs/tags/V${EXACT_VERSION}.tar.gz}"
    libscript_download "$URL" "${CACHE_DIR}/FreeRTOS-Kernel-V${EXACT_VERSION}.tar.gz"
    ;;
  bootstrap|install)
    resolve_exact_version
    if [ "${LIBSCRIPT_IMAGE_BUILD:-0}" = "1" ] && [ "${LIBSCRIPT_STAGE:-}" = "stage3" ]; then
      STACK='' "${SCRIPT_DIR}/build_firmware.sh"
      exit 0
    fi
    TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/freertos/${EXACT_VERSION}"
    if [ -x "${TARGET_DIR}/bin/freertos-env-check" ] && [ "${FORCE_REINSTALL:-0}" != "1" ]; then
      printf '[INFO] freertos %s is already installed at %s.\n' "$EXACT_VERSION" "$TARGET_DIR"
      libscript_symlink_alias 'freertos' "${VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias 'freertos' 'default' "${EXACT_VERSION}"
      exit 0
    fi
    mkdir -p "${TARGET_DIR}/bin" "${TARGET_DIR}/portable/MemMang"
    CACHE_TAR="${LIBSCRIPT_CACHE_DIR:-${LIBSCRIPT_ROOT_DIR}/cache}/freertos/FreeRTOS-Kernel-V${EXACT_VERSION}.tar.gz"
    if [ -s "$CACHE_TAR" ]; then
      tar -xzf "$CACHE_TAR" -C "$TARGET_DIR" --strip-components=1 2>/dev/null || true
    elif [ "${LIBSCRIPT_OFFLINE:-0}" != "1" ] && [ "${FREERTOS_FETCH_FULL_SOURCE:-0}" = "1" ]; then
      mkdir -p "$(dirname "$CACHE_TAR")"
      URL="${FREERTOS_DOWNLOAD_URL:-https://github.com/FreeRTOS/FreeRTOS-Kernel/archive/refs/tags/V${EXACT_VERSION}.tar.gz}"
      PACKAGE_NAME='freertos' libscript_download "$URL" "$CACHE_TAR"
      tar -xzf "$CACHE_TAR" -C "$TARGET_DIR" --strip-components=1 2>/dev/null || true
    fi
    cat <<WRAP > "${TARGET_DIR}/bin/freertos-env-check"
#!/bin/sh
printf 'FreeRTOS Kernel V%s (FREERTOS_KERNEL_PATH=%s)\n' "${EXACT_VERSION}" "${TARGET_DIR}"
WRAP
    chmod +x "${TARGET_DIR}/bin/freertos-env-check"
    libscript_symlink_alias 'freertos' "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'freertos' 'default' "${EXACT_VERSION}"
    ;;
  use)
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/freertos/${EXACT_VERSION}"
    if [ ! -d "$TARGET_DIR" ]; then
      STACK='' ACTION='install' "${THIS_FILE}"
    fi
    libscript_symlink_alias 'freertos' "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'freertos' 'default' "${EXACT_VERSION}"
    ;;
  compile|assemble)
    STACK='' "${SCRIPT_DIR}/build_firmware.sh"
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action 'freertos' "$ACTION" "$VERSION" "${FREERTOS_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
