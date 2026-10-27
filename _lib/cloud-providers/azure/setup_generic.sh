#!/bin/sh
# ## Overview
# Generic setup module for azure.
# 
# ## Usage
# Execute this script to perform generic initialization steps for azure.

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

for LIB in "_lib/_common/pkg_mgr.sh" "_lib/_common/os_info.sh" "_lib/_common/versioning.sh" "_lib/cloud/core/tags.sh"; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
done

AZURE_INSTALL_METHOD="$(libscript_resolve_install_method "AZURE")"
ACTION="${ACTION:-install}"
VERSION="${AZURE_VERSION:-latest}"

# ## az
# Wrapper around Azure CLI supporting DRY_RUN=true or unauthenticated local environments.
az() {
  if [ "${DRY_RUN:-}" = "true" ] || ! command -v az >/dev/null 2>&1; then
    printf '[DRY_RUN] az %s\n' "$*" >&2
    case "$*" in
      *"show -d"*) printf '127.0.0.1\n'; return 0 ;;
      *"show"*) return 1 ;;
      *) return 0 ;;
    esac
  fi
  command az "$@"
}

# ## resolve_exact_version
# Resolves semantic version aliases (such as 'latest' or 'lts') to a concrete release version.
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
  group|project)
    SUBACTION=${1:-ensure}
    RG=${2:-}
    if [ -z "$RG" ]; then
      printf '%s\n' 'Usage: group ensure <rg_name> [--location <loc>]'
      exit 1
    fi
    LOC="${AZURE_LOCATION:-${LOCATION:-eastus}}"
    shift 2 || true
    while [ $# -gt 0 ]; do
      case "$1" in
        --location|-l) LOC="$2"; shift 2 ;;
        --location=*) LOC="${1#*=}"; shift ;;
        *) shift ;;
      esac
    done
    case "$SUBACTION" in
      ensure|create)
        TAGS_ARG="$(libscript_format_tags azure)"
        if [ "$(az group exists --name "$RG" 2>/dev/null | tr -d '\r[:space:]')" = "true" ]; then
          printf '%s\n' "Resource group '$RG' already exists."
        else
          printf '%s\n' "Creating Azure resource group '$RG' in '$LOC'..."
          # shellcheck disable=SC2086
          az group create --name "$RG" --location "$LOC" $TAGS_ARG --output none
        fi
        ;;
      delete)
        az group delete --name "$RG" --yes --no-wait
        ;;
      *)
        printf '%s\n' "Unknown group sub-action: $SUBACTION"
        exit 1
        ;;
    esac
    exit 0
    ;;
  node)
    SUBACTION=${1:-}
    RESOURCE_NAME=${2:-}
    case "$SUBACTION" in
      create)
        IMAGE=${3:-}; RG=${4:-}
        if [ -z "$IMAGE" ] || [ -z "$RG" ]; then printf '%s\n' "Usage: node create <name> <image> <rg> [args...]"; exit 1; fi
        SIZE="${size:-Standard_D2s_v7}"
        VNET_VAL="${vnet_name:-}"
        NSG_VAL="${nsg:-}"
        DISK_VAL="${os_disk_size_gb:-}"
        ADMIN_VAL="${ADMIN_USER:-azureuser}"
        shift 4
        while [ $# -gt 0 ]; do
          case "$1" in
            --size) SIZE="$2"; shift 2 ;;
            --size=*) SIZE="${1#*=}"; shift ;;
            --vnet-name) VNET_VAL="$2"; shift 2 ;;
            --vnet-name=*) VNET_VAL="${1#*=}"; shift ;;
            --nsg) NSG_VAL="$2"; shift 2 ;;
            --nsg=*) NSG_VAL="${1#*=}"; shift ;;
            --os-disk-size-gb) DISK_VAL="$2"; shift 2 ;;
            --os-disk-size-gb=*) DISK_VAL="${1#*=}"; shift ;;
            --admin-username) ADMIN_VAL="$2"; shift 2 ;;
            --admin-username=*) ADMIN_VAL="${1#*=}"; shift ;;
            *) shift ;;
          esac
        done
        ARGS=""
        if [ -n "$VNET_VAL" ]; then ARGS="$ARGS --vnet-name $VNET_VAL"; fi
        if [ -n "$NSG_VAL" ]; then ARGS="$ARGS --nsg $NSG_VAL"; fi
        if [ -n "$DISK_VAL" ]; then ARGS="$ARGS --os-disk-size-gb $DISK_VAL"; fi
        TAGS_ARG="$(libscript_format_tags azure)"
        if az vm show -g "$RG" -n "$RESOURCE_NAME" >/dev/null 2>&1; then
          printf '%s\n' "VM '$RESOURCE_NAME' already exists in resource group '$RG'."
        else
          printf '%s\n' "Creating Azure VM: $RESOURCE_NAME in $RG ($SIZE, $IMAGE)"
          # shellcheck disable=SC2086
          az vm create --resource-group "$RG" --name "$RESOURCE_NAME" --image "$IMAGE" --size "$SIZE" --admin-username "$ADMIN_VAL" --generate-ssh-keys --public-ip-sku Standard $ARGS $TAGS_ARG
        fi
        ;;
      ip)
        RG=${3:-}
        if [ -z "$RESOURCE_NAME" ] || [ -z "$RG" ]; then printf '%s\n' "Usage: node ip <name> <rg>" >&2; exit 1; fi
        IP=$(az vm show -d -g "$RG" -n "$RESOURCE_NAME" --query publicIps -o tsv | xargs)
        printf '%s\n' "$IP"
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
        if [ "${DRY_RUN:-}" = "true" ] || [ "${DRY_RUN:-0}" = "1" ]; then
          printf '[DRY_RUN] Executing on %s (%s): %s\n' "$RESOURCE_NAME" "$RG" "$*"
          exit 0
        fi
        IP=$(az vm show -d -g "$RG" -n "$RESOURCE_NAME" --query publicIps -o tsv | xargs)
        ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o ConnectTimeout=30 "${ADMIN_USER:-azureuser}@$IP" "$@"
        ;;
      attach-disk)
        RG=${3:-}; DISK_NAME=${4:-}
        if [ -z "$DISK_NAME" ] || [ "$DISK_NAME" = "null" ]; then
          printf '%s\n' 'No disk name specified, skipping attach-disk.'
          exit 0
        fi
        if az vm show -g "$RG" -n "$RESOURCE_NAME" --query "storageProfile.dataDisks[?name=='$DISK_NAME'] | [0].name" -o tsv 2>/dev/null | grep -q .; then
          printf '%s\n' "Disk '$DISK_NAME' already attached to '$RESOURCE_NAME'."
        elif az disk show -g "$RG" -n "$DISK_NAME" >/dev/null 2>&1; then
          az vm disk attach -g "$RG" --vm-name "$RESOURCE_NAME" --name "$DISK_NAME" || true
        else
          printf '%s\n' "Disk '$DISK_NAME' already attached or managed in '$RG'."
        fi
        ;;
      deploy)
        RG=${3:-}; SRC=${4:-}; DST=${5:-}
        if [ -z "$DST" ]; then printf '%s\n' "Usage: node deploy <name> <rg> <src> <dst>"; exit 1; fi
        if [ "${DRY_RUN:-}" = "true" ] || ! command -v az >/dev/null 2>&1; then
          printf '[DRY_RUN] Deploying %s to %s (%s) -> %s\n' "$SRC" "$RESOURCE_NAME" "$RG" "$DST"
          exit 0
        fi
        IP=$(az vm show -d -g "$RG" -n "$RESOURCE_NAME" --query publicIps -o tsv | xargs)
        _src_sync="$SRC"
        if [ -d "$SRC" ]; then
          _src_sync="${SRC%/}/"
        fi
        if command -v rsync >/dev/null 2>&1; then
          rsync -avz --exclude=".git" --exclude="node_modules" --exclude="target" --exclude=".venv" --exclude="venv" --exclude=".angular" --exclude=".next" --exclude=".nuxt" --exclude=".turbo" --exclude=".parcel-cache" --exclude=".cache" --exclude=".tox" --exclude=".nox" --exclude=".terraform" --exclude=".mypy_cache" --exclude=".pytest_cache" --exclude=".ruff_cache" --exclude="__pycache__" --exclude="*.pyc" --exclude="*.pyo" --exclude=".DS_Store" --exclude="dist" --exclude="build" --exclude=".gradle" --exclude=".kotlin" --exclude="htmlcov" --exclude="coverage" --exclude=".coverage" --exclude="coverage.*" --exclude="combined-coverage.*" --exclude="test-results" --exclude="playwright-report" --exclude="documentation" --exclude="e2e_test.db" --exclude="logs" --exclude="*.duckdb" --exclude="*.duckdb.wal" -e "ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o ConnectTimeout=30" "$_src_sync" "${ADMIN_USER:-azureuser}@$IP:${DST%/}/"
        elif command -v tar >/dev/null 2>&1 && [ -d "$SRC" ]; then
          tar -czf - -C "$SRC" --exclude=".git" --exclude="node_modules" --exclude="target" --exclude=".venv" --exclude="venv" --exclude=".angular" --exclude=".next" --exclude=".nuxt" --exclude=".turbo" --exclude=".parcel-cache" --exclude=".cache" --exclude=".tox" --exclude=".nox" --exclude=".terraform" --exclude=".mypy_cache" --exclude=".pytest_cache" --exclude=".ruff_cache" --exclude="__pycache__" --exclude="*.pyc" --exclude="*.pyo" --exclude=".DS_Store" --exclude="dist" --exclude="build" --exclude=".gradle" --exclude=".kotlin" --exclude="htmlcov" --exclude="coverage" --exclude=".coverage" --exclude="test-results" --exclude="playwright-report" --exclude="documentation" --exclude="e2e_test.db" --exclude="logs" --exclude="*.duckdb" --exclude="*.duckdb.wal" . | ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o ConnectTimeout=30 "${ADMIN_USER:-azureuser}@$IP" "mkdir -p \"$DST\" && tar -xzf - -C \"$DST\""
        else
          scp -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o ConnectTimeout=30 -r "$SRC" "${ADMIN_USER:-azureuser}@$IP:$DST"
        fi
        ;;
      scp|upload)
        RG=${3:-}; SRC=${4:-}; DST=${5:-}
        if [ -z "$DST" ]; then printf '%s\n' "Usage: node $SUBACTION <name> <rg> <src> <dst>"; exit 1; fi
        if [ "${DRY_RUN:-}" = "true" ] || [ "${DRY_RUN:-0}" = "1" ]; then
          printf '[DRY_RUN] Uploading %s to %s (%s) -> %s\n' "$SRC" "$RESOURCE_NAME" "$RG" "$DST"
          exit 0
        fi
        IP=$(az vm show -d -g "$RG" -n "$RESOURCE_NAME" --query publicIps -o tsv | xargs)
        if command -v rsync >/dev/null 2>&1; then
          rsync -avz --exclude=".git" --exclude="node_modules" --exclude="target" --exclude=".venv" --exclude="venv" --exclude=".angular" --exclude=".next" --exclude=".nuxt" --exclude=".turbo" --exclude=".parcel-cache" --exclude=".cache" --exclude=".tox" --exclude=".nox" --exclude=".terraform" --exclude=".mypy_cache" --exclude=".pytest_cache" --exclude=".ruff_cache" --exclude="__pycache__" --exclude="*.pyc" --exclude="*.pyo" --exclude=".DS_Store" --exclude="dist" --exclude="build" --exclude=".gradle" --exclude=".kotlin" --exclude="htmlcov" --exclude="coverage" --exclude=".coverage" --exclude="coverage.*" --exclude="combined-coverage.*" --exclude="test-results" --exclude="playwright-report" --exclude="documentation" --exclude="e2e_test.db" --exclude="logs" --exclude="*.duckdb" --exclude="*.duckdb.wal" -e "ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o ConnectTimeout=30" "$SRC" "${ADMIN_USER:-azureuser}@$IP:$DST"
        elif command -v tar >/dev/null 2>&1 && [ -d "$SRC" ]; then
          tar -czf - -C "$SRC" --exclude=".git" --exclude="node_modules" --exclude="target" --exclude=".venv" --exclude="venv" --exclude=".angular" --exclude=".next" --exclude=".nuxt" --exclude=".turbo" --exclude=".parcel-cache" --exclude=".cache" --exclude=".tox" --exclude=".nox" --exclude=".terraform" --exclude=".mypy_cache" --exclude=".pytest_cache" --exclude=".ruff_cache" --exclude="__pycache__" --exclude="*.pyc" --exclude="*.pyo" --exclude=".DS_Store" --exclude="dist" --exclude="build" --exclude=".gradle" --exclude=".kotlin" --exclude="htmlcov" --exclude="coverage" --exclude=".coverage" --exclude="test-results" --exclude="playwright-report" --exclude="documentation" --exclude="e2e_test.db" --exclude="logs" --exclude="*.duckdb" --exclude="*.duckdb.wal" . | ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o ConnectTimeout=30 "${ADMIN_USER:-azureuser}@$IP" "mkdir -p \"$DST\" && tar -xzf - -C \"$DST\""
        else
          scp -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o ConnectTimeout=30 -r "$SRC" "${ADMIN_USER:-azureuser}@$IP:$DST"
        fi
        ;;
      scp-from|download)
        RG=${3:-}; SRC=${4:-}; DST=${5:-}
        if [ -z "$DST" ]; then printf '%s\n' "Usage: node $SUBACTION <name> <rg> <src> <dst>"; exit 1; fi
        if [ "${DRY_RUN:-}" = "true" ] || [ "${DRY_RUN:-0}" = "1" ]; then
          printf '[DRY_RUN] Downloading %s (%s):%s -> %s\n' "$RESOURCE_NAME" "$RG" "$SRC" "$DST"
          exit 0
        fi
        IP=$(az vm show -d -g "$RG" -n "$RESOURCE_NAME" --query publicIps -o tsv | xargs)
        mkdir -p "$(dirname "$DST")"
        if command -v rsync >/dev/null 2>&1; then
          rsync -avz -e "ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o ConnectTimeout=30" "${ADMIN_USER:-azureuser}@$IP:$SRC" "$DST" || scp -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o ConnectTimeout=30 -r "${ADMIN_USER:-azureuser}@$IP:$SRC" "$DST"
        else
          scp -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o ConnectTimeout=30 -r "${ADMIN_USER:-azureuser}@$IP:$SRC" "$DST"
        fi
        ;;
      sync)
        RG=${3:-}
        if [ -z "$RG" ]; then printf '%s\n' "Usage: node sync <name> <rg>"; exit 1; fi
        if [ "${DRY_RUN:-}" = "true" ] || [ "${DRY_RUN:-0}" = "1" ]; then
          printf '[DRY_RUN] Syncing LibScript to %s (%s)\n' "$RESOURCE_NAME" "$RG"
          exit 0
        fi
        IP=$(az vm show -d -g "$RG" -n "$RESOURCE_NAME" --query publicIps -o tsv | xargs)
        ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o ConnectTimeout=30 "${ADMIN_USER:-azureuser}@$IP" "mkdir -p ~/libscript"
        if command -v rsync >/dev/null 2>&1; then
          rsync -avz --exclude=".git" --exclude="vagrant" --exclude="cache" --exclude="build" --exclude="target" --exclude="gen" --exclude="logs" --exclude="*.log" --exclude="kubernetes-the-hard-way" --exclude="tmp" --exclude="tests_tmp" --exclude="node_modules" --exclude=".venv" --exclude=".DS_Store" -e "ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o ConnectTimeout=30" "${LIBSCRIPT_ROOT_DIR}/" "${ADMIN_USER:-azureuser}@$IP:~/libscript/"
        elif command -v tar >/dev/null 2>&1; then
          tar -czf - -C "${LIBSCRIPT_ROOT_DIR}" --exclude=".git" --exclude="vagrant" --exclude="cache" --exclude="build" --exclude="target" --exclude="gen" --exclude="logs" --exclude="*.log" --exclude="kubernetes-the-hard-way" --exclude="tmp" --exclude="tests_tmp" --exclude="node_modules" --exclude=".venv" --exclude=".DS_Store" . | ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o ConnectTimeout=30 "${ADMIN_USER:-azureuser}@$IP" "mkdir -p ~/libscript && tar -xzf - -C ~/libscript"
        else
          scp -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o ServerAliveCountMax=6 -o ConnectTimeout=30 -r "${LIBSCRIPT_ROOT_DIR}/"* "${ADMIN_USER:-azureuser}@$IP:~/libscript/"
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
            if [ "$TYPE" = "@" ] && { [ "$NAME" = "A" ] || [ "$NAME" = "CNAME" ] || [ "$NAME" = "TXT" ]; }; then
              _tmp_z="$ZONE"; ZONE="$RG"; RG="$_tmp_z"; TYPE="$NAME"; NAME="@"
            fi
            if [ "${DRY_RUN:-}" = "true" ] || [ "${DRY_RUN:-0}" = "1" ] || ! command -v az >/dev/null 2>&1; then
              printf '[DRY_RUN] az network dns record-set %s (%s) in zone %s (%s) -> %s\n' "$NAME" "$TYPE" "$ZONE" "$RG" "$VALUE"
              exit 0
            fi
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
        RECORD_NAME=${DOMAIN%."$ZONE"}
        if [ "$RECORD_NAME" = "$DOMAIN" ]; then RECORD_NAME="@"; fi
        az network dns record-set a delete -g "$RG" -z "$ZONE" -n "$RECORD_NAME" --yes >/dev/null 2>&1 || true
        az network dns record-set a add-record -g "$RG" -z "$ZONE" -n "$RECORD_NAME" -a "$IP" || true
        ;;
      unmap-node)
        DOMAIN=${2:-}; ZONE=${3:-}; RG=${4:-}; VM_NAME=${5:-}
        if [ -z "$VM_NAME" ]; then printf '%s\n' "Usage: dns unmap-node <domain> <zone> <rg> <vm-name>"; exit 1; fi
        IP=$(az vm show -d -g "$RG" -n "$VM_NAME" --query publicIps -o tsv | xargs)
        RECORD_NAME=${DOMAIN%."$ZONE"}
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
          printf '%s\n' 'Usage: firewall create <name> <resource-group> [ports...]'
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
        _max_prio=$(az network nsg rule list -g "$RESOURCE_GROUP" --nsg-name "$RESOURCE_NAME" --query "max([].priority)" -o tsv 2>/dev/null | tr -d "[:space:]" || true)
        case "$_max_prio" in
          [0-9]*)
            if [ "$_max_prio" -ge 1000 ] && [ "$_max_prio" -lt 4000 ]; then
              PRIORITY=$((_max_prio + 10))
            fi
            ;;
        esac
        SEEN_PORTS=""
        while [ $# -gt 0 ]; do
          case "$1" in
            --location) shift 2; continue ;;
            --*) shift; continue ;;
          esac
          for PORT in $1; do
            case "$PORT" in
              --*) continue ;;
              *[!0-9-]*) continue ;;
            esac
            case " $SEEN_PORTS " in
              *" $PORT "*) continue ;;
            esac
            SEEN_PORTS="$SEEN_PORTS $PORT"
            if az network nsg rule show -g "$RESOURCE_GROUP" --nsg-name "$RESOURCE_NAME" -n "Allow_$PORT" >/dev/null 2>&1; then
              printf '%s\n' "[REUSE] Firewall rule Allow_$PORT (port $PORT) already exists on $RESOURCE_NAME"
            else
              printf '%s\n' "[CREATE] Opening port $PORT on $RESOURCE_NAME (priority $PRIORITY)"
              az network nsg rule create --resource-group "$RESOURCE_GROUP" --nsg-name "$RESOURCE_NAME" --name "Allow_$PORT" --priority "$PRIORITY" --destination-port-ranges "$PORT" --access Allow --protocol Tcp || true
              PRIORITY=$((PRIORITY + 10))
            fi
          done
          shift
        done
        ;;
      delete)
        if [ -z "$RESOURCE_NAME" ] || [ -z "$RESOURCE_GROUP" ]; then
          printf '%s\n' 'Usage: firewall delete <name> <resource-group>'
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
          printf '%s\n' 'Usage: firewall update <name> <resource-group> [--add-port PORT] [--remove-port PORT]'
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
          printf '%s\n' 'Usage: network create <name> <resource-group>'
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
          printf '%s\n' 'Usage: network delete <name> <resource-group>'
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
          printf '%s\n' 'Usage: network update <name> <resource-group> [--tags T]'
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
          printf '%s\n' 'Usage: location select <location>'
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
    libscript_handle_generic_action "azure" "$ACTION" "$VERSION" "${AZURE_INSTALL_METHOD}"
    ;;
  ls-remote)
    if [ -n "${AZURE_RELEASES_URL:-}" ]; then
      libscript_fetch_stdout "${AZURE_RELEASES_URL}" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    else
    git ls-remote --tags "https://github.com/MicrosoftDocs/azure-docs" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | libscript_sort_versions | uniq || printf '%s\n' "No versions found"
    fi
    exit 0
    ;;
  use)
    libscript_handle_generic_action "azure" "$ACTION" "$VERSION" "${AZURE_INSTALL_METHOD}"
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
  install)
    if [ "$AZURE_INSTALL_METHOD" = "system" ]; then
      libscript_depends 'azure'
    else
      # libscript_native implementation
      resolve_exact_version
      TARGET_DIR="${LIBSCRIPT_HOME:-$HOME/.libscript}/azure/${EXACT_VERSION}"
      if [ ! -d "${TARGET_DIR}" ]; then
        log_info "Installing azure ${VERSION} natively to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}/bin"
        if ls "${DOWNLOAD_DIR:-/tmp/libscript_downloads}/azure/"*"${VERSION}"* >/dev/null 2>&1; then
          log_info 'Extracting from cache...'
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
  start|stop|restart|status|health|logs|up|down|install-service|uninstall-service|uninstall)
    libscript_handle_generic_action "azure" "$ACTION" "$VERSION" "${AZURE_INSTALL_METHOD}" "" "" "" "$@"
    ;;
esac
