#!/bin/sh
# ## Overview
# Generic setup and synthesis router for Zephyr RTOS (_lib/kernel/zephyr/).
# Supports Version Manager Contract verbs (ls, ls-remote, download, install, use, uninstall)
# and Tier 2 synthesis actions (bootstrap, compile, assemble).
#
# ## Usage
# ACTION=install ZEPHYR_VERSION=3.7.0 ./_lib/kernel/zephyr/setup.sh

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

for _zlib in "_lib/_common/pkg_mgr.sh" "_lib/_common/versioning.sh" "_lib/_common/source_builder.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_zlib}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done
unset SCRIPT_NAME || true

ZEPHYR_INSTALL_METHOD="${ZEPHYR_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-libscript_native}}"
ACTION="${ACTION:-install}"
VERSION="${ZEPHYR_VERSION:-3.7.0}"

# ## resolve_exact_version
# Resolves latest or lts aliases to concrete Zephyr RTOS release versions.
resolve_exact_version() {
  case "$VERSION" in
    lts) EXACT_VERSION='3.7.0' ;;
    latest) EXACT_VERSION='4.0.0' ;;
    *) EXACT_VERSION="$VERSION" ;;
  esac
}

case "$ACTION" in
  ls)
    if [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/zephyr" ]; then
      ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/zephyr"
    fi
    ;;
  ls-remote)
    RELEASES_URL="${ZEPHYR_RELEASES_URL:-https://api.github.com/repos/zephyrproject-rtos/zephyr/releases}"
    printf '3.7.0 (LTS)\n4.0.0\n'
    if [ "${LIBSCRIPT_OFFLINE:-0}" != "1" ]; then
      libscript_fetch_stdout "${RELEASES_URL}" | tr ',' '\n' | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 10 || true
    fi
    ;;
  download)
    resolve_exact_version
    CACHE_DIR="${LIBSCRIPT_CACHE_DIR:-${LIBSCRIPT_ROOT_DIR}/cache}/zephyr"
    mkdir -p "$CACHE_DIR"
    URL="${ZEPHYR_DOWNLOAD_URL:-https://github.com/zephyrproject-rtos/zephyr/archive/refs/tags/v${EXACT_VERSION}.tar.gz}"
    libscript_download "$URL" "${CACHE_DIR}/zephyr-v${EXACT_VERSION}.tar.gz"
    ;;
  bootstrap|install)
    resolve_exact_version
    if [ "${LIBSCRIPT_IMAGE_BUILD:-0}" = "1" ] && [ "${LIBSCRIPT_STAGE:-}" = "stage3" ]; then
      STACK='' "${SCRIPT_DIR}/build_firmware.sh"
      exit 0
    fi
    TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/zephyr/${EXACT_VERSION}"
    if [ -x "${TARGET_DIR}/bin/zephyr-env-check" ] && [ "${FORCE_REINSTALL:-0}" != "1" ]; then
      printf '[INFO] zephyr %s is already installed at %s.\n' "$EXACT_VERSION" "$TARGET_DIR"
      libscript_symlink_alias 'zephyr' "${VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias 'zephyr' 'default' "${EXACT_VERSION}"
      exit 0
    fi
    mkdir -p "${TARGET_DIR}/bin" "${TARGET_DIR}/modules/hal"
    CACHE_TAR="${LIBSCRIPT_CACHE_DIR:-${LIBSCRIPT_ROOT_DIR}/cache}/zephyr/zephyr-v${EXACT_VERSION}.tar.gz"
    if [ -s "$CACHE_TAR" ]; then
      tar -xzf "$CACHE_TAR" -C "$TARGET_DIR" --strip-components=1 2>/dev/null || true
    elif [ "${LIBSCRIPT_OFFLINE:-0}" != "1" ] && [ "${ZEPHYR_FETCH_FULL_SOURCE:-0}" = "1" ]; then
      mkdir -p "$(dirname "$CACHE_TAR")"
      URL="${ZEPHYR_DOWNLOAD_URL:-https://github.com/zephyrproject-rtos/zephyr/archive/refs/tags/v${EXACT_VERSION}.tar.gz}"
      PACKAGE_NAME='zephyr' libscript_download "$URL" "$CACHE_TAR"
      tar -xzf "$CACHE_TAR" -C "$TARGET_DIR" --strip-components=1 2>/dev/null || true
    fi
    cat <<WRAP > "${TARGET_DIR}/bin/zephyr-env-check"
#!/bin/sh
printf 'Zephyr RTOS Kernel %s (ZEPHYR_BASE=%s)\n' "${EXACT_VERSION}" "${TARGET_DIR}"
WRAP
    chmod +x "${TARGET_DIR}/bin/zephyr-env-check"
    libscript_symlink_alias 'zephyr' "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'zephyr' 'default' "${EXACT_VERSION}"
    ;;
  use)
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/zephyr/${EXACT_VERSION}"
    if [ ! -d "$TARGET_DIR" ]; then
      ACTION='install' "$0"
    fi
    libscript_symlink_alias 'zephyr' "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'zephyr' 'default' "${EXACT_VERSION}"
    ;;
  compile|assemble)
    STACK='' "${SCRIPT_DIR}/build_firmware.sh"
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action 'zephyr' "$ACTION" "$VERSION" "${ZEPHYR_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
