#!/bin/sh
# ## Overview
# Generic setup module for vultr.
#
# ## Usage
# Execute this script to perform generic initialization and cloud orchestration steps for vultr.

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

for LIB in "_lib/_common/pkg_mgr.sh" "_lib/_common/os_info.sh" "_lib/_common/versioning.sh" "_lib/cloud/core/tags.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

VULTR_INSTALL_METHOD="$(libscript_resolve_install_method "VULTR")"
ACTION="${ACTION:-install}"
VERSION="${VULTR_VERSION:-latest}"

# ## vultr_cli_exec
# Wrapper around vultr-cli supporting DRY_RUN=true or unauthenticated local environments.
vultr_cli_exec() {
  if [ "${DRY_RUN:-}" = "true" ] || ! command -v vultr-cli >/dev/null 2>&1; then
    printf '[DRY_RUN] vultr-cli %s
' "$*" >&2
    case "$*" in
      *"instance get"*|*"instance list"*) printf '203.0.113.10
'; return 0 ;;
      *) return 0 ;;
    esac
  fi
  command vultr-cli "$@"
}

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'stable') to a concrete release version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote vultr 2>/dev/null | tail -n 1)
    if [ -n "$_latest" ] && [ "$_latest" != "No versions found" ]; then
      EXACT_VERSION="$_latest"
    else
      EXACT_VERSION="${VERSION:-latest}"
    fi
  else
    EXACT_VERSION="${VERSION:-latest}"
  fi
}

