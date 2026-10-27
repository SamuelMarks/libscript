#!/bin/sh
# ## Overview
# Generic setup module for ollama with reuse-else-create semantics.
# 
# ## Usage
# Execute this script to perform generic initialization steps for ollama.

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
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
fi

for LIB in "_lib/_common/pkg_mgr.sh" "_lib/_common/os_info.sh" "_lib/_common/versioning.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

OLLAMA_INSTALL_METHOD="$(libscript_resolve_install_method "OLLAMA")"
ACTION="${ACTION:-install}"
VERSION="${OLLAMA_VERSION:-latest}"

# ## find_existing_ollama
# Checks LIBSCRIPT_HOME, /usr/local/bin, /usr/bin, and system PATH for an existing ollama binary.
find_existing_ollama() {
  for _feo_cand in \
    "${LIBSCRIPT_HOME:-$HOME/.libscript}/ollama/${VERSION}/bin/ollama" \
    "${LIBSCRIPT_HOME:-$HOME/.libscript}/ollama/default/bin/ollama" \
    "/usr/local/bin/ollama" \
    "/usr/bin/ollama" \
    "$(command -v ollama 2>/dev/null || true)"; do
    if [ -n "$_feo_cand" ] && [ -x "$_feo_cand" ]; then
      printf '%s\n' "$_feo_cand"
      return 0
    fi
  done
  return 1
}

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${FORCE_REINSTALL:-0}" != "1" ] && find_existing_ollama >/dev/null 2>&1; then
    EXACT_VERSION="${VERSION:-latest}"
    return 0
  fi
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote ollama 2>/dev/null | tail -n 1)
    if [ -n "$_latest" ] && [ "$_latest" != "No versions found" ] && [ "$_latest" != "ls-remote not fully implemented natively yet." ]; then
      EXACT_VERSION="$_latest"
    else
      EXACT_VERSION="${VERSION:-latest}"
    fi
  else
    EXACT_VERSION="${VERSION:-latest}"
  fi
}

