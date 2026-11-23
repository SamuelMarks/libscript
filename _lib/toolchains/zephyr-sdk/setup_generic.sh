#!/bin/sh
# ## Overview
# Generic setup script for the zephyr-sdk component implementing the Version Manager Contract.
#
# ## Usage
# This script is typically called internally by the component lifecycle.

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

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/engine/common/pkg_mgr.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/engine/common/versioning.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/engine/common/source_builder.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

ZEPHYR_SDK_INSTALL_METHOD="${ZEPHYR_SDK_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-libscript_native}}"
ACTION="${ACTION:-install}"
VERSION="${ZEPHYR_SDK_VERSION:-0.17.0}"
ZEPHYR_SDK_ARCHS="${ZEPHYR_SDK_ARCHS:-arm,aarch64,x86_64,riscv64}"

# ## resolve_exact_version
# Resolves dynamic version aliases such as latest or lts into an exact upstream version string.
resolve_exact_version() {
  if [ "${VERSION}" = "latest" ] || [ "${VERSION}" = "lts" ]; then
    _gh_repo='zephyrproject-rtos/sdk-ng'
    if [ -n "$_gh_repo" ]; then
      EXACT_VERSION=$(libscript_fetch_stdout 'https://api.github.com/repos/zephyrproject-rtos/sdk-ng/releases/latest' | tr ',' '\n' | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1 | sed 's/^v//' || true)
      if [ -z "$EXACT_VERSION" ]; then
        EXACT_VERSION='0.17.0'
      fi
    else
      EXACT_VERSION='0.17.0'
    fi
  else
    EXACT_VERSION="${VERSION}"
  fi
}

# ## resolve_sdk_host_tag
# Computes the Zephyr SDK archive host platform tag (linux-x86_64, linux-aarch64, macos-x86_64, macos-aarch64).
resolve_sdk_host_tag() {
  _u="${UNAME_LOWER:-linux}"
  _m="${ARCH:-x86_64}"
  case "$_m" in
    arm64|aarch64) _m='aarch64' ;;
    *) _m='x86_64' ;;
  esac
  case "$_u" in
    darwin*) printf 'macos-%s\n' "$_m" ;;
    *) printf 'linux-%s\n' "$_m" ;;
  esac
}

# ## resolve_artifact_url
# Substitutes version, OS, and CPU architecture tokens into an artifact URL template.
resolve_artifact_url() {
  _tpl="$1"
  _os_tok="${UNAME_LOWER:-linux}"
  _os_title='Linux'
  case "$_os_tok" in
    darwin*) _os_tok='darwin'; _os_title='Darwin' ;;
    freebsd*) _os_tok='freebsd'; _os_title='FreeBSD' ;;
    sunos*) _os_tok='sunos'; _os_title='SunOS' ;;
    *) _os_tok='linux'; _os_title='Linux' ;;
  esac
  _arch_raw="${ARCH:-x86_64}"
  _arch_x86='x86_64'
  _arch_go='amd64'
  case "$_arch_raw" in
    aarch64|arm64) _arch_x86='aarch64'; _arch_go='arm64' ;;
    x86_64|amd64) _arch_x86='x86_64'; _arch_go='amd64' ;;
    *) _arch_x86="$_arch_raw"; _arch_go="$_arch_raw" ;;
  esac
  _rust_target="${_arch_x86}-unknown-linux-musl"
  case "${_os_tok}:${_arch_x86}" in
    linux:aarch64) _rust_target='aarch64-unknown-linux-gnu' ;;
    linux:*) _rust_target="${_arch_x86}-unknown-linux-musl" ;;
    darwin:*) _rust_target="${_arch_x86}-apple-darwin" ;;
    freebsd:*) _rust_target="${_arch_x86}-unknown-freebsd" ;;
  esac
  printf '%s\n' "$_tpl" | sed \
    -e "s/{VERSION}/${EXACT_VERSION}/g" \
    -e "s/{OS}/${_os_tok}/g" \
    -e "s/{OS_TITLE}/${_os_title}/g" \
    -e "s/{ARCH}/${_arch_x86}/g" \
    -e "s/{ARCH_GO}/${_arch_go}/g" \
    -e "s/{RUST_TARGET}/${_rust_target}/g"
}