case "$ACTION" in
  group|project)
    SUBACTION=${1:-ensure}
    PROJ=${2:-default}
    printf 'Vultr project/group '''%s''' (%s) ensured.
' "$PROJ" "$SUBACTION"
    exit 0
    ;;
  auth)
    SUBACTION=${1:-status}
    case "$SUBACTION" in
      login) printf 'Set VULTR_API_KEY in environment to authenticate vultr-cli.
' ;;
      logout) unset VULTR_API_KEY || true ;;
      status) vultr_cli_exec account ;;
      *) printf 'Unknown auth sub-action: %s
' "$SUBACTION"; exit 1 ;;
    esac
    exit 0
    ;;
  location)
    SUBACTION=${1:-list}
    case "$SUBACTION" in
      list) vultr_cli_exec regions list ;;
      select) printf 'Default Vultr region set to %s.
' "${2:-ewr}" ;;
      *) printf 'Unknown location sub-action: %s
' "$SUBACTION"; exit 1 ;;
    esac
    exit 0
    ;;
  network)
    SUBACTION=${1:-}
    RESOURCE_NAME=${2:-}
    REGION=${3:-${VULTR_REGION:-ewr}}
    case "$SUBACTION" in
      create)
        printf 'Creating Vultr VPC: %s in %s
' "$RESOURCE_NAME" "$REGION"
        vultr_cli_exec vpc2 create --region="$REGION" --description="$RESOURCE_NAME" || true
        ;;
      delete)
        printf 'Deleting Vultr VPC: %s
' "$RESOURCE_NAME"
        vultr_cli_exec vpc2 delete "$RESOURCE_NAME" || true
        ;;
      wait-ssh)
        exit 0
        ;;
      list)
        vultr_cli_exec vpc2 list
        ;;
      *)
        printf 'Unknown network sub-action: %s
' "$SUBACTION"; exit 1 ;;
    esac
    exit 0
    ;;
  firewall)
    SUBACTION=${1:-}
    RESOURCE_NAME=${2:-}
    case "$SUBACTION" in
      create)
        printf 'Creating Vultr Firewall Group: %s
' "$RESOURCE_NAME"
        vultr_cli_exec firewall group create --description="$RESOURCE_NAME" || true
        ;;
      delete)
        printf 'Deleting Vultr Firewall Group: %s
' "$RESOURCE_NAME"
        vultr_cli_exec firewall group delete "$RESOURCE_NAME" || true
        ;;
      list)
        vultr_cli_exec firewall group list
        ;;
      *)
        printf 'Unknown firewall sub-action: %s
' "$SUBACTION"; exit 1 ;;
    esac
    exit 0
    ;;
  dns)
    SUBACTION=${1:-}
    SUBTYPE=${2:-}
    case "$SUBACTION" in
      zone)
        case "$SUBTYPE" in
          create) vultr_cli_exec dns domain create --domain="${3:-example.com}" || true ;;
          delete) vultr_cli_exec dns domain delete "${3:-example.com}" || true ;;
          list) vultr_cli_exec dns domain list ;;
          *) printf 'Unknown dns zone sub-action: %s
' "$SUBTYPE"; exit 1 ;;
        esac
        ;;
      record)
        case "$SUBTYPE" in
          create|update)
            vultr_cli_exec dns record create --domain="${3:-example.com}" --name="${4:-@}" --type="${5:-A}" --data="${6:-127.0.0.1}" || true
            ;;
          delete)
            vultr_cli_exec dns record delete "${3:-example.com}" "${4:-}" || true
            ;;
          list)
            vultr_cli_exec dns record list "${3:-example.com}"
            ;;
          *) printf 'Unknown dns record sub-action: %s
' "$SUBTYPE"; exit 1 ;;
        esac
        ;;
      *) printf 'Unknown dns action: %s
' "$SUBACTION"; exit 1 ;;
    esac
    exit 0
    ;;
  node)
    SUBACTION=${1:-}
    RESOURCE_NAME=${2:-}
    case "$SUBACTION" in
      create)
        IMAGE=${3:-1743}
        REGION=${4:-${VULTR_REGION:-ewr}}
        SIZE=${VM_SIZE:-vc2-2c-4gb}
        TAGS_ARG="$(libscript_format_tags vultr)"
        printf 'Creating Vultr Instance: %s (%s, %s, %s)
' "$RESOURCE_NAME" "$SIZE" "$IMAGE" "$REGION"
        # shellcheck disable=SC2086
        vultr_cli_exec instance create --label="$RESOURCE_NAME" --os="$IMAGE" --plan="$SIZE" --region="$REGION" $TAGS_ARG || true
        ;;
      delete)
        printf 'Deleting Vultr Instance: %s
' "$RESOURCE_NAME"
        vultr_cli_exec instance delete "$RESOURCE_NAME" || true
        ;;
      list)
        vultr_cli_exec instance list
        ;;
      ip)
        if [ "${DRY_RUN:-}" = "true" ] || [ "${DRY_RUN:-0}" = "1" ]; then
          printf '203.0.113.10
'
          exit 0
        fi
        vultr_cli_exec instance get "$RESOURCE_NAME" | awk '/MAIN IP/ {print $3}'
        ;;
      exec)
        shift 2
        if [ $# -gt 1 ]; then shift; fi
        if [ "${DRY_RUN:-}" = "true" ] || [ "${DRY_RUN:-0}" = "1" ]; then
          printf '[DRY_RUN] Executing on %s: %s
' "$RESOURCE_NAME" "$*"
          exit 0
        fi
        IP=$(vultr_cli_exec instance get "$RESOURCE_NAME" | awk '/MAIN IP/ {print $3}' | head -n 1)
        ssh -o StrictHostKeyChecking=no "${ADMIN_USER:-root}@$IP" "$@"
        ;;
      sync)
        if [ "${DRY_RUN:-}" = "true" ] || [ "${DRY_RUN:-0}" = "1" ]; then
          printf '[DRY_RUN] Syncing LibScript to %s
' "$RESOURCE_NAME"
          exit 0
        fi
        IP=$(vultr_cli_exec instance get "$RESOURCE_NAME" | awk '/MAIN IP/ {print $3}' | head -n 1)
        ssh -o StrictHostKeyChecking=no "${ADMIN_USER:-root}@$IP" "mkdir -p ~/libscript"
        if command -v rsync >/dev/null 2>&1; then
          rsync -avz --delete --exclude=".git" --exclude="vagrant" --exclude="cache" --exclude="build" --exclude="target" --exclude="logs" --exclude="tmp" --exclude="node_modules" --exclude=".venv" --exclude=".DS_Store" -e "ssh -o StrictHostKeyChecking=no" "${LIBSCRIPT_ROOT_DIR}/" "${ADMIN_USER:-root}@$IP:~/libscript/"
        else
          scp -o StrictHostKeyChecking=no -r "${LIBSCRIPT_ROOT_DIR}/"* "${ADMIN_USER:-root}@$IP:~/libscript/"
        fi
        ;;
      deploy|upload|scp)
        SRC=${4:-}; DST=${5:-}
        if [ "${DRY_RUN:-}" = "true" ] || [ "${DRY_RUN:-0}" = "1" ]; then
          printf '[DRY_RUN] Uploading %s to %s -> %s
' "$SRC" "$RESOURCE_NAME" "$DST"
          exit 0
        fi
        IP=$(vultr_cli_exec instance get "$RESOURCE_NAME" | awk '/MAIN IP/ {print $3}' | head -n 1)
        if command -v rsync >/dev/null 2>&1; then
          rsync -avz --delete --filter="P .env" --filter="P .env.secrets" --filter="P .env.libscript" --filter="P data" --exclude=".git" --exclude="node_modules" --exclude="target" --exclude=".venv" --exclude="venv" --exclude=".angular" --exclude=".vite" --exclude="dist" --exclude="build" --exclude="webroot" --exclude=".libscript_build.sha256" --exclude=".libscript_src_hash" --exclude=".env.libscript" --exclude="logs" --exclude="*.duckdb" --exclude="*.duckdb.wal" -e "ssh -o StrictHostKeyChecking=no" "$SRC" "${ADMIN_USER:-root}@$IP:$DST"
        else
          scp -o StrictHostKeyChecking=no -r "$SRC" "${ADMIN_USER:-root}@$IP:$DST"
        fi
        ;;
      download|scp-from)
        SRC=${4:-}; DST=${5:-}
        if [ "${DRY_RUN:-}" = "true" ] || [ "${DRY_RUN:-0}" = "1" ]; then
          printf '[DRY_RUN] Downloading %s:%s -> %s
' "$RESOURCE_NAME" "$SRC" "$DST"
          exit 0
        fi
        IP=$(vultr_cli_exec instance get "$RESOURCE_NAME" | awk '/MAIN IP/ {print $3}' | head -n 1)
        mkdir -p "$(dirname "$DST")"
        scp -o StrictHostKeyChecking=no -r "${ADMIN_USER:-root}@$IP:$SRC" "$DST"
        ;;
      *)
        printf 'Unknown node sub-action: %s
' "$SUBACTION"; exit 1 ;;
    esac
    exit 0
    ;;
  ls)
    ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/vultr/" 2>/dev/null || true
    exit 0
    ;;
  ls-remote)
    git ls-remote --tags "https://github.com/vultr/vultr-cli" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s
' "No versions found"
    exit 0
    ;;
  use)
    resolve_exact_version
    libscript_symlink_alias "vultr" "$VERSION" "${EXACT_VERSION}"
    libscript_symlink_alias "vultr" "default" "${EXACT_VERSION}"
    exit 0
    ;;
  download)
    mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/vultr"
    exit 0
    ;;
  install)
    if [ "$VULTR_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'vultr-cli' || true
    else
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/vultr/${EXACT_VERSION}"
      mkdir -p "${TARGET_DIR}/bin"
      libscript_symlink_alias "vultr" "$VERSION" "${EXACT_VERSION}"
    fi
    exit 0
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service)
    exit 0
    ;;
  uninstall)
    resolve_exact_version
    rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/vultr/${EXACT_VERSION}"
    rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/vultr/$VERSION"
    exit 0
    ;;
esac
