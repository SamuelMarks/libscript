#!/bin/sh
# ## Overview
# Generic setup script for the mcuboot component implementing the Version Manager Contract.
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

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/pkg_mgr.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/versioning.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/source_builder.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/python_env.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

MCUBOOT_INSTALL_METHOD="${MCUBOOT_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-libscript_native}}"
ACTION="${ACTION:-install}"
VERSION="${MCUBOOT_VERSION:-2.1.0}"

# ## resolve_exact_version
# Resolves dynamic version aliases such as latest or lts into an exact upstream version string.
resolve_exact_version() {
  if [ "${VERSION}" = "latest" ] || [ "${VERSION}" = "lts" ]; then
    _gh_repo='mcu-tools/mcuboot'
    if [ -n "$_gh_repo" ]; then
      EXACT_VERSION=$(libscript_fetch_stdout 'https://api.github.com/repos/mcu-tools/mcuboot/releases/latest' | tr ',' '\n' | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1 | sed 's/^v//' || true)
      if [ -z "$EXACT_VERSION" ]; then
        EXACT_VERSION='1.0.0'
      fi
    else
      EXACT_VERSION='1.0.0'
    fi
  else
    EXACT_VERSION="${VERSION}"
  fi
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
    if [ "${MCUBOOT_INSTALL_METHOD}" = "libscript_native" ]; then
      [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/mcuboot" ] && ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/mcuboot"
    else
      if command -v 'imgtool' >/dev/null 2>&1; then
        'imgtool' --version || true
      fi
    fi
    ;;
  ls-remote)
    RELEASES_URL="${MCUBOOT_RELEASES_URL:-https://api.github.com/repos/mcu-tools/mcuboot/releases/latest}"
    printf '[ls-remote] Fetching available mcuboot versions from %s...\n' "${RELEASES_URL}"
    libscript_fetch_stdout "${RELEASES_URL}" | head -n 30 || true
    ;;
  use)
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/mcuboot/${EXACT_VERSION}"
    if [ ! -d "$TARGET_DIR" ]; then
      printf 'Version %s not installed. Installing...\n' "$EXACT_VERSION"
      ACTION='install' "$0"
    fi
    libscript_symlink_alias 'mcuboot' "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'mcuboot' 'default' "${EXACT_VERSION}"
    ;;
  sign)
    STACK='' "${SCRIPT_DIR}/sign_firmware.sh" "$@"
    ;;
  download)
    resolve_exact_version
    _def_dl_url='https://github.com/mcu-tools/mcuboot/archive/refs/tags/v{VERSION}.tar.gz'
    URL="${MCUBOOT_DOWNLOAD_URL:-${_def_dl_url}}"
    URL=$(resolve_artifact_url "$URL")
    DL_DIR="${DOWNLOAD_DIR:-/tmp/libscript_downloads}/mcuboot"
    mkdir -p "$DL_DIR"
    ARCHIVE_NAME=$(basename "$URL")
    printf '[download] Pre-downloading mcuboot %s from %s to %s...\n' "$VERSION" "$URL" "$DL_DIR/$ARCHIVE_NAME"
    libscript_download "$URL" "$DL_DIR/$ARCHIVE_NAME"
    ;;
  install)
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/mcuboot/${EXACT_VERSION}"
    if [ -x "${TARGET_DIR}/bin/imgtool" ] && [ "${FORCE_REINSTALL:-0}" != "1" ]; then
      printf '[INFO] %s %s is already installed at %s.\n' 'mcuboot' "${EXACT_VERSION}" "${TARGET_DIR}"
      libscript_symlink_alias 'mcuboot' "${VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias 'mcuboot' 'default' "${EXACT_VERSION}"
      exit 0
    fi
    mkdir -p "${TARGET_DIR}/bin"
    if [ "${LIBSCRIPT_OFFLINE:-0}" != "1" ]; then
      _req_tmp="${TARGET_DIR}/requirements.imgtool.txt"
      printf 'imgtool==%s\n' "${EXACT_VERSION}" > "$_req_tmp"
      if libscript_python_venv "${TARGET_DIR}/venv" "" "$_req_tmp" 2>/dev/null && [ -x "${TARGET_DIR}/venv/bin/imgtool" ]; then
        ln -sf "../venv/bin/imgtool" "${TARGET_DIR}/bin/imgtool"
      fi
    fi
    if [ ! -x "${TARGET_DIR}/bin/imgtool" ]; then
      for _cc in cc gcc clang; do
        if command -v "$_cc" >/dev/null 2>&1; then
          "$_cc" -std=c11 -O2 -o "${TARGET_DIR}/bin/mcuboot_c_signer" "${SCRIPT_DIR}/mcuboot_c_signer.c" && break
        fi
      done
      cat <<'WRAP' > "${TARGET_DIR}/bin/imgtool"
#!/bin/sh
if [ "${1:-}" = "--version" ] || [ "${1:-}" = "version" ]; then
  printf 'imgtool (LibScript MCUboot v2 C11 signer)\n'
  exit 0
fi
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
_wrap_dir=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
exec "${_wrap_dir}/mcuboot_c_signer" "$@"
WRAP
      chmod +x "${TARGET_DIR}/bin/imgtool"
    fi
    libscript_symlink_alias 'mcuboot' "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'mcuboot' 'default' "${EXACT_VERSION}"
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action 'mcuboot' "$ACTION" "$VERSION" "${MCUBOOT_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