case "$ACTION" in
  ls)
    if [ "${ZEPHYR_SDK_INSTALL_METHOD}" = "libscript_native" ]; then
      [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/zephyr-sdk" ] && ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/zephyr-sdk"
    else
      if command -v 'arm-zephyr-eabi-gcc' >/dev/null 2>&1; then
        'arm-zephyr-eabi-gcc' --version || true
      fi
    fi
    ;;
  ls-remote)
    RELEASES_URL="${ZEPHYR_SDK_RELEASES_URL:-https://api.github.com/repos/zephyrproject-rtos/sdk-ng/releases/latest}"
    printf '[ls-remote] Fetching available zephyr-sdk versions from %s...\n' "${RELEASES_URL}"
    libscript_fetch_stdout "${RELEASES_URL}" | head -n 30 || true
    ;;
  use)
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/zephyr-sdk/${EXACT_VERSION}"
    if [ ! -d "$TARGET_DIR" ]; then
      printf 'Version %s not installed. Installing...\n' "$EXACT_VERSION"
      STACK='' ACTION='install' "${THIS_FILE}"
    fi
    libscript_symlink_alias 'zephyr-sdk' "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'zephyr-sdk' 'default' "${EXACT_VERSION}"
    ;;
  download)
    resolve_exact_version
    _host_tag=$(resolve_sdk_host_tag)
    _def_dl_url="https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v{VERSION}/zephyr-sdk-{VERSION}_${_host_tag}_minimal.tar.xz"
    URL="${ZEPHYR_SDK_DOWNLOAD_URL:-${_def_dl_url}}"
    URL=$(resolve_artifact_url "$URL")
    DL_DIR="${DOWNLOAD_DIR:-/tmp/libscript_downloads}/zephyr-sdk"
    mkdir -p "$DL_DIR"
    ARCHIVE_NAME=$(basename "$URL")
    printf '[download] Pre-downloading zephyr-sdk %s from %s to %s...\n' "$VERSION" "$URL" "$DL_DIR/$ARCHIVE_NAME"
    libscript_download "$URL" "$DL_DIR/$ARCHIVE_NAME"
    ;;
  install)
    if [ "${ZEPHYR_SDK_INSTALL_METHOD}" = "from-source" ]; then
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/zephyr-sdk/${EXACT_VERSION}"
      _host_tag=$(resolve_sdk_host_tag)
      _def_src_url="https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v{VERSION}/zephyr-sdk-{VERSION}_${_host_tag}_minimal.tar.xz"
      SRC_URL="${ZEPHYR_SDK_DOWNLOAD_URL:-${_def_src_url}}"
      SRC_URL=$(resolve_artifact_url "$SRC_URL")
      libscript_build_component_from_source 'zephyr-sdk' "$EXACT_VERSION" 'arm-zephyr-eabi-gcc' 'c' 'autotools' "$SRC_URL"
      libscript_symlink_alias 'zephyr-sdk' "${VERSION}" "${EXACT_VERSION}"
      exit 0
    elif [ "${ZEPHYR_SDK_INSTALL_METHOD}" = "system" ]; then
      libscript_depends 'zephyr-sdk'
    elif [ "${ZEPHYR_SDK_INSTALL_METHOD}" = "nix" ] || [ "${ZEPHYR_SDK_INSTALL_METHOD}" = "guix" ] || [ "${ZEPHYR_SDK_INSTALL_METHOD}" = "spack" ] || [ "${ZEPHYR_SDK_INSTALL_METHOD}" = "brew" ] || [ "${ZEPHYR_SDK_INSTALL_METHOD}" = "winget" ] || [ "${ZEPHYR_SDK_INSTALL_METHOD}" = "choco" ] || [ "${ZEPHYR_SDK_INSTALL_METHOD}" = "scoop" ]; then
      libscript_depends_via "${ZEPHYR_SDK_INSTALL_METHOD}" 'zephyr-sdk'
    else
      resolve_exact_version
      TARGET_DIR="${ZEPHYR_SDK_INSTALL_DIR:-${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/zephyr-sdk/${EXACT_VERSION}}"
      if { [ -x "${TARGET_DIR}/bin/arm-zephyr-eabi-gcc" ] || [ -x "${TARGET_DIR}/arm-zephyr-eabi/bin/arm-zephyr-eabi-gcc" ] || [ -f "${TARGET_DIR}/sdk_version" ]; } && [ "${FORCE_REINSTALL:-0}" != "1" ]; then
        printf '[INFO] %s %s is already installed at %s.\n' 'zephyr-sdk' "${EXACT_VERSION}" "${TARGET_DIR}"
        libscript_symlink_alias 'zephyr-sdk' "${VERSION}" "${EXACT_VERSION}"
        libscript_symlink_alias 'zephyr-sdk' 'default' "${EXACT_VERSION}"
        exit 0
      fi
      if [ "${LIBSCRIPT_ALLOW_STUB:-0}" = "1" ] && [ "${LIBSCRIPT_OFFLINE:-0}" = "1" ]; then
        mkdir -p "${TARGET_DIR}/bin"
        printf '%s\n' "${EXACT_VERSION}" > "${TARGET_DIR}/sdk_version"
        printf '#!/bin/sh\nprintf "arm-zephyr-eabi-gcc (Zephyr SDK %s stub)\\n"\n' "${EXACT_VERSION}" > "${TARGET_DIR}/bin/arm-zephyr-eabi-gcc"
        chmod +x "${TARGET_DIR}/bin/arm-zephyr-eabi-gcc"
        libscript_symlink_alias 'zephyr-sdk' "${VERSION}" "${EXACT_VERSION}"
        libscript_symlink_alias 'zephyr-sdk' 'default' "${EXACT_VERSION}"
        exit 0
      fi
      _host_tag=$(resolve_sdk_host_tag)
      _def_url="https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v{VERSION}/zephyr-sdk-{VERSION}_${_host_tag}_minimal.tar.xz"
      URL="${ZEPHYR_SDK_DOWNLOAD_URL:-${_def_url}}"
      URL=$(resolve_artifact_url "$URL")
      if [ -z "$URL" ]; then
        libscript_depends 'zephyr-sdk'
        exit 0
      fi
      mkdir -p "$TARGET_DIR/bin"
      ARCHIVE_NAME=$(basename "$URL")
      CACHED_DL="${DOWNLOAD_DIR:-${LIBSCRIPT_CACHE_DIR:-$LIBSCRIPT_ROOT_DIR/cache/downloads}}/zephyr-sdk/$ARCHIVE_NAME"
      if [ -s "$CACHED_DL" ]; then
        TMP_FILE="$CACHED_DL"
      else
        TMP_FILE="${TMPDIR:-/tmp}/zephyr-sdk-$$.archive"
        PACKAGE_NAME='zephyr-sdk' libscript_download "$URL" "$TMP_FILE"
      fi
      case "$URL" in
        *.tar.gz|*.tgz)
          tar -xzf "$TMP_FILE" -C "$TARGET_DIR" --strip-components=1 2>/dev/null || tar -xzf "$TMP_FILE" -C "$TARGET_DIR"
          ;;
        *.tar.xz|*.txz)
          tar -xJf "$TMP_FILE" -C "$TARGET_DIR" --strip-components=1 2>/dev/null || tar -xJf "$TMP_FILE" -C "$TARGET_DIR"
          ;;
        *.tar.bz2|*.tbz2)
          tar -xjf "$TMP_FILE" -C "$TARGET_DIR" --strip-components=1 2>/dev/null || tar -xjf "$TMP_FILE" -C "$TARGET_DIR"
          ;;
        *.zip)
          unzip -q -o "$TMP_FILE" -d "$TARGET_DIR"
          ;;
        *)
          cp -f "$TMP_FILE" "$TARGET_DIR/bin/arm-zephyr-eabi-gcc"
          chmod +x "$TARGET_DIR/bin/arm-zephyr-eabi-gcc"
          ;;
      esac
      if [ -x "${TARGET_DIR}/setup.sh" ] && [ "${LIBSCRIPT_OFFLINE:-0}" != "1" ]; then
        _old_ifs="$IFS"
        IFS=','
        for _zarch in $ZEPHYR_SDK_ARCHS; do
          [ -n "$_zarch" ] || continue
          "${TARGET_DIR}/setup.sh" -t "${_zarch}-zephyr-elf" 2>/dev/null || "${TARGET_DIR}/setup.sh" -t "${_zarch}-zephyr-eabi" 2>/dev/null || true
        done
        IFS="$_old_ifs"
      fi
      if [ -x "${TARGET_DIR}/arm-zephyr-eabi/bin/arm-zephyr-eabi-gcc" ]; then
        ln -sf "../arm-zephyr-eabi/bin/arm-zephyr-eabi-gcc" "${TARGET_DIR}/bin/arm-zephyr-eabi-gcc"
      fi
      if [ "$TMP_FILE" != "$CACHED_DL" ]; then
        rm -f "$TMP_FILE"
      fi
      libscript_symlink_alias 'zephyr-sdk' "${VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias 'zephyr-sdk' 'default' "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action 'zephyr-sdk' "$ACTION" "$VERSION" "${ZEPHYR_SDK_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
