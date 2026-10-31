#!/bin/sh
# ## Overview
# Generic setup script for the android-sdk component.
# Downloads and configures Google Android commandlinetools (sdkmanager), accepts licenses,
# and installs configurable Android platforms and build-tools.
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
export DIR="${SCRIPT_DIR}"

if [ -f "${LIBSCRIPT_ROOT_DIR}/env.sh" ]; then
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/env.sh'
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
fi

for LIB in "_lib/_common/pkg_mgr.sh" "_lib/_common/versioning.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

ANDROID_SDK_VERSION="${ANDROID_SDK_VERSION:-11076708}"
ANDROID_PLATFORM="${ANDROID_PLATFORM:-platforms;android-34}"
ANDROID_BUILD_TOOLS="${ANDROID_BUILD_TOOLS:-build-tools;34.0.0}"
ACTION="${ACTION:-install}"

# ## resolve_cmdtools_url
# Resolves the official Google repository download URL for Android commandlinetools.
resolve_cmdtools_url() {
  _ver="$1"
  [ "$_ver" = "latest" ] && _ver="11076708"
  _os=$(uname -s | tr '[:upper:]' '[:lower:]')
  case "$_os" in
    darwin*) _plat="mac" ;;
    *) _plat="linux" ;;
  esac
  printf 'https://dl.google.com/android/repository/commandlinetools-%s-%s_latest.zip
' "$_plat" "$_ver"
}

case "$ACTION" in
  ls)
    ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/android-sdk/" 2>/dev/null || true
    exit 0
    ;;
  ls-remote)
    printf '%s
' "11076708"
    exit 0
    ;;
  use)
    EXACT_VERSION="${ANDROID_SDK_VERSION}"
    [ "$EXACT_VERSION" = "latest" ] && EXACT_VERSION="11076708"
    libscript_symlink_alias "android-sdk" "${ANDROID_SDK_VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias "android-sdk" "default" "${EXACT_VERSION}"
    exit 0
    ;;
  download)
    EXACT_VERSION="${ANDROID_SDK_VERSION}"
    [ "$EXACT_VERSION" = "latest" ] && EXACT_VERSION="11076708"
    DL_URL="${ANDROID_SDK_DOWNLOAD_URL:-$(resolve_cmdtools_url "$EXACT_VERSION")}"
    mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/android-sdk"
    libscript_download "$DL_URL" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/android-sdk/commandlinetools-${EXACT_VERSION}.zip"
    exit 0
    ;;
  install)
    EXACT_VERSION="${ANDROID_SDK_VERSION}"
    [ "$EXACT_VERSION" = "latest" ] && EXACT_VERSION="11076708"
    TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/android-sdk/${EXACT_VERSION}"
    if [ -x "${TARGET_DIR}/cmdline-tools/latest/bin/sdkmanager" ]; then
      log_info "android-sdk ${EXACT_VERSION} is already installed at ${TARGET_DIR}."
      libscript_symlink_alias "android-sdk" "latest" "${EXACT_VERSION}"
      exit 0
    fi

    libscript_depends 'java' 'unzip' || true
    mkdir -p "${TARGET_DIR}/cmdline-tools"

    DL_URL="${ANDROID_SDK_DOWNLOAD_URL:-$(resolve_cmdtools_url "$EXACT_VERSION")}"
    TEMP_ZIP=$(mktemp)
    libscript_download "$DL_URL" "$TEMP_ZIP"
    EXTRACT_TMP=$(mktemp -d)
    unzip -q "$TEMP_ZIP" -d "$EXTRACT_TMP"
    rm -f "$TEMP_ZIP"

    if [ -d "${EXTRACT_TMP}/cmdline-tools" ]; then
      rm -rf "${TARGET_DIR}/cmdline-tools/latest"
      mv "${EXTRACT_TMP}/cmdline-tools" "${TARGET_DIR}/cmdline-tools/latest"
    fi
    rm -rf "$EXTRACT_TMP"

    if [ -x "${TARGET_DIR}/cmdline-tools/latest/bin/sdkmanager" ]; then
      yes 2>/dev/null | "${TARGET_DIR}/cmdline-tools/latest/bin/sdkmanager" --sdk_root="${TARGET_DIR}" --licenses >/dev/null 2>&1 || true
      "${TARGET_DIR}/cmdline-tools/latest/bin/sdkmanager" --sdk_root="${TARGET_DIR}" "platform-tools" "${ANDROID_PLATFORM}" "${ANDROID_BUILD_TOOLS}" >/dev/null 2>&1 || true
    fi

    libscript_symlink_alias "android-sdk" "latest" "${EXACT_VERSION}"
    libscript_symlink_alias "android-sdk" "${ANDROID_SDK_VERSION}" "${EXACT_VERSION}"
    exit 0
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service)
    log_info 'android-sdk is a build toolchain and does not run a background daemon.'
    exit 0
    ;;
  uninstall)
    EXACT_VERSION="${ANDROID_SDK_VERSION}"
    [ "$EXACT_VERSION" = "latest" ] && EXACT_VERSION="11076708"
    rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/android-sdk/${EXACT_VERSION}"
    rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/android-sdk/latest"
    exit 0
    ;;
esac
