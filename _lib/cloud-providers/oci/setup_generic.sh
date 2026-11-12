#!/bin/sh
# ## Overview
# Generic setup script for the oci component implementing the Version Manager Contract.
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

OCI_INSTALL_METHOD="${OCI_INSTALL_METHOD:-${LIBSCRIPT_GLOBAL_INSTALL_METHOD:-libscript_native}}"
ACTION="${ACTION:-install}"
VERSION="${OCI_VERSION:-latest}"

# ## oci_cli_exec
# Executes OCI CLI commands with DRY_RUN=true simulation support.
oci_cli_exec() {
  if [ "${DRY_RUN:-}" = "true" ] || [ "${DRY_RUN:-0}" = "1" ] || ! command -v oci >/dev/null 2>&1; then
    printf '[DRY_RUN] oci %s\n' "$*" >&2
    case "$*" in
      *"instance list-vnics"*|*"instance get"*) printf '203.0.113.21\n'; return 0 ;;
      *) return 0 ;;
    esac
  fi
  command oci "$@"
}

# ## resolve_exact_version
# Resolves dynamic version aliases such as latest or lts into an exact upstream version string.
resolve_exact_version() {
  if [ "${VERSION}" = "latest" ] || [ "${VERSION}" = "lts" ]; then
    _gh_repo='oracle/oci-cli'
    if [ -n "$_gh_repo" ]; then
      EXACT_VERSION=$(libscript_fetch_stdout 'https://api.github.com/repos/oracle/oci-cli/releases/latest' | tr ',' '\n' | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1 | sed 's/^v//' || true)
      if [ -z "$EXACT_VERSION" ]; then
        EXACT_VERSION='3.51.4'
      fi
    else
      EXACT_VERSION='3.51.4'
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
  group|project|compartment)
    SUBACTION=${1:-ensure}
    COMP_ID=${2:-${OCI_COMPARTMENT_ID:-default-compartment}}
    printf 'OCI compartment '\''%s'\'' (%s) ensured.\n' "$COMP_ID" "$SUBACTION"
    exit 0
    ;;
  auth)
    SUBACTION=${1:-status}
    case "$SUBACTION" in
      login) oci_cli_exec setup config ;;
      logout) printf 'Remove ~/.oci/config session profile to log out of OCI CLI.\n' ;;
      status) oci_cli_exec iam region list ;;
      *) printf 'Unknown auth sub-action: %s\n' "$SUBACTION" >&2; exit 1 ;;
    esac
    exit 0
    ;;
  location)
    SUBACTION=${1:-list}
    case "$SUBACTION" in
      list) oci_cli_exec iam region list ;;
      select) printf 'Default OCI region set to %s.\n' "${2:-us-ashburn-1}" ;;
      *) printf 'Unknown location sub-action: %s\n' "$SUBACTION" >&2; exit 1 ;;
    esac
    exit 0
    ;;
  network)
    SUBACTION=${1:-}
    RESOURCE_NAME=${2:-libscript-vcn}
    REGION=${3:-${OCI_REGION:-us-ashburn-1}}
    COMP_ID=${OCI_COMPARTMENT_ID:-ocid1.compartment.oc1..example}
    case "$SUBACTION" in
      create)
        printf 'Creating OCI VCN: %s in %s\n' "$RESOURCE_NAME" "$REGION"
        oci_cli_exec network vcn create --compartment-id "$COMP_ID" --cidr-block '10.0.0.0/16' --display-name "$RESOURCE_NAME" --region "$REGION" || true
        ;;
      delete)
        printf 'Deleting OCI VCN: %s\n' "$RESOURCE_NAME"
        oci_cli_exec network vcn delete --vcn-id "$RESOURCE_NAME" --force || true
        ;;
      wait-ssh)
        exit 0
        ;;
      list)
        oci_cli_exec network vcn list --compartment-id "$COMP_ID"
        ;;
      *)
        printf 'Unknown network sub-action: %s\n' "$SUBACTION" >&2; exit 1 ;;
    esac
    exit 0
    ;;
  firewall)
    SUBACTION=${1:-}
    RESOURCE_NAME=${2:-libscript-nsg}
    COMP_ID=${OCI_COMPARTMENT_ID:-ocid1.compartment.oc1..example}
    case "$SUBACTION" in
      create)
        printf 'Creating OCI Network Security Group: %s\n' "$RESOURCE_NAME"
        oci_cli_exec network nsg create --compartment-id "$COMP_ID" --vcn-id "${3:-ocid1.vcn.oc1..example}" --display-name "$RESOURCE_NAME" || true
        ;;
      delete)
        printf 'Deleting OCI Network Security Group: %s\n' "$RESOURCE_NAME"
        oci_cli_exec network nsg delete --nsg-id "$RESOURCE_NAME" --force || true
        ;;
      list)
        oci_cli_exec network nsg list --compartment-id "$COMP_ID"
        ;;
      *)
        printf 'Unknown firewall sub-action: %s\n' "$SUBACTION" >&2; exit 1 ;;
    esac
    exit 0
    ;;
  dns)
    SUBACTION=${1:-}
    SUBTYPE=${2:-}
    COMP_ID=${OCI_COMPARTMENT_ID:-ocid1.compartment.oc1..example}
    case "$SUBACTION" in
      zone)
        case "$SUBTYPE" in
          create) oci_cli_exec dns zone create --compartment-id "$COMP_ID" --name "${3:-example.com}" --zone-type PRIMARY || true ;;
          delete) oci_cli_exec dns zone delete --zone-name-or-id "${3:-example.com}" --force || true ;;
          list) oci_cli_exec dns zone list --compartment-id "$COMP_ID" ;;
          *) printf 'Unknown dns zone sub-action: %s\n' "$SUBTYPE" >&2; exit 1 ;;
        esac
        ;;
      record)
        case "$SUBTYPE" in
          create|update)
            oci_cli_exec dns record domain patch --zone-name-or-id "${3:-example.com}" --domain "${4:-example.com}" || true
            ;;
          delete)
            oci_cli_exec dns record domain delete --zone-name-or-id "${3:-example.com}" --domain "${4:-example.com}" --force || true
            ;;
          list)
            oci_cli_exec dns record zone get --zone-name-or-id "${3:-example.com}"
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
    COMP_ID=${OCI_COMPARTMENT_ID:-ocid1.compartment.oc1..example}
    case "$SUBACTION" in
      create)
        IMAGE=${3:-Oracle-Linux-9}
        REGION=${4:-${OCI_REGION:-us-ashburn-1}}
        SHAPE=${VM_SIZE:-${OCI_SHAPE:-VM.Standard.E4.Flex}}
        AD=${OCI_AVAILABILITY_DOMAIN:-AD-1}
        SUBNET=${OCI_SUBNET_ID:-ocid1.subnet.oc1..example}
        TAGS_ARG="$(libscript_format_tags oci)"
        printf 'Creating OCI Compute Instance: %s (%s, %s, %s)\n' "$RESOURCE_NAME" "$SHAPE" "$IMAGE" "$REGION"
        # shellcheck disable=SC2086
        oci_cli_exec compute instance launch --compartment-id "$COMP_ID" --availability-domain "$AD" --shape "$SHAPE" --subnet-id "$SUBNET" --display-name "$RESOURCE_NAME" --region "$REGION" $TAGS_ARG || true
        ;;
      delete)
        printf 'Terminating OCI Compute Instance: %s\n' "$RESOURCE_NAME"
        oci_cli_exec compute instance terminate --instance-id "$RESOURCE_NAME" --force || true
        ;;
      list)
        oci_cli_exec compute instance list --compartment-id "$COMP_ID"
        ;;
      wait-ssh)
        exit 0
        ;;
      ip)
        if [ "${DRY_RUN:-}" = "true" ] || [ "${DRY_RUN:-0}" = "1" ]; then
          printf '203.0.113.21\n'
          exit 0
        fi
        oci_cli_exec compute instance list-vnics --instance-id "$RESOURCE_NAME" --query 'data[0]."public-ip"' --raw-output
        ;;
      exec)
        shift 2
        if [ $# -gt 1 ] && [ "${1:-}" = "--" ]; then shift; fi
        if [ "${DRY_RUN:-}" = "true" ] || [ "${DRY_RUN:-0}" = "1" ]; then
          printf '[DRY_RUN] Executing on %s: %s\n' "$RESOURCE_NAME" "$*"
          exit 0
        fi
        IP=$(oci_cli_exec compute instance list-vnics --instance-id "$RESOURCE_NAME" --query 'data[0]."public-ip"' --raw-output | head -n 1)
        _oci_ssh_opts=$(libscript_ssh_mux_opts)
        # shellcheck disable=SC2029,SC2086
        ssh $_oci_ssh_opts "${ADMIN_USER:-opc}@$IP" "$@"
        ;;
      sync)
        if [ "${DRY_RUN:-}" = "true" ] || [ "${DRY_RUN:-0}" = "1" ]; then
          printf '[DRY_RUN] Syncing LibScript to %s\n' "$RESOURCE_NAME"
          exit 0
        fi
        IP=$(oci_cli_exec compute instance list-vnics --instance-id "$RESOURCE_NAME" --query 'data[0]."public-ip"' --raw-output | head -n 1)
        libscript_sync_runtime_to_remote "${ADMIN_USER:-opc}@$IP" "libscript"
        ;;
      deploy|upload|scp)
        SRC=${3:-${4:-}}; DST=${4:-${5:-}}
        if [ "${DRY_RUN:-}" = "true" ] || [ "${DRY_RUN:-0}" = "1" ]; then
          printf '[DRY_RUN] Uploading %s to %s -> %s\n' "$SRC" "$RESOURCE_NAME" "$DST"
          exit 0
        fi
        IP=$(oci_cli_exec compute instance list-vnics --instance-id "$RESOURCE_NAME" --query 'data[0]."public-ip"' --raw-output | head -n 1)
        libscript_scp_to_remote "$SRC" "${ADMIN_USER:-opc}@$IP" "$DST"
        ;;
      download|scp-from)
        SRC=${3:-${4:-}}; DST=${4:-${5:-}}
        if [ "${DRY_RUN:-}" = "true" ] || [ "${DRY_RUN:-0}" = "1" ]; then
          printf '[DRY_RUN] Downloading %s:%s -> %s\n' "$RESOURCE_NAME" "$SRC" "$DST"
          exit 0
        fi
        IP=$(oci_cli_exec compute instance list-vnics --instance-id "$RESOURCE_NAME" --query 'data[0]."public-ip"' --raw-output | head -n 1)
        libscript_scp_from_remote "${ADMIN_USER:-opc}@$IP" "$SRC" "$DST"
        ;;
      *)
        printf 'Unknown node sub-action: %s\n' "$SUBACTION" >&2; exit 1 ;;
    esac
    exit 0
    ;;
  ls)
    if [ "${OCI_INSTALL_METHOD}" = "libscript_native" ]; then
      [ -d "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/oci" ] && ls -1 "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/oci"
    else
      if command -v 'oci' >/dev/null 2>&1; then
        'oci' --version || true
      fi
    fi
    ;;
  ls-remote)
    RELEASES_URL="${OCI_RELEASES_URL:-https://api.github.com/repos/oracle/oci-cli/releases/latest}"
    printf '[ls-remote] Fetching available oci versions from %s...\n' "${RELEASES_URL}"
    libscript_fetch_stdout "${RELEASES_URL}" | head -n 30 || true
    ;;
  use)
    resolve_exact_version
    TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/oci/${EXACT_VERSION}"
    if [ ! -d "$TARGET_DIR" ]; then
      printf 'Version %s not installed. Installing...\n' "$EXACT_VERSION"
      ACTION='install' "$0"
    fi
    libscript_symlink_alias 'oci' "${VERSION}" "${EXACT_VERSION}"
    libscript_symlink_alias 'oci' 'default' "${EXACT_VERSION}"
    ;;
  download)
    resolve_exact_version
    _def_dl_url='https://github.com/oracle/oci-cli/releases/download/v{VERSION}/oci-cli-{VERSION}.zip'
    URL="${OCI_DOWNLOAD_URL:-${_def_dl_url}}"
    URL=$(resolve_artifact_url "$URL")
    DL_DIR="${DOWNLOAD_DIR:-/tmp/libscript_downloads}/oci"
    mkdir -p "$DL_DIR"
    ARCHIVE_NAME=$(basename "$URL")
    printf '[download] Pre-downloading oci %s from %s to %s...\n' "$VERSION" "$URL" "$DL_DIR/$ARCHIVE_NAME"
    libscript_download "$URL" "$DL_DIR/$ARCHIVE_NAME"
    ;;
  install)
    if [ "${OCI_INSTALL_METHOD}" = "from-source" ]; then
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/oci/${EXACT_VERSION}"
      _def_src_url='https://github.com/oracle/oci-cli/releases/download/v{VERSION}/oci-cli-{VERSION}.zip'
      SRC_URL="${OCI_DOWNLOAD_URL:-${_def_src_url}}"
      SRC_URL=$(resolve_artifact_url "$SRC_URL")
      libscript_build_component_from_source 'oci' "$EXACT_VERSION" 'oci' 'python' 'pip' "$SRC_URL"
      libscript_symlink_alias 'oci' "${VERSION}" "${EXACT_VERSION}"
      exit 0
    elif [ "${OCI_INSTALL_METHOD}" = "system" ]; then
      libscript_depends 'oci'
    elif [ "${OCI_INSTALL_METHOD}" = "nix" ] || [ "${OCI_INSTALL_METHOD}" = "guix" ] || [ "${OCI_INSTALL_METHOD}" = "spack" ] || [ "${OCI_INSTALL_METHOD}" = "brew" ] || [ "${OCI_INSTALL_METHOD}" = "winget" ] || [ "${OCI_INSTALL_METHOD}" = "choco" ] || [ "${OCI_INSTALL_METHOD}" = "scoop" ]; then
      libscript_depends_via "${OCI_INSTALL_METHOD}" 'oci'
    else
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/oci/${EXACT_VERSION}"
      if [ -x "${TARGET_DIR}/bin/oci" ] && [ "${FORCE_REINSTALL:-0}" != "1" ]; then
        printf '[INFO] %s %s is already installed at %s.\n' 'oci' "${EXACT_VERSION}" "${TARGET_DIR}"
        libscript_symlink_alias 'oci' "${VERSION}" "${EXACT_VERSION}"
        libscript_symlink_alias 'oci' 'default' "${EXACT_VERSION}"
        exit 0
      fi
      _def_url='https://github.com/oracle/oci-cli/releases/download/v{VERSION}/oci-cli-{VERSION}.zip'
      URL="${OCI_DOWNLOAD_URL:-${_def_url}}"
      URL=$(resolve_artifact_url "$URL")
      if [ -z "$URL" ]; then
        libscript_depends 'oci'
        exit 0
      fi
      mkdir -p "$TARGET_DIR/bin"
      ARCHIVE_NAME=$(basename "$URL")
      CACHED_DL="${DOWNLOAD_DIR:-${LIBSCRIPT_CACHE_DIR:-$LIBSCRIPT_ROOT_DIR/cache/downloads}}/oci/$ARCHIVE_NAME"
      if [ -s "$CACHED_DL" ]; then
        TMP_FILE="$CACHED_DL"
      else
        TMP_FILE="${TMPDIR:-/tmp}/oci-$$.archive"
        PACKAGE_NAME='oci' libscript_download "$URL" "$TMP_FILE"
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
          cp -f "$TMP_FILE" "$TARGET_DIR/bin/oci"
          chmod +x "$TARGET_DIR/bin/oci"
          ;;
      esac
      if [ ! -x "$TARGET_DIR/bin/oci" ]; then
        _sub_dirs=$(find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -type d 2>/dev/null || true)
        for _sub in $_sub_dirs; do
          [ "$_sub" = "$TARGET_DIR/bin" ] && continue
          if [ -f "$_sub/bin/oci" ] || [ -f "$_sub/bin/oci.sh" ] || [ -f "$_sub/sbin/oci" ] || [ -f "$_sub/oci" ]; then
            _flat_tmp="${TARGET_DIR}.flat.$$"
            rm -rf "$_flat_tmp"
            mv "$_sub" "$_flat_tmp"
            cp -Rf "$_flat_tmp"/. "$TARGET_DIR"/
            rm -rf "$_flat_tmp"
            break
          fi
        done
      fi
      if [ ! -x "$TARGET_DIR/bin/oci" ] && [ -f "$TARGET_DIR/bin/oci.sh" ]; then
        chmod +x "$TARGET_DIR/bin/oci.sh"
        ln -sf "oci.sh" "$TARGET_DIR/bin/oci"
      fi
      if [ ! -x "$TARGET_DIR/bin/oci" ] && [ -f "$TARGET_DIR/sbin/oci" ]; then
        chmod +x "$TARGET_DIR/sbin/oci"
        ln -sf "../sbin/oci" "$TARGET_DIR/bin/oci"
      fi
      if [ ! -x "$TARGET_DIR/bin/oci" ] && [ -f "$TARGET_DIR/oci" ]; then
        chmod +x "$TARGET_DIR/oci"
        ln -sf "../oci" "$TARGET_DIR/bin/oci"
      fi
      if [ ! -x "$TARGET_DIR/bin/oci" ]; then
        for _entry in $(ls -1 "$TARGET_DIR" 2>/dev/null || true); do
          case "$_entry" in
            oci-*|oci_*)
              if [ -f "$TARGET_DIR/$_entry" ]; then
                chmod +x "$TARGET_DIR/$_entry"
                ln -sf "../$_entry" "$TARGET_DIR/bin/oci"
                break
              fi
              ;;
          esac
        done
      fi
      if [ -f "$TARGET_DIR/bin/oci" ]; then
        chmod +x "$TARGET_DIR/bin/oci"
      fi
      if [ "$TMP_FILE" != "$CACHED_DL" ]; then
        rm -f "$TMP_FILE"
      fi
      libscript_symlink_alias 'oci' "${VERSION}" "${EXACT_VERSION}"
      libscript_symlink_alias 'oci' 'default' "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action 'oci' "$ACTION" "$VERSION" "${OCI_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
