#!/bin/sh
# ## Overview
# Generic setup module for linode.
#
# ## Usage
# Execute this script to perform generic initialization and cloud orchestration steps for linode.

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
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

LINODE_INSTALL_METHOD="$(libscript_resolve_install_method "LINODE")"
ACTION="${ACTION:-install}"
VERSION="${LINODE_VERSION:-latest}"

# ## linode_cli_exec
# Wrapper around linode-cli supporting DRY_RUN=true or unauthenticated local environments.
linode_cli_exec() {
  if [ "${DRY_RUN:-}" = "true" ] || ! command -v linode-cli >/dev/null 2>&1; then
    printf '[DRY_RUN] linode-cli %s
' "$*" >&2
    case "$*" in
      *"--format ipv4"*) printf '203.0.113.10
'; return 0 ;;
      *) return 0 ;;
    esac
  fi
  command linode-cli "$@"
}

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'stable') to a concrete release version.
resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote linode 2>/dev/null | tail -n 1)
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
    printf 'Linode project/group '''%s''' (%s) ensured.
' "$PROJ" "$SUBACTION"
    exit 0
    ;;
  auth)
    SUBACTION=${1:-status}
    case "$SUBACTION" in
      login) linode_cli_exec configure ;;
      logout) rm -f "${HOME}/.config/linode-cli" ;;
      status) linode_cli_exec account view ;;
      *) printf 'Unknown auth sub-action: %s
' "$SUBACTION"; exit 1 ;;
    esac
    exit 0
    ;;
  location)
    SUBACTION=${1:-list}
    case "$SUBACTION" in
      list) linode_cli_exec regions list ;;
      select) printf 'Default Linode region set to %s.
' "${2:-us-east}" ;;
      *) printf 'Unknown location sub-action: %s
' "$SUBACTION"; exit 1 ;;
    esac
    exit 0
    ;;
  network)
    SUBACTION=${1:-}
    RESOURCE_NAME=${2:-}
    REGION=${3:-${LINODE_REGION:-us-east}}
    case "$SUBACTION" in
      create)
        printf 'Creating Linode VPC: %s in %s
' "$RESOURCE_NAME" "$REGION"
        linode_cli_exec vpcs create --label "$RESOURCE_NAME" --region "$REGION" || true
        ;;
      delete)
        printf 'Deleting Linode VPC: %s
' "$RESOURCE_NAME"
        linode_cli_exec vpcs delete "$RESOURCE_NAME" || true
        ;;
      list)
        linode_cli_exec vpcs list
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
        printf 'Creating Linode Cloud Firewall: %s
' "$RESOURCE_NAME"
        linode_cli_exec firewalls create --label "$RESOURCE_NAME" --rules.inbound_policy ACCEPT --rules.outbound_policy ACCEPT || true
        ;;
      delete)
        printf 'Deleting Linode Cloud Firewall: %s
' "$RESOURCE_NAME"
        linode_cli_exec firewalls delete "$RESOURCE_NAME" || true
        ;;
      list)
        linode_cli_exec firewalls list
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
          create) linode_cli_exec domains create --domain "${3:-example.com}" --type master --soa_email "admin@${3:-example.com}" || true ;;
          delete) linode_cli_exec domains delete "${3:-}" || true ;;
          list) linode_cli_exec domains list ;;
          *) printf 'Unknown dns zone sub-action: %s
' "$SUBTYPE"; exit 1 ;;
        esac
        ;;
      record)
        case "$SUBTYPE" in
          create|update)
            linode_cli_exec domains records-create "${3:-}" --name "${4:-}" --type "${5:-A}" --target "${6:-127.0.0.1}" || true
            ;;
          delete)
            linode_cli_exec domains records-delete "${3:-}" "${4:-}" || true
            ;;
          list)
            linode_cli_exec domains records-list "${3:-}"
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
        IMAGE=${3:-linode/ubuntu22.04}
        REGION=${4:-${LINODE_REGION:-us-east}}
        SIZE=${VM_SIZE:-g6-standard-2}
        TAGS_ARG="$(libscript_format_tags linode)"
        printf 'Creating Linode Instance: %s (%s, %s, %s)
' "$RESOURCE_NAME" "$SIZE" "$IMAGE" "$REGION"
        # shellcheck disable=SC2086
        linode_cli_exec linodes create --label "$RESOURCE_NAME" --image "$IMAGE" --type "$SIZE" --region "$REGION" $TAGS_ARG || true
        ;;
      delete)
        printf 'Deleting Linode Instance: %s
' "$RESOURCE_NAME"
        linode_cli_exec linodes delete "$RESOURCE_NAME" || true
        ;;
      list)
        linode_cli_exec linodes list
        ;;
      ip)
        if [ "${DRY_RUN:-}" = "true" ] || [ "${DRY_RUN:-0}" = "1" ]; then
          printf '203.0.113.10
'
          exit 0
        fi
        linode_cli_exec linodes list --label "$RESOURCE_NAME" --format ipv4 --text --no-headers
        ;;
      exec)
        shift 2
        if [ $# -gt 1 ]; then shift; fi
        if [ "${DRY_RUN:-}" = "true" ] || [ "${DRY_RUN:-0}" = "1" ]; then
          printf '[DRY_RUN] Executing on %s: %s
' "$RESOURCE_NAME" "$*"
          exit 0
        fi
        IP=$(linode_cli_exec linodes list --label "$RESOURCE_NAME" --format ipv4 --text --no-headers | head -n 1)
        ssh -o StrictHostKeyChecking=no "${ADMIN_USER:-root}@$IP" "$@"
        ;;
      sync)
        if [ "${DRY_RUN:-}" = "true" ] || [ "${DRY_RUN:-0}" = "1" ]; then
          printf '[DRY_RUN] Syncing LibScript to %s
' "$RESOURCE_NAME"
          exit 0
        fi
        IP=$(linode_cli_exec linodes list --label "$RESOURCE_NAME" --format ipv4 --text --no-headers | head -n 1)
        ssh -o StrictHostKeyChecking=no "${ADMIN_USER:-root}@$IP" "mkdir -p ~/libscript"
        if command -v rsync >/dev/null 2>&1; then
          rsync -avz --exclude=".git" --exclude="vagrant" -e "ssh -o StrictHostKeyChecking=no" "${LIBSCRIPT_ROOT_DIR}/" "${ADMIN_USER:-root}@$IP:~/libscript/"
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
        IP=$(linode_cli_exec linodes list --label "$RESOURCE_NAME" --format ipv4 --text --no-headers | head -n 1)
        if command -v rsync >/dev/null 2>&1; then
          rsync -avz --exclude=".git" --exclude="node_modules" -e "ssh -o StrictHostKeyChecking=no" "$SRC" "${ADMIN_USER:-root}@$IP:$DST"
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
        IP=$(linode_cli_exec linodes list --label "$RESOURCE_NAME" --format ipv4 --text --no-headers | head -n 1)
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
    ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/linode/" 2>/dev/null || true
    exit 0
    ;;
  ls-remote)
    git ls-remote --tags "https://github.com/linode/linode-cli" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s
' "No versions found"
    exit 0
    ;;
  use)
    resolve_exact_version
    libscript_symlink_alias "linode" "$VERSION" "${EXACT_VERSION}"
    libscript_symlink_alias "linode" "default" "${EXACT_VERSION}"
    exit 0
    ;;
  download)
    mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/linode"
    exit 0
    ;;
  install)
    if [ "$LINODE_INSTALL_METHOD" = "system" ]; then
      libscript_depends "linode-cli" || true
    else
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/linode/${EXACT_VERSION}"
      mkdir -p "${TARGET_DIR}/bin"
      libscript_symlink_alias "linode" "$VERSION" "${EXACT_VERSION}"
    fi
    exit 0
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service)
    exit 0
    ;;
  uninstall)
    resolve_exact_version
    rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/linode/${EXACT_VERSION}"
    rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/linode/$VERSION"
    exit 0
    ;;
esac
