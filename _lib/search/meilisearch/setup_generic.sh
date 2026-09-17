#!/bin/sh
# ## Overview
# Generic setup module for Meilisearch.
# 
# ## Usage
# Performs cross-platform binary download or package manager installation of Meilisearch.

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"
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

MEILISEARCH_INSTALL_METHOD="$(libscript_resolve_install_method "MEILISEARCH")"
ACTION="${ACTION:-install}"
VERSION="${MEILISEARCH_VERSION:-v1.36.0}"

# ## resolve_exact_version
# Executes resolve_exact_version functionality.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ]; then
    EXACT_VERSION="v1.36.0"
  else
    EXACT_VERSION="${VERSION}"
  fi
}

case "$ACTION" in
  ls)
    if command -v meilisearch >/dev/null 2>&1; then
      meilisearch --version
    else
      printf 'meilisearch not installed
'
    fi
    exit 0
    ;;
  ls-remote)
    printf 'v1.34.0
v1.35.0
v1.36.0
'
    exit 0
    ;;
  install)
    resolve_exact_version
    log_info "Installing Meilisearch (${EXACT_VERSION}) via ${MEILISEARCH_INSTALL_METHOD}..."
    TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/meilisearch/${EXACT_VERSION}"
    if [ -f "${TARGET_DIR}/bin/meilisearch" ]; then
      log_info "Meilisearch ${EXACT_VERSION} is already installed in ${TARGET_DIR}."
    else
      mkdir -p "${TARGET_DIR}/bin"
      # Resolve binary download URL
      OS_NAME="linux"
      if [ "${UNAME_LOWER}" = "darwin" ]; then
        OS_NAME="macos"
      elif [ "${UNAME_LOWER}" = "freebsd" ]; then
        OS_NAME="freebsd"
      fi

      ARCH_NAME="amd64"
      case "${ARCH:-$(uname -m)}" in
        x86_64|amd64) ARCH_NAME="amd64" ;;
        aarch64|arm64)
          if [ "$OS_NAME" = "macos" ]; then
            ARCH_NAME="apple-silicon"
          else
            ARCH_NAME="aarch64"
          fi
          ;;
      esac

      BIN_URL="https://github.com/meilisearch/meilisearch/releases/download/${EXACT_VERSION}/meilisearch-${OS_NAME}-${ARCH_NAME}"
      TEMP_BIN=$(mktemp)
      if libscript_download "${BIN_URL}" "${TEMP_BIN}" 2>/dev/null; then
        mv "${TEMP_BIN}" "${TARGET_DIR}/bin/meilisearch"
        chmod +x "${TARGET_DIR}/bin/meilisearch"
      else
        rm -f "${TEMP_BIN}"
        if command -v meilisearch >/dev/null 2>&1; then
          ln -sf "$(command -v meilisearch)" "${TARGET_DIR}/bin/meilisearch"
        elif [ "${UNAME_LOWER}" = "freebsd" ]; then
          libscript_depends "textproc/meilisearch" || true
        elif command -v cargo >/dev/null 2>&1; then
          log_info "Compiling meilisearch from source via cargo..."
          cargo install meilisearch --root "${TARGET_DIR}" || true
        else
          log_warn "Unable to download or install Meilisearch binary."
        fi
      fi
    fi
    libscript_symlink_alias "meilisearch" "$VERSION" "${EXACT_VERSION}"
    ;;
  start|stop|restart|status|health|logs|up|down)
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
    export SCRIPT_NAME
    . "${SCRIPT_NAME}"
    service_name="${LIBSCRIPT_SERVICE_NAME:-meilisearch}"
    libscript_service "$ACTION" "$service_name" "$@"
    exit 0
    ;;
  install-service)
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
    export SCRIPT_NAME
    . "${SCRIPT_NAME}"
    service_name="${LIBSCRIPT_SERVICE_NAME:-meilisearch}"
    libscript_install_service "$service_name" "$@"
    exit 0
    ;;
  uninstall-service)
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
    export SCRIPT_NAME
    . "${SCRIPT_NAME}"
    service_name="${LIBSCRIPT_SERVICE_NAME:-meilisearch}"
    libscript_uninstall_service "$service_name" "$@"
    exit 0
    ;;
  uninstall)
    resolve_exact_version
    log_info "Uninstalling Meilisearch ${EXACT_VERSION}..."
    rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/meilisearch/${EXACT_VERSION}"
    rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/meilisearch/${VERSION}"
    exit 0
    ;;
  test)
    if command -v meilisearch >/dev/null 2>&1; then
      meilisearch --version
      exit 0
    elif [ -x "${LIBSCRIPT_HOME:-$HOME/.libscript}/meilisearch/${VERSION}/bin/meilisearch" ]; then
      "${LIBSCRIPT_HOME:-$HOME/.libscript}/meilisearch/${VERSION}/bin/meilisearch" --version
      exit 0
    else
      printf 'meilisearch binary not found
' >&2
      exit 1
    fi
    ;;
esac