case "$ACTION" in
  ls)
    libscript_handle_generic_action "ollama" "$ACTION" "$VERSION" "${OLLAMA_INSTALL_METHOD}"
    ;;
  ls-remote)
    if [ -n "${OLLAMA_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${OLLAMA_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    else
      git ls-remote --tags "https://github.com/ollama/ollama" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    fi
    exit 0
    ;;
  use)
    libscript_handle_generic_action "ollama" "$ACTION" "$VERSION" "${OLLAMA_INSTALL_METHOD}"
    ;;
  download)
    if [ "$OLLAMA_INSTALL_METHOD" = "libscript_native" ]; then
      if [ "${FORCE_REINSTALL:-0}" != "1" ] && find_existing_ollama >/dev/null 2>&1; then
        log_info '[REUSE] ollama is already installed; skipping download.'
        exit 0
      fi
      log_info "Downloading ollama ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/ollama..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/ollama"
      if [ -n "${OLLAMA_DOWNLOAD_URL:-}" ]; then
        libscript_download "${OLLAMA_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/ollama/ollama-${VERSION}.tar.gz"
      else
        log_warn "OLLAMA_DOWNLOAD_URL is not defined for ollama ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "${FORCE_REINSTALL:-0}" != "1" ] && _existing_ol=$(find_existing_ollama 2>/dev/null); then
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/ollama/${EXACT_VERSION}"
      mkdir -p "${TARGET_DIR}/bin"
      if [ "$_existing_ol" != "${TARGET_DIR}/bin/ollama" ]; then
        ln -sf "$_existing_ol" "${TARGET_DIR}/bin/ollama" 2>/dev/null || true
      fi
      libscript_symlink_alias "ollama" "$VERSION" "${EXACT_VERSION}"
      libscript_symlink_alias "ollama" "default" "${EXACT_VERSION}"
      log_info "[REUSE] ollama (${VERSION}) already installed at ${_existing_ol}."
      exit 0
    fi
    if [ "$OLLAMA_INSTALL_METHOD" = "system" ]; then
      if ! libscript_depends "ollama"; then
        log_info 'System package manager does not have ollama. Falling back to native...'
        OLLAMA_INSTALL_METHOD='libscript_native'
      fi
    fi
    # libscript_native implementation
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/ollama/${EXACT_VERSION}"
    if [ ! -x "${TARGET_DIR}/bin/ollama" ]; then
      log_info "Installing ollama ${VERSION} natively to ${TARGET_DIR}..."
      mkdir -p "${TARGET_DIR}/bin"
      if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/ollama/"*"${VERSION}"* >/dev/null 2>&1; then
        log_info 'Extracting from cache...'
        cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/ollama/" -maxdepth 1 -type f -name "*${VERSION}*" 2>/dev/null | head -n 1 || true)
        if [ -n "$cache_file" ]; then
          if case "$cache_file" in *.tar.gz|*.tgz) true;; *) false;; esac; then
            tar -xzf "$cache_file" -C "${TARGET_DIR}" --strip-components=1 || true
          elif case "$cache_file" in *.zip) true;; *) false;; esac; then
            unzip -q "$cache_file" -d "${TARGET_DIR}" || true
          else
            cp "$cache_file" "${TARGET_DIR}/bin/ollama" || true
            chmod +x "${TARGET_DIR}/bin/ollama" || true
          fi
        fi
      else
        if [ -n "${OLLAMA_DOWNLOAD_URL:-}" ]; then
          TEMP_FILE=$(mktemp)
          libscript_download "${OLLAMA_DOWNLOAD_URL:-}" "${TEMP_FILE}"
          if case "${OLLAMA_DOWNLOAD_URL:-}" in *.tar.gz|*.tgz) true;; *) false;; esac; then
            tar -xzf "${TEMP_FILE}" -C "${TARGET_DIR}" --strip-components=1 || true
          elif case "${OLLAMA_DOWNLOAD_URL:-}" in *.zip) true;; *) false;; esac; then
            unzip -q "${TEMP_FILE}" -d "${TARGET_DIR}" || true
          else
            cp "${TEMP_FILE}" "${TARGET_DIR}/bin/ollama" || true
            chmod +x "${TARGET_DIR}/bin/ollama" || true
          fi
          rm -f "${TEMP_FILE}"
        else
          log_info "No download URL provided for ollama ${VERSION}. Attempting fallback to Github..."
          libscript_depends 'curl' 'tar'
          TEMP_FILE=$(mktemp)
          OS_ARCH=$(uname -m)
          _actual_version="${EXACT_VERSION}"
          if [ "${_actual_version}" = "latest" ] || [ "${_actual_version}" = "" ]; then
            _actual_version=$(libscript_resolve_github_latest "ollama/ollama" "v0.5.7")
          fi
          if [ "$OS_ARCH" = "aarch64" ]; then
            DL_URL="https://github.com/ollama/ollama/releases/download/${_actual_version}/ollama-linux-arm64.tgz"
          else
            DL_URL="https://github.com/ollama/ollama/releases/download/${_actual_version}/ollama-linux-amd64.tgz"
          fi
          if libscript_download "$DL_URL" "$TEMP_FILE"; then
            tar -xzf "$TEMP_FILE" -C "${TARGET_DIR}" || true
            chmod +x "${TARGET_DIR}/bin/ollama" 2>/dev/null || true
          fi
          rm -f "${TEMP_FILE}"
        fi
      fi
    else
      log_info "ollama ${VERSION} is already installed."
    fi
    libscript_symlink_alias "ollama" "$VERSION" "${EXACT_VERSION}"
    libscript_symlink_alias "ollama" "default" "${EXACT_VERSION}"
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "ollama" "$ACTION" "$VERSION" "${OLLAMA_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
