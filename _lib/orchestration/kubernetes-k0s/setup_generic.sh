#!/bin/sh
# ## Overview
# Generic setup module for kubernetes-k0s.
# 
# ## Usage
# Execute this script to perform generic initialization steps for kubernetes-k0s.

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

KUBERNETES_K0S_INSTALL_METHOD="$(libscript_resolve_install_method "KUBERNETES_K0S")"
ACTION="${ACTION:-install}"
VERSION="${KUBERNETES_K0S_VERSION:-latest}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote kubernetes-k0s 2>/dev/null | tail -n 1)
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
    libscript_handle_generic_action "kubernetes-k0s" "$ACTION" "$VERSION" "${KUBERNETES_K0S_INSTALL_METHOD}"
    ;;
  ls-remote)
    if [ -n "${KUBERNETES_K0S_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${KUBERNETES_K0S_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    else
    git ls-remote --tags "https://github.com/k0sproject/k0s" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    fi
    exit 0
    ;;
  use)
    libscript_handle_generic_action "kubernetes-k0s" "$ACTION" "$VERSION" "${KUBERNETES_K0S_INSTALL_METHOD}"
    ;;
  download)
    if [ "$KUBERNETES_K0S_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading kubernetes-k0s ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/kubernetes-k0s..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/kubernetes-k0s"
      if [ -n "${KUBERNETES_K0S_DOWNLOAD_URL:-}" ]; then
        libscript_download "${KUBERNETES_K0S_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/kubernetes-k0s/kubernetes-k0s-${VERSION}.tar.gz"
      else
        log_warn "KUBERNETES_K0S_DOWNLOAD_URL is not defined for kubernetes-k0s ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$KUBERNETES_K0S_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'kubernetes-k0s'
    else
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/kubernetes-k0s/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing kubernetes-k0s ${VERSION} natively to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}/bin"
        if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/kubernetes-k0s/"*"${VERSION}"* >/dev/null 2>&1; then
          log_info 'Extracting from cache...'
          cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/kubernetes-k0s/" -maxdepth 1 -type f -name "*${VERSION}*" 2>/dev/null | head -n 1 || true)
          if [ -n "$cache_file" ]; then
            if case "$cache_file" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "$cache_file" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "$cache_file" in *.zip) true;; *) false;; esac; then
              unzip -q "$cache_file" -d "${TARGET_DIR}" || true
            else
              cp "$cache_file" "${TARGET_DIR}/bin/kubernetes-k0s" || true
              chmod +x "${TARGET_DIR}/bin/kubernetes-k0s" || true
            fi
          fi
        else
          if [ -n "${KUBERNETES_K0S_DOWNLOAD_URL:-}" ]; then
            TEMP_FILE=$(mktemp)
            libscript_download "${KUBERNETES_K0S_DOWNLOAD_URL:-}" "${TEMP_FILE}"
            if case "${KUBERNETES_K0S_DOWNLOAD_URL:-}" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "${TEMP_FILE}" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "${KUBERNETES_K0S_DOWNLOAD_URL:-}" in *.zip) true;; *) false;; esac; then
              unzip -q "${TEMP_FILE}" -d "${TARGET_DIR}" || true
            else
              cp "${TEMP_FILE}" "${TARGET_DIR}/bin/kubernetes-k0s" || true
              chmod +x "${TARGET_DIR}/bin/kubernetes-k0s" || true
            fi
            rm -f "${TEMP_FILE}"
          else
            if [ "$UNAME_LOWER" = "linux" ]; then
              _actual_version="${EXACT_VERSION}"
              if [ "${_actual_version}" = "latest" ] || [ "${_actual_version}" = "" ]; then
                _actual_version=$(libscript_fetch_stdout "https://api.github.com/repos/k0sproject/k0s/releases/latest" | grep '"tag_name":' | head -n 1 | cut -d '"' -f 4)
              fi
              case "${ARCH:-}" in
                aarch64|arm64) _k0s_arch="arm64" ;;
                *) _k0s_arch="amd64" ;;
              esac
              DL_URL="https://github.com/k0sproject/k0s/releases/download/${_actual_version}/k0s-${_actual_version}-${_k0s_arch}"
              mkdir -p "${TARGET_DIR}/bin"
              TEMP_FILE="${TARGET_DIR}/bin/k0s"
              libscript_download "$DL_URL" "$TEMP_FILE" || true
              chmod +x "$TEMP_FILE" || true
            else
              log_warn "No download URL provided for kubernetes-k0s ${VERSION}."
            fi
          fi
        fi
      else
        log_info "kubernetes-k0s ${VERSION} is already installed."
      fi
      libscript_symlink_alias "kubernetes-k0s" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "kubernetes-k0s" "$ACTION" "$VERSION" "${KUBERNETES_K0S_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
