#!/bin/sh
# ## Overview
# Generic setup module for ansible-galaxy.
# 
# ## Usage
# Execute this script to perform generic initialization steps for ansible-galaxy.

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
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;; esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf "%s\n" "$d")}"
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

ANSIBLE_GALAXY_INSTALL_METHOD="${ANSIBLE_GALAXY_INSTALL_METHOD:-system}"
ANSIBLE_GALAXY_INSTALL_METHOD="$(libscript_resolve_install_method "ANSIBLE_GALAXY")"
ACTION="${ACTION:-install}"
VERSION="${ANSIBLE_GALAXY_VERSION:-latest}"

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote ansible-galaxy 2>/dev/null | tail -n 1)
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
    libscript_handle_generic_action "ansible-galaxy" "$ACTION" "$VERSION" "${ANSIBLE_GALAXY_INSTALL_METHOD}"
    ;;
  ls-remote)
    if [ -n "${ANSIBLE_GALAXY_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${ANSIBLE_GALAXY_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    else
    git ls-remote --tags "https://github.com/ansible/ansible" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    fi
    exit 0
    ;;
  use)
    libscript_handle_generic_action "ansible-galaxy" "$ACTION" "$VERSION" "${ANSIBLE_GALAXY_INSTALL_METHOD}"
    ;;
  download)
    if [ "$ANSIBLE_GALAXY_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading ansible-galaxy ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/ansible-galaxy..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/ansible-galaxy"
      if [ -n "${ANSIBLE_GALAXY_DOWNLOAD_URL:-}" ]; then
        libscript_download "${ANSIBLE_GALAXY_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/ansible-galaxy/ansible-galaxy-${VERSION}.tar.gz"
      else
        log_warn "ANSIBLE_GALAXY_DOWNLOAD_URL is not defined for ansible-galaxy ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install)
    if [ "$ANSIBLE_GALAXY_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'ansible-galaxy'
    else
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/ansible-galaxy/${EXACT_VERSION}"
      if [ ! -x "${TARGET_DIR}/bin/ansible-galaxy" ]; then
        log_info "Installing ansible-galaxy ${VERSION} natively to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}/bin"
        if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/ansible-galaxy/"*"${VERSION}"* >/dev/null 2>&1; then
          log_info 'Extracting from cache...'
          cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/ansible-galaxy/" -maxdepth 1 -type f -name "*${VERSION}*" 2>/dev/null | head -n 1 || true)
          if [ -n "$cache_file" ]; then
            if case "$cache_file" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "$cache_file" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "$cache_file" in *.zip) true;; *) false;; esac; then
              unzip -q "$cache_file" -d "${TARGET_DIR}" || true
            else
              cp "$cache_file" "${TARGET_DIR}/bin/ansible-galaxy" || true
              chmod +x "${TARGET_DIR}/bin/ansible-galaxy" || true
            fi
          fi
        else
          if [ -n "${ANSIBLE_GALAXY_DOWNLOAD_URL:-}" ]; then
            TEMP_FILE=$(mktemp)
            libscript_download "${ANSIBLE_GALAXY_DOWNLOAD_URL:-}" "${TEMP_FILE}"
            if case "${ANSIBLE_GALAXY_DOWNLOAD_URL:-}" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "${TEMP_FILE}" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "${ANSIBLE_GALAXY_DOWNLOAD_URL:-}" in *.zip) true;; *) false;; esac; then
              unzip -q "${TEMP_FILE}" -d "${TARGET_DIR}" || true
            else
              cp "${TEMP_FILE}" "${TARGET_DIR}/bin/ansible-galaxy" || true
              chmod +x "${TARGET_DIR}/bin/ansible-galaxy" || true
            fi
            rm -f "${TEMP_FILE}"
          else
            if [ "$UNAME_LOWER" = "linux" ] || [ "$UNAME_LOWER" = "freebsd" ] || [ "$UNAME_LOWER" = "sunos" ] || [ "$UNAME_LOWER" = "darwin" ]; then
              log_info 'Falling back to system package manager or pip for ansible-galaxy...'
              if command -v brew >/dev/null 2>&1; then
                libscript_depends_via brew ansible || true
              fi
              libscript_depends 'ansible-galaxy' || true
              if ! command -v ansible-galaxy >/dev/null 2>&1; then
                if command -v uv >/dev/null 2>&1; then
                  uv tool install ansible-core || true
                elif command -v pipx >/dev/null 2>&1; then
                  pipx install ansible-core || true
                elif command -v python3 >/dev/null 2>&1 && python3 -m pip --version >/dev/null 2>&1; then
                  python3 -m pip install --quiet ansible-core || true
                fi
              fi
              if command -v ansible-galaxy >/dev/null 2>&1; then
                ln -sf "$(command -v ansible-galaxy)" "${TARGET_DIR}/bin/ansible-galaxy"
              elif [ -x "${HOME}/.local/bin/ansible-galaxy" ]; then
                ln -sf "${HOME}/.local/bin/ansible-galaxy" "${TARGET_DIR}/bin/ansible-galaxy"
              fi
            else
              log_warn "No download URL provided for ansible-galaxy ${VERSION}."
            fi
          fi
        fi
      else
        log_info "ansible-galaxy ${VERSION} is already installed."
      fi
      libscript_symlink_alias "ansible-galaxy" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "ansible-galaxy" "$ACTION" "$VERSION" "${ANSIBLE_GALAXY_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
