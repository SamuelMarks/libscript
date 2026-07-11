#!/bin/sh
# ## Overview
# Generic setup module for gcp.
# 
# ## Usage
# Execute this script to perform generic initialization steps for gcp.

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
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
DIR="${SCRIPT_DIR}"

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

GCP_INSTALL_METHOD="$(libscript_resolve_install_method "GCP")"
ACTION="${ACTION:-install}"
VERSION="${GCP_VERSION:-latest}"

resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote gcp 2>/dev/null | tail -n 1)
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
  node)
    SUBACTION=${1:-}
    RESOURCE_NAME=${2:-}
    case "$SUBACTION" in
      create)
        if [ -z "$RESOURCE_NAME" ]; then
          printf '%s\n' "Usage: node create <name> [--machine-type TYPE] [--image IMAGE]"
          exit 1
        fi
        TYPE="n1-standard-1"
        IMAGE="debian-11"
        shift 2
        while [ $# -gt 0 ]; do
          case "$1" in
            --machine-type)
              TYPE="$2"; shift 2 ;;
            --image)
              IMAGE="$2"; shift 2 ;;
            *)
              printf '%s\n' "Unknown option: $1"; exit 1 ;;
          esac
        done
        printf '%s\n' "Creating GCP VM: $RESOURCE_NAME ($TYPE, $IMAGE)"
        TAGS_ARG="$(libscript_format_tags gcp)"
        if gcloud compute instances describe "$RESOURCE_NAME" >/dev/null 2>&1; then
          printf '%s\n' "Instance '$RESOURCE_NAME' already exists."
        else
          # shellcheck disable=SC2086
          gcloud compute instances create "$RESOURCE_NAME" --machine-type="$TYPE" --image-family="$IMAGE" --image-project="debian-cloud" $TAGS_ARG
        fi
        ;;
      delete)
        if [ -z "$RESOURCE_NAME" ]; then
          printf '%s\n' "Usage: node delete <name>"
          exit 1
        fi
        libscript_verify_managed gcp node "$RESOURCE_NAME" || exit 1
        printf '%s\n' "Deleting GCP VM: $RESOURCE_NAME"
        if gcloud compute instances describe "$RESOURCE_NAME" >/dev/null 2>&1; then
          gcloud compute instances delete "$RESOURCE_NAME" --quiet
        else
          printf '%s\n' "Instance '$RESOURCE_NAME' already deleted or not found."
        fi
        ;;
      list)
        gcloud compute instances list
        ;;
      update)
        if [ -z "$RESOURCE_NAME" ]; then
          printf '%s\n' "Usage: node update <name> [--machine-type TYPE]"
          exit 1
        fi
        libscript_verify_managed gcp node "$RESOURCE_NAME" || exit 1
        shift 2
        while [ $# -gt 0 ]; do
          case "$1" in
            --machine-type)
              gcloud compute instances set-machine-type "$RESOURCE_NAME" --machine-type="$2"
              shift 2 ;;
            *)
              printf '%s\n' "Unknown option: $1"; exit 1 ;;
          esac
        done
        ;;
      exec)
        shift 2
        if [ -z "$RESOURCE_NAME" ]; then printf '%s\n' "Usage: node exec <name> <cmd...>"; exit 1; fi
        gcloud compute ssh "$RESOURCE_NAME" --command="$*"
        ;;
      *)
        printf '%s\n' "Unknown node sub-action: $SUBACTION"; exit 1
        ;;
    esac
    exit 0
    ;;
  dns)
    SUBACTION=${1:-}
    SUBTYPE=${2:-}
    case "$SUBACTION" in
      zone)
        case "$SUBTYPE" in
          create)
            ZONE=${3:-}; DNS_NAME=${4:-}
            if [ -z "$ZONE" ] || [ -z "$DNS_NAME" ]; then printf '%s\n' "Usage: dns zone create <zone> <dns-name>"; exit 1; fi
            TAGS_ARG="$(libscript_format_tags gcp)"
            if gcloud dns managed-zones describe "$ZONE" >/dev/null 2>&1; then
              printf '%s\n' "DNS zone '$ZONE' already exists."
            else
              # shellcheck disable=SC2086
              gcloud dns managed-zones create "$ZONE" --dns-name="$DNS_NAME" --description="Libscript managed" $TAGS_ARG
            fi
            ;;
          delete)
            ZONE=${3:-}
            if [ -z "$ZONE" ]; then printf '%s\n' "Usage: dns zone delete <zone>"; exit 1; fi
            libscript_verify_managed gcp dns "$ZONE" || exit 1
            if gcloud dns managed-zones describe "$ZONE" >/dev/null 2>&1; then
              gcloud dns managed-zones delete "$ZONE" --quiet
            else
              printf '%s\n' "DNS zone '$ZONE' already deleted or not found."
            fi
            ;;
          list)
            gcloud dns managed-zones list
            ;;
          *)
            printf '%s\n' "Unknown dns zone action: $SUBTYPE"; exit 1 ;;
        esac
        ;;
      record)
        case "$SUBTYPE" in
          create|update)
            ZONE=${3:-}; NAME=${4:-}; TYPE=${5:-}; DATA=${6:-}; TTL=${7:-300}
            if [ -z "$DATA" ]; then printf '%s\n' "Usage: dns record $SUBTYPE <zone> <name> <type> <data> [ttl]"; exit 1; fi
            if [ "$SUBTYPE" = "update" ]; then
              libscript_verify_managed gcp dns "$ZONE" || exit 1
            fi
            if [ "$SUBTYPE" = "create" ]; then
              gcloud dns record-sets create "$NAME" --zone="$ZONE" --type="$TYPE" --rrdatas="$DATA" --ttl="$TTL"
            else
              gcloud dns record-sets update "$NAME" --zone="$ZONE" --type="$TYPE" --rrdatas="$DATA" --ttl="$TTL"
            fi
            ;;
          delete)
            ZONE=${3:-}; NAME=${4:-}; TYPE=${5:-}
            if [ -z "$TYPE" ]; then printf '%s\n' "Usage: dns record delete <zone> <name> <type>"; exit 1; fi
            libscript_verify_managed gcp dns "$ZONE" || exit 1
            gcloud dns record-sets delete "$NAME" --zone="$ZONE" --type="$TYPE" --quiet
            ;;
          list)
            ZONE=${3:-}
            if [ -z "$ZONE" ]; then printf '%s\n' "Usage: dns record list <zone>"; exit 1; fi
            gcloud dns record-sets list --zone="$ZONE"
            ;;
          *)
            printf '%s\n' "Unknown dns record action: $SUBTYPE"; exit 1 ;;
        esac
        ;;
      *)
        printf '%s\n' "Unknown dns action: $SUBACTION"; exit 1
        ;;
    esac
    exit 0
    ;;
  firewall)
    SUBACTION=${1:-}
    RESOURCE_NAME=${2:-}
    case "$SUBACTION" in
      create)
        if [ -z "$RESOURCE_NAME" ]; then
          printf '%s\n' "Usage: firewall create <name> [--network NETWORK] [--allow PORTS]"
          exit 1
        fi
        NETWORK="default"
        ALLOW=""
        shift 2
        while [ $# -gt 0 ]; do
          case "$1" in
            --network)
              NETWORK="$2"; shift 2 ;;
            --allow)
              ALLOW="--allow=$2"; shift 2 ;;
            *)
              printf '%s\n' "Unknown option: $1"; exit 1 ;;
          esac
        done
        printf '%s\n' "Creating GCP Firewall Rule: $RESOURCE_NAME"
        if gcloud compute firewall-rules describe "$RESOURCE_NAME" >/dev/null 2>&1; then
          printf '%s\n' "Firewall rule '$RESOURCE_NAME' already exists."
        else
          gcloud compute firewall-rules create "$RESOURCE_NAME" --network="$NETWORK" $ALLOW
        fi
        ;;
      delete)
        if [ -z "$RESOURCE_NAME" ]; then
          printf '%s\n' "Usage: firewall delete <name>"
          exit 1
        fi
        libscript_verify_managed gcp firewall "$RESOURCE_NAME" || exit 1
        printf '%s\n' "Deleting GCP Firewall Rule: $RESOURCE_NAME"
        if gcloud compute firewall-rules describe "$RESOURCE_NAME" >/dev/null 2>&1; then
          gcloud compute firewall-rules delete "$RESOURCE_NAME" --quiet
        else
          printf '%s\n' "Firewall rule '$RESOURCE_NAME' already deleted or not found."
        fi
        ;;
      list)
        gcloud compute firewall-rules list
        ;;
      update)
        if [ -z "$RESOURCE_NAME" ]; then
          printf '%s\n' "Usage: firewall update <name> [--allow PORTS]"
          exit 1
        fi
        libscript_verify_managed gcp firewall "$RESOURCE_NAME" || exit 1
        shift 2
        while [ $# -gt 0 ]; do
          case "$1" in
            --allow)
              gcloud compute firewall-rules update "$RESOURCE_NAME" --allow="$2"
              shift 2 ;;
            *)
              printf '%s\n' "Unknown option: $1"; exit 1 ;;
          esac
        done
        ;;
      *)
        printf '%s\n' "Unknown firewall sub-action: $SUBACTION"; exit 1
        ;;
    esac
    exit 0
    ;;
  network)
    SUBACTION=${1:-}
    RESOURCE_NAME=${2:-}
    case "$SUBACTION" in
      create)
        if [ -z "$RESOURCE_NAME" ]; then
          printf '%s\n' "Usage: network create <name>"
          exit 1
        fi
        printf '%s\n' "Creating GCP Network: $RESOURCE_NAME"
        TAGS_ARG="$(libscript_format_tags gcp)"
        if gcloud compute networks describe "$RESOURCE_NAME" >/dev/null 2>&1; then
          printf '%s\n' "Network '$RESOURCE_NAME' already exists."
        else
          # shellcheck disable=SC2086
          gcloud compute networks create "$RESOURCE_NAME" $TAGS_ARG
        fi
        ;;
      delete)
        if [ -z "$RESOURCE_NAME" ]; then
          printf '%s\n' "Usage: network delete <name>"
          exit 1
        fi
        libscript_verify_managed gcp network "$RESOURCE_NAME" || exit 1
        printf '%s\n' "Deleting GCP Network: $RESOURCE_NAME"
        if gcloud compute networks describe "$RESOURCE_NAME" >/dev/null 2>&1; then
          gcloud compute networks delete "$RESOURCE_NAME" --quiet
        else
          printf '%s\n' "Network '$RESOURCE_NAME' already deleted or not found."
        fi
        ;;
      list)
        gcloud compute networks list
        ;;
      update)
        if [ -z "$RESOURCE_NAME" ]; then
          printf '%s\n' "Usage: network update <name> [--bgp-routing-mode MODE]"
          exit 1
        fi
        libscript_verify_managed gcp network "$RESOURCE_NAME" || exit 1
        shift 2
        while [ $# -gt 0 ]; do
          case "$1" in
            --bgp-routing-mode)
              gcloud compute networks update "$RESOURCE_NAME" --bgp-routing-mode="$2"
              shift 2 ;;
            *)
              printf '%s\n' "Unknown option: $1"; exit 1 ;;
          esac
        done
        ;;
      *)
        printf '%s\n' "Unknown network sub-action: $SUBACTION"; exit 1
        ;;
    esac
    exit 0
    ;;
  auth)
    SUBACTION=${1:-}
    case "$SUBACTION" in
      login)
        gcloud auth login
        gcloud auth application-default login
        ;;
      logout)
        gcloud auth revoke
        ;;
      status)
        gcloud auth list
        ;;
      *)
        printf '%s\n' "Unknown auth sub-action: $SUBACTION"; exit 1
        ;;
    esac
    exit 0
    ;;
  location)
    SUBACTION=${1:-}
    case "$SUBACTION" in
      list)
        gcloud compute regions list
        ;;
      select)
        if [ -n "${2:-}" ]; then
          gcloud config set compute/region "$2"
          printf '%s\n' "Default region set to $2."
        else
          printf '%s\n' "Usage: location select <region>"
          exit 1
        fi
        ;;
      *)
        printf '%s\n' "Unknown location sub-action: $SUBACTION"; exit 1
        ;;
    esac
    exit 0
    ;;
  ls)
    if [ "$GCP_INSTALL_METHOD" = "mise" ]; then
      mise ls gcp || true
    elif [ "$GCP_INSTALL_METHOD" = "asdf" ]; then
      asdf list gcp || true
    elif [ "$GCP_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "$GCP_INSTALL_METHOD" = "vfox" ]; then
      vfox ls gcp || true
    elif [ "$GCP_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System packages do not support ls here."
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/gcp/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$GCP_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote gcp || true
    elif [ "$GCP_INSTALL_METHOD" = "asdf" ]; then
      asdf list all gcp || true
    elif [ "$GCP_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "$GCP_INSTALL_METHOD" = "vfox" ]; then
      vfox ls all gcp || true
    else
      if [ -n "${GCP_RELEASES_URL:-}" ]; then
        curl -sSL "${GCP_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s\n' "No versions found"
      else
      git ls-remote --tags "https://github.com/priyankavergadia/GCPSketchnote" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s\n' "No versions found"
    fi
    fi
    exit 0
    ;;
  use)
    if [ "$GCP_INSTALL_METHOD" = "mise" ]; then
      mise use "gcp@${VERSION}"
    elif [ "$GCP_INSTALL_METHOD" = "asdf" ]; then
      asdf global gcp "${VERSION}"
    elif [ "$GCP_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not use explicit versions this way"
    elif [ "$GCP_INSTALL_METHOD" = "vfox" ]; then
      vfox use "gcp@${VERSION}"
    elif [ "$GCP_INSTALL_METHOD" = "vfox" ]; then
      vfox use "gcp@${VERSION}"
    elif [ "$GCP_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System packages do not support use here."
    else
      resolve_exact_version
      libscript_symlink_alias "gcp" "$VERSION" "${EXACT_VERSION}"
      libscript_symlink_alias "gcp" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/gcp/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "gcp ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "gcp" "default" "${EXACT_VERSION}"
      log_info "Set default gcp version to ${EXACT_VERSION}."
      log_info "To apply to the current shell, run:"
      log_info "  eval \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env gcp \"$VERSION\")"
    fi
    exit 0
    ;;
  download)
    if [ "$GCP_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading gcp ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/gcp..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/gcp"
      if [ -n "${GCP_DOWNLOAD_URL:-}" ]; then
        libscript_download "${GCP_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/gcp/gcp-${VERSION}.tar.gz"
      else
        log_warn "GCP_DOWNLOAD_URL is not defined for gcp ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install|*)
    if [ "$GCP_INSTALL_METHOD" = "system" ]; then
      libscript_depends "gcp"
    elif [ "$GCP_INSTALL_METHOD" = "mise" ]; then
      mise install "gcp@${VERSION}"
    elif [ "$GCP_INSTALL_METHOD" = "asdf" ]; then
      asdf install gcp "${VERSION}"
    elif [ "$GCP_INSTALL_METHOD" = "pkgx" ]; then
      pkgx install "gcp@${VERSION}"
    elif [ "$GCP_INSTALL_METHOD" = "vfox" ]; then
      vfox add gcp || true
      vfox install "gcp@${VERSION}"
    else
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/gcp/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing gcp ${VERSION} natively to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}/bin"
        if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/gcp/"*"${VERSION}"* >/dev/null 2>&1; then
          log_info "Extracting from cache..."
          cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/gcp/" -maxdepth 1 -type f -name "*${VERSION}*" 2>/dev/null | head -n 1 || true)
          if [ -n "$cache_file" ]; then
            if case "$cache_file" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "$cache_file" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "$cache_file" in *.zip) true;; *) false;; esac; then
              unzip -q "$cache_file" -d "${TARGET_DIR}" || true
            else
              cp "$cache_file" "${TARGET_DIR}/bin/gcp" || true
              chmod +x "${TARGET_DIR}/bin/gcp" || true
            fi
          fi
        else
          if [ -n "${GCP_DOWNLOAD_URL:-}" ]; then
            TEMP_FILE=$(mktemp)
            libscript_download "${GCP_DOWNLOAD_URL:-}" "${TEMP_FILE}"
            if case "${GCP_DOWNLOAD_URL:-}" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "${TEMP_FILE}" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "${GCP_DOWNLOAD_URL:-}" in *.zip) true;; *) false;; esac; then
              unzip -q "${TEMP_FILE}" -d "${TARGET_DIR}" || true
            else
              cp "${TEMP_FILE}" "${TARGET_DIR}/bin/gcp" || true
              chmod +x "${TARGET_DIR}/bin/gcp" || true
            fi
            rm -f "${TEMP_FILE}"
          else
            log_warn "No download URL provided for gcp ${VERSION}."
          fi
        fi
      else
        log_info "gcp ${VERSION} is already installed."
      fi
      libscript_symlink_alias "gcp" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down)
    if [ "$GCP_INSTALL_METHOD" = "libscript_native" ] || [ "$GCP_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-gcp}}"
      libscript_service "$ACTION" "$service_name" "$@"
    else
      log_info "$ACTION not natively implemented for $GCP_INSTALL_METHOD."
    fi
    exit 0
    ;;
  install-service)
    if [ "$GCP_INSTALL_METHOD" = "libscript_native" ] || [ "$GCP_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-gcp}}"
      libscript_install_service "$service_name" "$@"
    else
      log_info "install-service not implemented for $GCP_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall-service)
    if [ "$GCP_INSTALL_METHOD" = "libscript_native" ] || [ "$GCP_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-gcp}}"
      libscript_uninstall_service "$service_name" "$@"
    else
      log_info "uninstall-service not implemented for $GCP_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall)
    if [ "$GCP_INSTALL_METHOD" = "libscript_native" ]; then
      if type resolve_exact_version >/dev/null 2>&1; then resolve_exact_version; else EXACT_VERSION="${VERSION:-latest}"; fi
      log_info "Uninstalling gcp $VERSION..."
      rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/gcp/${EXACT_VERSION}"
      rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/gcp/$VERSION"
    else
      log_info "Uninstall not implemented or supported for $GCP_INSTALL_METHOD."
    fi
    exit 0
    ;;

esac
