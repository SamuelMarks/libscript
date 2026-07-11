#!/bin/sh
# ## Overview
# Generic setup module for azure.
# 
# ## Usage
# Execute this script to perform generic initialization steps for azure.

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

AZURE_INSTALL_METHOD="$(libscript_resolve_install_method "AZURE")"
ACTION="${ACTION:-install}"
VERSION="${AZURE_VERSION:-latest}"

resolve_exact_version() {
  if [ "${VERSION:-}" = "latest" ] || [ "${VERSION:-}" = "lts" ] || [ "${VERSION:-}" = "stable" ]; then
    _latest=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" ls-remote azure 2>/dev/null | tail -n 1)
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
        IMAGE=${3:-}; RG=${4:-}
        if [ -z "$IMAGE" ] || [ -z "$RG" ]; then printf '%s\n' "Usage: node create <name> <image> <rg> [args...]"; exit 1; fi
        SIZE="${size:-Standard_D2s_v7}"
        printf '%s\n' "Creating Azure VM: $RESOURCE_NAME in $RG ($SIZE, $IMAGE)"
        shift 4
        ARGS=""
        if [ -n "${vnet_name:-}" ]; then ARGS="$ARGS --vnet-name ${vnet_name}"; fi
        if [ -n "${nsg:-}" ]; then ARGS="$ARGS --nsg ${nsg}"; fi
        if [ -n "${os_disk_size_gb:-}" ]; then ARGS="$ARGS --os-disk-size-gb ${os_disk_size_gb}"; fi
        
        TAGS_ARG="$(libscript_format_tags azure)"
        if az vm show -g "$RG" -n "$RESOURCE_NAME" >/dev/null 2>&1; then
          printf '%s\n' "VM '$RESOURCE_NAME' already exists in resource group '$RG'."
        else
          # shellcheck disable=SC2086
          az vm create --resource-group "$RG" --name "$RESOURCE_NAME" --image "$IMAGE" --size "$SIZE" --admin-username azureuser --generate-ssh-keys --public-ip-sku Standard $ARGS $TAGS_ARG
        fi
        ;;
      delete)
        RG=${3:-}
        if [ -z "$RG" ]; then printf '%s\n' "Usage: node delete <name> <rg>"; exit 1; fi
        libscript_verify_managed azure node "$RESOURCE_NAME" "$RG" || exit 1
        printf '%s\n' "Deleting Azure VM: $RESOURCE_NAME from $RG"
        if az vm show -g "$RG" -n "$RESOURCE_NAME" >/dev/null 2>&1; then
          az vm delete --name "$RESOURCE_NAME" --resource-group "$RG" --yes
        else
          printf '%s\n' "VM '$RESOURCE_NAME' already deleted or not found in resource group '$RG'."
        fi
        ;;
      list)
        RG=${3:-}
        if [ -n "$RG" ]; then az vm list -g "$RG" -o table; else az vm list -o table; fi
        ;;
      update)
        RG=${3:-}
        if [ -z "$RG" ]; then printf '%s\n' "Usage: node update <name> <rg> [--size SIZE] [--tags T]"; exit 1; fi
        libscript_verify_managed azure node "$RESOURCE_NAME" "$RG" || exit 1
        shift 3
        while [ $# -gt 0 ]; do
          case "$1" in
            --size)
              az vm resize -g "$RG" -n "$RESOURCE_NAME" --size "$2"
              shift 2 ;;
            --tags)
              az vm update -g "$RG" -n "$RESOURCE_NAME" --set tags="$2"
              shift 2 ;;
            *)
              printf '%s\n' "Unknown option: $1"; exit 1 ;;
          esac
        done
        ;;
      exec)
        RG=${3:-}; shift 3
        if [ -z "$RG" ]; then printf '%s\n' "Usage: node exec <name> <rg> <cmd...>"; exit 1; fi
        IP=$(az vm show -d -g "$RG" -n "$RESOURCE_NAME" --query publicIps -o tsv | xargs)
        ssh -o StrictHostKeyChecking=no "azureuser@$IP" "$@"
        ;;
      deploy)
        RG=${3:-}; SRC=${4:-}; DST=${5:-}
        if [ -z "$DST" ]; then printf '%s\n' "Usage: node deploy <name> <rg> <src> <dst>"; exit 1; fi
        IP=$(az vm show -d -g "$RG" -n "$RESOURCE_NAME" --query publicIps -o tsv | xargs)
        if command -v rsync >/dev/null 2>&1; then
          rsync -avz -e "ssh -o StrictHostKeyChecking=no" "$SRC" "azureuser@$IP:$DST"
        else
          scp -o StrictHostKeyChecking=no -r "$SRC" "azureuser@$IP:$DST"
        fi
        ;;
      scp)
        RG=${3:-}; SRC=${4:-}; DST=${5:-}
        if [ -z "$DST" ]; then printf '%s\n' "Usage: node scp <name> <rg> <src> <dst>"; exit 1; fi
        IP=$(az vm show -d -g "$RG" -n "$RESOURCE_NAME" --query publicIps -o tsv | xargs)
        scp -o StrictHostKeyChecking=no "$SRC" "azureuser@$IP:$DST"
        ;;
      scp-from)
        RG=${3:-}; SRC=${4:-}; DST=${5:-}
        if [ -z "$DST" ]; then printf '%s\n' "Usage: node scp-from <name> <rg> <src> <dst>"; exit 1; fi
        IP=$(az vm show -d -g "$RG" -n "$RESOURCE_NAME" --query publicIps -o tsv | xargs)
        scp -o StrictHostKeyChecking=no "azureuser@$IP:$SRC" "$DST"
        ;;
      sync)
        RG=${3:-}
        if [ -z "$RG" ]; then printf '%s\n' "Usage: node sync <name> <rg>"; exit 1; fi
        IP=$(az vm show -d -g "$RG" -n "$RESOURCE_NAME" --query publicIps -o tsv | xargs)
        ssh -o StrictHostKeyChecking=no "azureuser@$IP" "mkdir -p ~/libscript"
        if command -v rsync >/dev/null 2>&1; then
          rsync -avz -e "ssh -o StrictHostKeyChecking=no" "${LIBSCRIPT_ROOT_DIR}/" "azureuser@$IP:~/libscript/"
        else
          scp -o StrictHostKeyChecking=no -r "${LIBSCRIPT_ROOT_DIR}/"* "azureuser@$IP:~/libscript/"
        fi
        ;;
      *)
        printf '%s\n' "Unknown node action: $SUBACTION"; exit 1
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
            ZONE=${3:-}; RG=${4:-}
            if [ -z "$ZONE" ] || [ -z "$RG" ]; then printf '%s\n' "Usage: dns zone create <zone> <rg>"; exit 1; fi
            TAGS_ARG="$(libscript_format_tags azure)"
            if az network dns zone show -g "$RG" -n "$ZONE" >/dev/null 2>&1; then
              printf '%s\n' "DNS zone '$ZONE' already exists in resource group '$RG'."
            else
              # shellcheck disable=SC2086
              az network dns zone create -g "$RG" -n "$ZONE" $TAGS_ARG
            fi
            ;;
          delete)
            ZONE=${3:-}; RG=${4:-}
            if [ -z "$ZONE" ] || [ -z "$RG" ]; then printf '%s\n' "Usage: dns zone delete <zone> <rg>"; exit 1; fi
            libscript_verify_managed azure dns "$ZONE" "$RG" || exit 1
            if az network dns zone show -g "$RG" -n "$ZONE" >/dev/null 2>&1; then
              az network dns zone delete -g "$RG" -n "$ZONE" --yes
            else
              printf '%s\n' "DNS zone '$ZONE' already deleted or not found in resource group '$RG'."
            fi
            ;;
          list)
            RG=${3:-}
            if [ -n "$RG" ]; then az network dns zone list -g "$RG" -o table; else az network dns zone list -o table; fi
            ;;
          *)
            printf '%s\n' "Unknown dns zone action: $SUBTYPE"; exit 1 ;;
        esac
        ;;
      record)
        case "$SUBTYPE" in
          create|update)
            ZONE=${3:-}; RG=${4:-}; NAME=${5:-}; TYPE=${6:-}; VALUE=${7:-}
            if [ -z "$VALUE" ]; then printf '%s\n' "Usage: dns record $SUBTYPE <zone> <rg> <name> <type> <value>"; exit 1; fi
            if [ "$SUBTYPE" = "update" ]; then
              libscript_verify_managed azure dns "$ZONE" "$RG" || exit 1
            fi
            if [ "$TYPE" = "A" ]; then
              az network dns record-set a add-record -g "$RG" -z "$ZONE" -n "$NAME" -a "$VALUE"
            elif [ "$TYPE" = "CNAME" ]; then
              az network dns record-set cname set-record -g "$RG" -z "$ZONE" -n "$NAME" -c "$VALUE"
            elif [ "$TYPE" = "TXT" ]; then
              az network dns record-set txt add-record -g "$RG" -z "$ZONE" -n "$NAME" -v "$VALUE"
            else
              printf '%s\n' "Type $TYPE not supported yet."; exit 1
            fi
            ;;
          delete)
            ZONE=${3:-}; RG=${4:-}; NAME=${5:-}; TYPE=${6:-}
            if [ -z "$TYPE" ]; then printf '%s\n' "Usage: dns record delete <zone> <rg> <name> <type>"; exit 1; fi
            libscript_verify_managed azure dns "$ZONE" "$RG" || exit 1
            az network dns record-set "$(printf '%s\n' "$TYPE" | tr '[:upper:]' '[:lower:]')" delete -g "$RG" -z "$ZONE" -n "$NAME" --yes
            ;;
          list)
            ZONE=${3:-}; RG=${4:-}
            if [ -z "$RG" ]; then printf '%s\n' "Usage: dns record list <zone> <rg>"; exit 1; fi
            az network dns record-set list -g "$RG" -z "$ZONE" -o table
            ;;
          *)
            printf '%s\n' "Unknown dns record action: $SUBTYPE"; exit 1 ;;
        esac
        ;;
      map-node)
        DOMAIN=${2:-}; ZONE=${3:-}; RG=${4:-}; VM_NAME=${5:-}
        if [ -z "$VM_NAME" ]; then printf '%s\n' "Usage: dns map-node <domain> <zone> <rg> <vm-name>"; exit 1; fi
        IP=$(az vm show -d -g "$RG" -n "$VM_NAME" --query publicIps -o tsv | xargs)
        RECORD_NAME=${DOMAIN%.$ZONE}
        if [ "$RECORD_NAME" = "$DOMAIN" ]; then RECORD_NAME="@"; fi
        az network dns record-set a add-record -g "$RG" -z "$ZONE" -n "$RECORD_NAME" -a "$IP"
        ;;
      unmap-node)
        DOMAIN=${2:-}; ZONE=${3:-}; RG=${4:-}; VM_NAME=${5:-}
        if [ -z "$VM_NAME" ]; then printf '%s\n' "Usage: dns unmap-node <domain> <zone> <rg> <vm-name>"; exit 1; fi
        IP=$(az vm show -d -g "$RG" -n "$VM_NAME" --query publicIps -o tsv | xargs)
        RECORD_NAME=${DOMAIN%.$ZONE}
        if [ "$RECORD_NAME" = "$DOMAIN" ]; then RECORD_NAME="@"; fi
        az network dns record-set a remove-record -g "$RG" -z "$ZONE" -n "$RECORD_NAME" -a "$IP"
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
    RESOURCE_GROUP=${3:-}
    case "$SUBACTION" in
      create)
        if [ -z "$RESOURCE_NAME" ] || [ -z "$RESOURCE_GROUP" ]; then
          printf '%s\n' "Usage: firewall create <name> <resource-group> [ports...]"
          exit 1
        fi
        LOC="${AZURE_LOCATION:-eastus}"
        printf '%s\n' "Creating Azure NSG: $RESOURCE_NAME in $RESOURCE_GROUP ($LOC)"
        TAGS_ARG="$(libscript_format_tags azure)"
        if az network nsg show -g "$RESOURCE_GROUP" -n "$RESOURCE_NAME" >/dev/null 2>&1; then
          printf '%s\n' "NSG '$RESOURCE_NAME' already exists in resource group '$RESOURCE_GROUP'."
        else
          # shellcheck disable=SC2086
          az network nsg create --name "$RESOURCE_NAME" --resource-group "$RESOURCE_GROUP" --location "$LOC" $TAGS_ARG
        fi
        shift 3
        PRIORITY=1000
        while [ $# -gt 0 ]; do
          PORT=$1
          printf '%s\n' "Opening port $PORT on $RESOURCE_NAME"
          az network nsg rule create --resource-group "$RESOURCE_GROUP" --nsg-name "$RESOURCE_NAME" --name "Allow_$PORT" --priority "$PRIORITY" --destination-port-ranges "$PORT" --access Allow --protocol Tcp
          PRIORITY=$((PRIORITY + 10))
          shift
        done
        ;;
      delete)
        if [ -z "$RESOURCE_NAME" ] || [ -z "$RESOURCE_GROUP" ]; then
          printf '%s\n' "Usage: firewall delete <name> <resource-group>"
          exit 1
        fi
        libscript_verify_managed azure firewall "$RESOURCE_NAME" "$RESOURCE_GROUP" || exit 1
        printf '%s\n' "Deleting Azure NSG: $RESOURCE_NAME from $RESOURCE_GROUP"
        if az network nsg show -g "$RESOURCE_GROUP" -n "$RESOURCE_NAME" >/dev/null 2>&1; then
          az network nsg delete --name "$RESOURCE_NAME" --resource-group "$RESOURCE_GROUP" --yes
        else
          printf '%s\n' "NSG '$RESOURCE_NAME' already deleted or not found in resource group '$RESOURCE_GROUP'."
        fi
        ;;
      list)
        if [ -n "$RESOURCE_GROUP" ]; then
          az network nsg list --resource-group "$RESOURCE_GROUP" -o table
        else
          az network nsg list -o table
        fi
        ;;
      update)
        if [ -z "$RESOURCE_NAME" ] || [ -z "$RESOURCE_GROUP" ]; then
          printf '%s\n' "Usage: firewall update <name> <resource-group> [--add-port PORT] [--remove-port PORT]"
          exit 1
        fi
        libscript_verify_managed azure firewall "$RESOURCE_NAME" "$RESOURCE_GROUP" || exit 1
        PRIORITY=2000
        while [ $# -gt 0 ]; do
          case "$1" in
            --add-port)
              PORT=$2
              az network nsg rule create --resource-group "$RESOURCE_GROUP" --nsg-name "$RESOURCE_NAME" --name "Allow_$PORT" --priority "$PRIORITY" --destination-port-ranges "$PORT" --access Allow --protocol Tcp
              PRIORITY=$((PRIORITY + 10))
              shift 2 ;;
            --remove-port)
              PORT=$2
              az network nsg rule delete --resource-group "$RESOURCE_GROUP" --nsg-name "$RESOURCE_NAME" --name "Allow_$PORT"
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
    RESOURCE_GROUP=${3:-}
    case "$SUBACTION" in
      create)
        if [ -z "$RESOURCE_NAME" ] || [ -z "$RESOURCE_GROUP" ]; then
          printf '%s\n' "Usage: network create <name> <resource-group>"
          exit 1
        fi
        LOC="${AZURE_LOCATION:-eastus}"
        printf '%s\n' "Creating Azure VNet: $RESOURCE_NAME in $RESOURCE_GROUP ($LOC)"
        TAGS_ARG="$(libscript_format_tags azure)"
        if az network vnet show -g "$RESOURCE_GROUP" -n "$RESOURCE_NAME" >/dev/null 2>&1; then
          printf '%s\n' "VNet '$RESOURCE_NAME' already exists in resource group '$RESOURCE_GROUP'."
        else
          # shellcheck disable=SC2086
          az network vnet create --name "$RESOURCE_NAME" --resource-group "$RESOURCE_GROUP" --location "$LOC" $TAGS_ARG
        fi
        ;;
      delete)
        if [ -z "$RESOURCE_NAME" ] || [ -z "$RESOURCE_GROUP" ]; then
          printf '%s\n' "Usage: network delete <name> <resource-group>"
          exit 1
        fi
        libscript_verify_managed azure network "$RESOURCE_NAME" "$RESOURCE_GROUP" || exit 1
        printf '%s\n' "Deleting Azure VNet: $RESOURCE_NAME from $RESOURCE_GROUP"
        if az network vnet show -g "$RESOURCE_GROUP" -n "$RESOURCE_NAME" >/dev/null 2>&1; then
          az network vnet delete --name "$RESOURCE_NAME" --resource-group "$RESOURCE_GROUP" --yes
        else
          printf '%s\n' "VNet '$RESOURCE_NAME' already deleted or not found in resource group '$RESOURCE_GROUP'."
        fi
        ;;
      list)
        if [ -n "$RESOURCE_GROUP" ]; then
          az network vnet list --resource-group "$RESOURCE_GROUP" -o table
        else
          az network vnet list -o table
        fi
        ;;
      update)
        if [ -z "$RESOURCE_NAME" ] || [ -z "$RESOURCE_GROUP" ]; then
          printf '%s\n' "Usage: network update <name> <resource-group> [--tags T]"
          exit 1
        fi
        libscript_verify_managed azure network "$RESOURCE_NAME" "$RESOURCE_GROUP" || exit 1
        while [ $# -gt 0 ]; do
          case "$1" in
            --tags)
              az network vnet update --name "$RESOURCE_NAME" --resource-group "$RESOURCE_GROUP" --set tags="$2"
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
        az login
        ;;
      logout)
        az logout
        ;;
      status)
        az account show
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
        az account list-locations --query "[].name" -o tsv
        ;;
      select)
        if [ -n "${2:-}" ]; then
          az configure --defaults location="$2"
          printf '%s\n' "Default location set to $2."
        else
          printf '%s\n' "Usage: location select <location>"
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
    if [ "$AZURE_INSTALL_METHOD" = "mise" ]; then
      mise ls azure || true
    elif [ "$AZURE_INSTALL_METHOD" = "asdf" ]; then
      asdf list azure || true
    elif [ "$AZURE_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "$AZURE_INSTALL_METHOD" = "vfox" ]; then
      vfox ls azure || true
    elif [ "$AZURE_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System packages do not support ls here."
    else
      ls -1 "${LIBSCRIPT_HOME:-$HOME/.libscript}/azure/" 2>/dev/null || true
    fi
    exit 0
    ;;
  ls-remote)
    if [ "$AZURE_INSTALL_METHOD" = "mise" ]; then
      mise ls-remote azure || true
    elif [ "$AZURE_INSTALL_METHOD" = "asdf" ]; then
      asdf list all azure || true
    elif [ "$AZURE_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not have a local list command"
    elif [ "$AZURE_INSTALL_METHOD" = "vfox" ]; then
      vfox ls all azure || true
    else
      if [ -n "${AZURE_RELEASES_URL:-}" ]; then
        curl -sSL "${AZURE_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s\n' "No versions found"
      else
      git ls-remote --tags "https://github.com/MicrosoftDocs/azure-docs" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort -V | uniq || printf '%s\n' "No versions found"
    fi
    fi
    exit 0
    ;;
  use)
    if [ "$AZURE_INSTALL_METHOD" = "mise" ]; then
      mise use "azure@${VERSION}"
    elif [ "$AZURE_INSTALL_METHOD" = "asdf" ]; then
      asdf global azure "${VERSION}"
    elif [ "$AZURE_INSTALL_METHOD" = "pkgx" ]; then
      printf '%s\n' "pkgx does not use explicit versions this way"
    elif [ "$AZURE_INSTALL_METHOD" = "vfox" ]; then
      vfox use "azure@${VERSION}"
    elif [ "$AZURE_INSTALL_METHOD" = "vfox" ]; then
      vfox use "azure@${VERSION}"
    elif [ "$AZURE_INSTALL_METHOD" = "system" ]; then
      printf '%s\n' "System packages do not support use here."
    else
      resolve_exact_version
      libscript_symlink_alias "azure" "$VERSION" "${EXACT_VERSION}"
      libscript_symlink_alias "azure" "default" "${EXACT_VERSION}"
      
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/azure/${EXACT_VERSION}"
      if [ ! -d "$TARGET_DIR" ]; then
        log_info "azure ${EXACT_VERSION} is not installed. Installing it now..."
        unset SCRIPT_NAME || true
        ACTION="install" sh "$DIR/setup.sh" install "$PACKAGE_NAME" "" || exit 1
      fi

      libscript_symlink_alias "azure" "default" "${EXACT_VERSION}"
      log_info "Set default azure version to ${EXACT_VERSION}."
      log_info "To apply to the current shell, run:"
      log_info "  eval \$(\"${LIBSCRIPT_ROOT_DIR}/libscript.sh\" env azure \"$VERSION\")"
    fi
    exit 0
    ;;
  download)
    if [ "$AZURE_INSTALL_METHOD" = "libscript_native" ]; then
      log_info "Downloading azure ${VERSION} to ${DOWNLOAD_DIR:-/tmp/libscript_downloads}/azure..."
      mkdir -p "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/azure"
      if [ -n "${AZURE_DOWNLOAD_URL:-}" ]; then
        libscript_download "${AZURE_DOWNLOAD_URL:-}" "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/azure/azure-${VERSION}.tar.gz"
      else
        log_warn "AZURE_DOWNLOAD_URL is not defined for azure ${VERSION}."
      fi
    fi
    exit 0
    ;;
  install|*)
    if [ "$AZURE_INSTALL_METHOD" = "system" ]; then
      libscript_depends "azure"
    elif [ "$AZURE_INSTALL_METHOD" = "mise" ]; then
      mise install "azure@${VERSION}"
    elif [ "$AZURE_INSTALL_METHOD" = "asdf" ]; then
      asdf install azure "${VERSION}"
    elif [ "$AZURE_INSTALL_METHOD" = "pkgx" ]; then
      pkgx install "azure@${VERSION}"
    elif [ "$AZURE_INSTALL_METHOD" = "vfox" ]; then
      vfox add azure || true
      vfox install "azure@${VERSION}"
    else
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/azure/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing azure ${VERSION} natively to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}/bin"
        if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/azure/"*"${VERSION}"* >/dev/null 2>&1; then
          log_info "Extracting from cache..."
          cache_file=$(find "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/azure/" -maxdepth 1 -type f -name "*${VERSION}*" 2>/dev/null | head -n 1 || true)
          if [ -n "$cache_file" ]; then
            if case "$cache_file" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "$cache_file" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "$cache_file" in *.zip) true;; *) false;; esac; then
              unzip -q "$cache_file" -d "${TARGET_DIR}" || true
            else
              cp "$cache_file" "${TARGET_DIR}/bin/azure" || true
              chmod +x "${TARGET_DIR}/bin/azure" || true
            fi
          fi
        else
          if [ -n "${AZURE_DOWNLOAD_URL:-}" ]; then
            TEMP_FILE=$(mktemp)
            libscript_download "${AZURE_DOWNLOAD_URL:-}" "${TEMP_FILE}"
            if case "${AZURE_DOWNLOAD_URL:-}" in *.tar.gz|*.tgz) true;; *) false;; esac; then
              tar -xzf "${TEMP_FILE}" -C "${TARGET_DIR}" --strip-components=1 || true
            elif case "${AZURE_DOWNLOAD_URL:-}" in *.zip) true;; *) false;; esac; then
              unzip -q "${TEMP_FILE}" -d "${TARGET_DIR}" || true
            else
              cp "${TEMP_FILE}" "${TARGET_DIR}/bin/azure" || true
              chmod +x "${TARGET_DIR}/bin/azure" || true
            fi
            rm -f "${TEMP_FILE}"
          else
            log_warn "No download URL provided for azure ${VERSION}."
          fi
        fi
      else
        log_info "azure ${VERSION} is already installed."
      fi
      libscript_symlink_alias "azure" "$VERSION" "${EXACT_VERSION}"
    fi
    ;;
  start|stop|restart|status|health|logs|up|down)
    if [ "$AZURE_INSTALL_METHOD" = "libscript_native" ] || [ "$AZURE_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-azure}}"
      libscript_service "$ACTION" "$service_name" "$@"
    else
      log_info "$ACTION not natively implemented for $AZURE_INSTALL_METHOD."
    fi
    exit 0
    ;;
  install-service)
    if [ "$AZURE_INSTALL_METHOD" = "libscript_native" ] || [ "$AZURE_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-azure}}"
      libscript_install_service "$service_name" "$@"
    else
      log_info "install-service not implemented for $AZURE_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall-service)
    if [ "$AZURE_INSTALL_METHOD" = "libscript_native" ] || [ "$AZURE_INSTALL_METHOD" = "system" ]; then
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/service_install.sh"
      export SCRIPT_NAME
      . "${SCRIPT_NAME}"
      service_name="${LIBSCRIPT_SERVICE_NAME:-libscript_${PACKAGE_NAME:-azure}}"
      libscript_uninstall_service "$service_name" "$@"
    else
      log_info "uninstall-service not implemented for $AZURE_INSTALL_METHOD."
    fi
    exit 0
    ;;
  uninstall)
    if [ "$AZURE_INSTALL_METHOD" = "libscript_native" ]; then
      if type resolve_exact_version >/dev/null 2>&1; then resolve_exact_version; else EXACT_VERSION="${VERSION:-latest}"; fi
      log_info "Uninstalling azure $VERSION..."
      rm -rf "${LIBSCRIPT_HOME:-$HOME/.libscript}/azure/${EXACT_VERSION}"
      rm -f "${LIBSCRIPT_HOME:-$HOME/.libscript}/azure/$VERSION"
    else
      log_info "Uninstall not implemented or supported for $AZURE_INSTALL_METHOD."
    fi
    exit 0
    ;;

esac
