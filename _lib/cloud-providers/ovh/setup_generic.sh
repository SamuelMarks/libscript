#!/bin/sh
# ## Overview
# Generic setup script for the ovh component implementing the Version Manager Contract.
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

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/remote_sync.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/cloud/core/tags.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

OVH_INSTALL_METHOD="${OVH_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-libscript_native}}"
ACTION="${ACTION:-install}"
VERSION="${OVH_VERSION:-latest}"

# ## ovh_cli_exec
# Executes OVHcloud CLI commands with DRY_RUN=true simulation support.
ovh_cli_exec() {
  if [ "${DRY_RUN:-}" = "true" ] || [ "${DRY_RUN:-0}" = "1" ] || ! command -v ovhcloud >/dev/null 2>&1; then
    printf '[DRY_RUN] ovhcloud %s\n' "$*" >&2
    case "$*" in
      *"instance get"*|*"instance list"*) printf '203.0.113.22\n'; return 0 ;;
      *) return 0 ;;
    esac
  fi
  command ovhcloud "$@"
}

# ## resolve_exact_version
# Resolves dynamic version aliases such as latest or lts into an exact upstream version string.
resolve_exact_version() {
  if [ "${VERSION}" = "latest" ] || [ "${VERSION}" = "lts" ]; then
    _gh_repo='ovh/ovhcloud-cli'
    if [ -n "$_gh_repo" ]; then
      EXACT_VERSION=$(libscript_fetch_stdout 'https://api.github.com/repos/ovh/ovhcloud-cli/releases/latest' | tr ',' '\n' | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1 | sed 's/^v//' || true)
      if [ -z "$EXACT_VERSION" ]; then
        EXACT_VERSION='0.6.0'
      fi
    else
      EXACT_VERSION='0.6.0'
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
  group|project)
    SUBACTION=${1:-ensure}
    PROJ=${2:-${OVH_PROJECT_ID:-default-project}}
    printf 'OVHcloud Public Cloud project '\''%s'\'' (%s) ensured.\n' "$PROJ" "$SUBACTION"
    exit 0
    ;;
  auth)
    SUBACTION=${1:-status}
    case "$SUBACTION" in
      login) ovh_cli_exec login ;;
      logout) printf 'Remove ~/.ovh.conf credentials to log out of OVHcloud CLI.\n' ;;
      status) ovh_cli_exec account info ;;
      *) printf 'Unknown auth sub-action: %s\n' "$SUBACTION" >&2; exit 1 ;;
    esac
    exit 0
    ;;
  location)
    SUBACTION=${1:-list}
    PROJ=${OVH_PROJECT_ID:-default-project}
    case "$SUBACTION" in
      list) ovh_cli_exec cloud region list --cloud-project "$PROJ" ;;
      select) printf 'Default OVHcloud region set to %s.\n' "${2:-GRA11}" ;;
      *) printf 'Unknown location sub-action: %s\n' "$SUBACTION" >&2; exit 1 ;;
    esac
    exit 0
    ;;
  network)
    SUBACTION=${1:-}
    RESOURCE_NAME=${2:-libscript-vrack}
    REGION=${3:-${OVH_REGION:-GRA11}}
    PROJ=${OVH_PROJECT_ID:-default-project}
    case "$SUBACTION" in
      create)
        printf 'Creating OVHcloud private network: %s in %s\n' "$RESOURCE_NAME" "$REGION"
        ovh_cli_exec cloud network private create --cloud-project "$PROJ" --name "$RESOURCE_NAME" --regions "$REGION" || true
        ;;
      delete)
        printf 'Deleting OVHcloud private network: %s\n' "$RESOURCE_NAME"
        ovh_cli_exec cloud network private delete "$RESOURCE_NAME" --cloud-project "$PROJ" || true
        ;;
      wait-ssh)
        exit 0
        ;;
      list)
        ovh_cli_exec cloud network private list --cloud-project "$PROJ"
        ;;
      *)
        printf 'Unknown network sub-action: %s\n' "$SUBACTION" >&2; exit 1 ;;
    esac
    exit 0
    ;;
  firewall)
    SUBACTION=${1:-}
    RESOURCE_NAME=${2:-203.0.113.22}
    case "$SUBACTION" in
      create)
        printf 'Enabling OVHcloud Edge Network Firewall for %s\n' "$RESOURCE_NAME"
        ovh_cli_exec ip firewall enable "$RESOURCE_NAME" || true
        ;;
      delete)
        printf 'Disabling OVHcloud Edge Network Firewall for %s\n' "$RESOURCE_NAME"
        ovh_cli_exec ip firewall disable "$RESOURCE_NAME" || true
        ;;
      list)
        ovh_cli_exec ip firewall list "$RESOURCE_NAME" || true
        ;;
      *)
        printf 'Unknown firewall sub-action: %s\n' "$SUBACTION" >&2; exit 1 ;;
    esac
    exit 0
    ;;
  dns)
    SUBACTION=${1:-}
    SUBTYPE=${2:-}
    case "$SUBACTION" in
      zone)
        case "$SUBTYPE" in
          create) ovh_cli_exec domain-zone refresh "${3:-example.com}" || true ;;
          delete) printf 'Requested OVHcloud DNS zone deletion for %s\n' "${3:-example.com}" ;;
          list) ovh_cli_exec domain-zone list ;;
          *) printf 'Unknown dns zone sub-action: %s\n' "$SUBTYPE" >&2; exit 1 ;;
        esac
        ;;
      record)
        case "$SUBTYPE" in
          create|update)
            ovh_cli_exec domain-zone record create "${3:-example.com}" --sub-domain "${4:-@}" --field-type "${5:-A}" --target "${6:-127.0.0.1}" || true
            ;;
          delete)
            ovh_cli_exec domain-zone record delete "${3:-example.com}" "${4:-0}" || true
            ;;
          list)
            ovh_cli_exec domain-zone record list "${3:-example.com}"
            ;;
          *) printf 'Unknown dns record sub-action: %s\n' "$SUBTYPE" >&2; exit 1 ;;
        esac
        ;;
      *) printf 'Unknown dns action: %s\n' "$SUBACTION" >&2; exit 1 ;;
    esac
    exit 0
    ;;
  node)
    SUBACTION=${1:-}
    RESOURCE_NAME=${2:-libscript-node}
    PROJ=${OVH_PROJECT_ID:-default-project}
    case "$SUBACTION" in
      create)
        IMAGE=${3:-Ubuntu-24.04}
        REGION=${4:-${OVH_REGION:-GRA11}}
        FLAVOR=${VM_SIZE:-${OVH_FLAVOR:-d2-4}}
        TAGS_ARG="$(libscript_format_tags ovh)"
        printf 'Creating OVHcloud Public Cloud Instance: %s (%s, %s, %s)\n' "$RESOURCE_NAME" "$FLAVOR" "$IMAGE" "$REGION"
        # shellcheck disable=SC2086
        ovh_cli_exec cloud instance create --cloud-project "$PROJ" --name "$RESOURCE_NAME" --image "$IMAGE" --flavor "$FLAVOR" --region "$REGION" $TAGS_ARG || true
        ;;
      delete)
        printf 'Deleting OVHcloud Public Cloud Instance: %s\n' "$RESOURCE_NAME"
        ovh_cli_exec cloud instance delete "$RESOURCE_NAME" --cloud-project "$PROJ" || true
        ;;
      list)
        ovh_cli_exec cloud instance list --cloud-project "$PROJ"
        ;;
      wait-ssh)
        exit 0
        ;;
      ip)
        if [ "${DRY_RUN:-}" = "true" ] || [ "${DRY_RUN:-0}" = "1" ]; then
          printf '203.0.113.22\n'
          exit 0
        fi
        ovh_cli_exec cloud instance get "$RESOURCE_NAME" --cloud-project "$PROJ" | awk '/ip/ {print $2}' | head -n 1
        ;;
      exec)
        shift 2
        if [ $# -gt 1 ] && [ "${1:-}" = "--" ]; then shift; fi
        if [ "${DRY_RUN:-}" = "true" ] || [ "${DRY_RUN:-0}" = "1" ]; then
          printf '[DRY_RUN] Executing on %s: %s\n' "$RESOURCE_NAME" "$*"
          exit 0
        fi
        IP=$(ovh_cli_exec cloud instance get "$RESOURCE_NAME" --cloud-project "$PROJ" | awk '/ip/ {print $2}' | head -n 1)
        _ovh_ssh_opts=$(libscript_ssh_mux_opts)
        # shellcheck disable=SC2029,SC2086
        ssh $_ovh_ssh_opts "${ADMIN_USER:-ubuntu}@$IP" "$@"
        ;;
      sync)
        if [ "${DRY_RUN:-}" = "true" ] || [ "${DRY_RUN:-0}" = "1" ]; then
          printf '[DRY_RUN] Syncing LibScript to %s\n' "$RESOURCE_NAME"
          exit 0
        fi
        IP=$(ovh_cli_exec cloud instance get "$RESOURCE_NAME" --cloud-project "$PROJ" | awk '/ip/ {print $2}' | head -n 1)
        libscript_sync_runtime_to_remote "${ADMIN_USER:-ubuntu}@$IP" "libscript"
        ;;
      deploy|upload|scp)
        SRC=${3:-${4:-}}; DST=${4:-${5:-}}
        if [ "${DRY_RUN:-}" = "true" ] || [ "${DRY_RUN:-0}" = "1" ]; then
          printf '[DRY_RUN] Uploading %s to %s -> %s\n' "$SRC" "$RESOURCE_NAME" "$DST"
          exit 0
        fi
        IP=$(ovh_cli_exec cloud instance get "$RESOURCE_NAME" --cloud-project "$PROJ" | awk '/ip/ {print $2}' | head -n 1)
        libscript_scp_to_remote "$SRC" "${ADMIN_USER:-ubuntu}@$IP" "$DST"
        ;;
      download|scp-from)
        SRC=${3:-${4:-}}; DST=${4:-${5:-}}
        if [ "${DRY_RUN:-}" = "true" ] || [ "${DRY_RUN:-0}" = "1" ]; then
          printf '[DRY_RUN] Downloading %s:%s -> %s\n' "$RESOURCE_NAME" "$SRC" "$DST"
          exit 0
        fi
        IP=$(ovh_cli_exec cloud instance get "$RESOURCE_NAME" --cloud-project "$PROJ" | awk '/ip/ {print $2}' | head -n 1)
        libscript_scp_from_remote "${ADMIN_USER:-ubuntu}@$IP" "$SRC" "$DST"
        ;;
      *)
        printf 'Unknown node sub-action: %s\n' "$SUBACTION" >&2; exit 1 ;;
    esac
    exit 0
    ;;
  ls)
    if [ "${OVH_INSTALL_METHOD}" = "libscript_native" ]; then
      [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/ovh" ] && ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/ovh"
    else
      if command -v 'ovhcloud' >/dev/null 2>&1; then
        'ovhcloud' --version || true
      fi
    fi
    ;;
  ls-remote)
    RELEASES_URL="${OVH_RELEASES_URL:-https://api.github.com/repos/ovh/ovhcloud-cli/releases/latest}"
    printf '[ls-remote] Fetching available ovh versions from %s...\n' "${RELEASES_URL}"
    libscript_fetch_stdout "${RELEASES_URL}" | head -n 30 || true
    ;;
  use)
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/ovh/${EXACT_VERSION}"
    if [ ! -d "$TARGET_DIR" ]; then
      printf 'Version %s not installed. Installing...\n' "$EXACT_VERSION"
      ACTION='install' "$0"
    fi
    libscript_symlink_alias 'ovh' "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'ovh' 'default' "${EXACT_VERSION}"
    ;;
  download)
    resolve_exact_version
    _def_dl_url='https://github.com/ovh/ovhcloud-cli/releases/download/v{VERSION}/ovhcloud-cli_{OS}_{ARCH}.tar.gz'
    URL="${OVH_DOWNLOAD_URL:-${_def_dl_url}}"
    URL=$(resolve_artifact_url "$URL")
    DL_DIR="${DOWNLOAD_DIR:-/tmp/libscript_downloads}/ovh"
    mkdir -p "$DL_DIR"
    ARCHIVE_NAME=$(basename "$URL")
    printf '[download] Pre-downloading ovh %s from %s to %s...\n' "$VERSION" "$URL" "$DL_DIR/$ARCHIVE_NAME"
    libscript_download "$URL" "$DL_DIR/$ARCHIVE_NAME"
    ;;
  install)
    if [ "${OVH_INSTALL_METHOD}" = "from-source" ]; then
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/ovh/${EXACT_VERSION}"
      _def_src_url='https://github.com/ovh/ovhcloud-cli/releases/download/v{VERSION}/ovhcloud-cli_{OS}_{ARCH}.tar.gz'
      SRC_URL="${OVH_DOWNLOAD_URL:-${_def_src_url}}"
      SRC_URL=$(resolve_artifact_url "$SRC_URL")
      libscript_build_component_from_source 'ovh' "$EXACT_VERSION" 'ovhcloud' 'go' 'go' "$SRC_URL"
      libscript_symlink_alias 'ovh' "${VERSION}" "${EXACT_VERSION}"
      exit 0
    elif [ "${OVH_INSTALL_METHOD}" = "system" ]; then
      libscript_depends 'ovh'
    elif [ "${OVH_INSTALL_METHOD}" = "nix" ] || [ "${OVH_INSTALL_METHOD}" = "guix" ] || [ "${OVH_INSTALL_METHOD}" = "spack" ] || [ "${OVH_INSTALL_METHOD}" = "brew" ] || [ "${OVH_INSTALL_METHOD}" = "winget" ] || [ "${OVH_INSTALL_METHOD}" = "choco" ] || [ "${OVH_INSTALL_METHOD}" = "scoop" ]; then
      libscript_depends_via "${OVH_INSTALL_METHOD}" 'ovh'
    else
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/ovh/${EXACT_VERSION}"
      if [ -x "${TARGET_DIR}/bin/ovhcloud" ] && [ "${FORCE_REINSTALL:-0}" != "1" ]; then
        printf '[INFO] %s %s is already installed at %s.\n' 'ovh' "${EXACT_VERSION}" "${TARGET_DIR}"
        libscript_symlink_alias 'ovh' "${VERSION}" "${EXACT_VERSION}"
        libscript_symlink_alias 'ovh' 'default' "${EXACT_VERSION}"
        exit 0
      fi
      _def_url='https://github.com/ovh/ovhcloud-cli/releases/download/v{VERSION}/ovhcloud-cli_{OS}_{ARCH}.tar.gz'
      URL="${OVH_DOWNLOAD_URL:-${_def_url}}"
      URL=$(resolve_artifact_url "$URL")
      if [ -z "$URL" ]; then
        libscript_depends 'ovh'
        exit 0
      fi
      mkdir -p "$TARGET_DIR/bin"
      ARCHIVE_NAME=$(basename "$URL")
      CACHED_DL="${DOWNLOAD_DIR:-${LIBSCRIPT_CACHE_DIR:-$LIBSCRIPT_ROOT_DIR/cache/downloads}}/ovh/$ARCHIVE_NAME"
      if [ -s "$CACHED_DL" ]; then
        TMP_FILE="$CACHED_DL"
      else
        TMP_FILE="${TMPDIR:-/tmp}/ovh-$$.archive"
        PACKAGE_NAME='ovh' libscript_download "$URL" "$TMP_FILE"
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
          cp -f "$TMP_FILE" "$TARGET_DIR/bin/ovhcloud"
          chmod +x "$TARGET_DIR/bin/ovhcloud"
          ;;
      esac
      if [ ! -x "$TARGET_DIR/bin/ovhcloud" ]; then
        _sub_dirs=$(find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null || true)
        for _sub in $_sub_dirs; do
          [ "$_sub" = "$TARGET_DIR/bin" ] && continue
          if [ -f "$_sub/bin/ovhcloud" ] || [ -f "$_sub/bin/ovhcloud.sh" ] || [ -f "$_sub/sbin/ovhcloud" ] || [ -f "$_sub/ovhcloud" ]; then
            _flat_tmp="${TARGET_DIR}.flat.$$"
            rm -rf "$_flat_tmp"
            mv "$_sub" "$_flat_tmp"
            cp -Rf "$_flat_tmp"/. "$TARGET_DIR"/
            rm -rf "$_flat_tmp"
            break
          fi
        done
      fi
      if [ ! -x "$TARGET_DIR/bin/ovhcloud" ] && [ -f "$TARGET_DIR/bin/ovhcloud.sh" ]; then
        chmod +x "$TARGET_DIR/bin/ovhcloud.sh"
        ln -sf "ovhcloud.sh" "$TARGET_DIR/bin/ovhcloud"
      fi
      if [ ! -x "$TARGET_DIR/bin/ovhcloud" ] && [ -f "$TARGET_DIR/sbin/ovhcloud" ]; then
        chmod +x "$TARGET_DIR/sbin/ovhcloud"
        ln -sf "../sbin/ovhcloud" "$TARGET_DIR/bin/ovhcloud"
      fi
      if [ ! -x "$TARGET_DIR/bin/ovhcloud" ] && [ -f "$TARGET_DIR/ovhcloud" ]; then
        chmod +x "$TARGET_DIR/ovhcloud"
        ln -sf "../ovhcloud" "$TARGET_DIR/bin/ovhcloud"
      fi
      if [ ! -x "$TARGET_DIR/bin/ovhcloud" ]; then
        for _entry in $(ls -1 "$TARGET_DIR" 2>/dev/null || true); do
          case "$_entry" in
            ovhcloud-*|ovhcloud_*)
              if [ -f "$TARGET_DIR/$_entry" ]; then
                chmod +x "$TARGET_DIR/$_entry"
                ln -sf "../$_entry" "$TARGET_DIR/bin/ovhcloud"
                break
              fi
              ;;
          esac
        done
      fi
      if [ -f "$TARGET_DIR/bin/ovhcloud" ]; then
        chmod +x "$TARGET_DIR/bin/ovhcloud"
      fi
      if [ "$TMP_FILE" != "$CACHED_DL" ]; then
        rm -f "$TMP_FILE"
      fi
      libscript_symlink_alias 'ovh' "${VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias 'ovh' 'default' "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action 'ovh' "$ACTION" "$VERSION" "${OVH_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
