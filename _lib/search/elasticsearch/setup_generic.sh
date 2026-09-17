#!/bin/sh
# ## Overview
# Generic setup module for Elasticsearch search engine.
# 
# ## Usage
# Performs cross-platform installation and management for Elasticsearch.

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

ELASTICSEARCH_INSTALL_METHOD="$(libscript_resolve_install_method "ELASTICSEARCH")"
ACTION="${ACTION:-install}"
VERSION="${ELASTICSEARCH_VERSION:-7.17.21}"

case "$ACTION" in
  ls)
    if command -v elasticsearch >/dev/null 2>&1; then
      elasticsearch --version
    else
      printf 'elasticsearch not installed
'
    fi
    exit 0
    ;;
  ls-remote)
    printf '7.17.21
8.13.0
'
    exit 0
    ;;
  install)
    log_info "Installing Elasticsearch (${VERSION}) via ${ELASTICSEARCH_INSTALL_METHOD}..."
    if command -v elasticsearch >/dev/null 2>&1; then
      log_info "elasticsearch is already available on the system."
    elif [ "${UNAME_LOWER}" = "freebsd" ]; then
      libscript_depends "textproc/elasticsearch7" || true
    else
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/elasticsearch/${VERSION}"
      if [ ! -f "${TARGET_DIR}/bin/elasticsearch" ]; then
        mkdir -p "${TARGET_DIR}"
        OS_NAME="linux"
        [ "${UNAME_LOWER}" = "darwin" ] && OS_NAME="darwin"
        ARCH_NAME="x86_64"
        [ "${ARCH:-$(uname -m)}" = "aarch64" ] || [ "${ARCH:-$(uname -m)}" = "arm64" ] && ARCH_NAME="aarch64"
        TAR_URL="https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${VERSION}-${OS_NAME}-${ARCH_NAME}.tar.gz"
        TEMP_TAR=$(mktemp)
        if libscript_download "${TAR_URL}" "${TEMP_TAR}" 2>/dev/null; then
          tar -xzf "${TEMP_TAR}" -C "${TARGET_DIR}" --strip-components=1 || true
          rm -f "${TEMP_TAR}"
        else
          rm -f "${TEMP_TAR}"
          log_info "Downloading generic Elasticsearch tarball..."
          libscript_depends "languages/java" || true
        fi
      fi
    fi
    ;;
  start|stop|restart|status|health|logs|up|down)
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
    export SCRIPT_NAME
    . "${SCRIPT_NAME}"
    service_name="${LIBSCRIPT_SERVICE_NAME:-elasticsearch}"
    libscript_service "$ACTION" "$service_name" "$@"
    exit 0
    ;;
  uninstall)
    log_info "Uninstalling Elasticsearch..."
    rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/elasticsearch/${VERSION}"
    exit 0
    ;;
  test)
    if command -v elasticsearch >/dev/null 2>&1; then
      elasticsearch --version
      exit 0
    elif [ -x "${LIBSCRIPT_HOME:-$HOME/.libscript}/elasticsearch/${VERSION}/bin/elasticsearch" ]; then
      "${LIBSCRIPT_HOME:-$HOME/.libscript}/elasticsearch/${VERSION}/bin/elasticsearch" --version
      exit 0
    else
      printf 'elasticsearch binary not found
' >&2
      exit 1
    fi
    ;;
esac
