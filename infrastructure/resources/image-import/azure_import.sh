#!/bin/sh
# ## Overview
# Aligns or validates a distro VHD PageBlob, uploads to Azure Blob Storage, and registers an Azure Managed Image.
# ## Usage
# ./infrastructure/resources/image-import/azure_import.sh --disk=<artifact_or_vhd> --account=<storage_acct> [--gallery=<sig>] [--rg=<rg>] [--name=<img_def>] [--distro=<target>] [--profile=<preset>] [--version=<1.0.0>] [--out=<receipt.json>] [--dry-run]
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

DISK_PATH=''
ACCOUNT="${IMAGE_IMPORT_AZURE_ACCOUNT:-}"
GALLERY="${IMAGE_IMPORT_AZURE_GALLERY:-}"
RG="${IMAGE_IMPORT_AZURE_RG:-libscript-marketplace-rg}"
IMG_NAME=''
DISTRO_TARGET=''
PROFILE_ARG=''
ARCH_VAL=''
IMG_VER='1.0.0'
OUT_RECEIPT=''
DRY_RUN="${IMAGE_IMPORT_DRY_RUN:-0}"
ALLOW_STUB="${LIBSCRIPT_ALLOW_STUB:-0}"

# ## show_help
# Displays CLI usage instructions for azure_import.sh.
show_help() {
  printf '%s\n' 'Usage: azure_import.sh [--disk=<path> | --distro=<target> --profile=<preset>] --account=<storage_acct> [--gallery=<sig>] [--rg=<rg>] [--name=<img_def>] [--version=<1.0.0>] [--out=<receipt.json>] [--dry-run]'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h) show_help; exit 0 ;;
    --disk=*) DISK_PATH="${1#*=}"; shift ;;
    --disk) DISK_PATH="${2:-}"; shift 2 ;;
    --account=*) ACCOUNT="${1#*=}"; shift ;;
    --account) ACCOUNT="${2:-}"; shift 2 ;;
    --gallery=*) GALLERY="${1#*=}"; shift ;;
    --gallery) GALLERY="${2:-}"; shift 2 ;;
    --rg=*) RG="${1#*=}"; shift ;;
    --rg) RG="${2:-}"; shift 2 ;;
    --name=*) IMG_NAME="${1#*=}"; shift ;;
    --name) IMG_NAME="${2:-}"; shift 2 ;;
    --distro=*|--target=*) DISTRO_TARGET="${1#*=}"; shift ;;
    --distro|--target) DISTRO_TARGET="${2:-}"; shift 2 ;;
    --profile=*) PROFILE_ARG="${1#*=}"; shift ;;
    --profile) PROFILE_ARG="${2:-}"; shift 2 ;;
    --arch=*) ARCH_VAL="${1#*=}"; shift ;;
    --arch) ARCH_VAL="${2:-}"; shift 2 ;;
    --version=*) IMG_VER="${1#*=}"; shift ;;
    --version) IMG_VER="${2:-}"; shift 2 ;;
    --out=*) OUT_RECEIPT="${1#*=}"; shift ;;
    --out) OUT_RECEIPT="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN='1'; shift ;;
    --allow-stub) ALLOW_STUB='1'; shift ;;
    *) shift ;;
  esac
done

# ## synthesize_distro_if_needed
# Synthesizes a VHD artifact via package-as when --distro is given without --disk.
synthesize_distro_if_needed() {
  if [ -n "$DISK_PATH" ] || [ -z "$DISTRO_TARGET" ]; then
    return 0
  fi
  case "$DISTRO_TARGET" in
    linux-distro|freebsd-distro|illumos-distro|reactos-distro|unikernel-distro) ;;
    *)
      printf '[ERROR] Unsupported --distro target for Azure import: %s\n' "$DISTRO_TARGET" >&2
      exit 1
      ;;
  esac
  _az_fmt='vhd'
  if [ "$DISTRO_TARGET" = 'unikernel-distro' ]; then _az_fmt='azure-vhd'; fi
  _az_tmp="${LIBSCRIPT_BUILD_DIR:-${LIBSCRIPT_ROOT_DIR}/build}/image-import/azure-${DISTRO_TARGET}.vhd"
  mkdir -p "$(dirname "$_az_tmp")"
  set -- package-as "$DISTRO_TARGET" --format "$_az_fmt" --output "$_az_tmp"
  if [ -n "$PROFILE_ARG" ]; then set -- "$@" --profile "$PROFILE_ARG"; fi
  if [ "$ALLOW_STUB" = '1' ]; then set -- "$@" --allow-stub; fi
  STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" "$@"
  DISK_PATH="$_az_tmp"
}

# ## detect_azure_distro_metadata
# Infers distro_family, OS type (Linux vs Windows for ReactOS), Hyper-V generation, and default image name.
detect_azure_distro_metadata() {
  DISTRO_FAMILY='generic'
  AZ_OS_TYPE='Linux'
  HV_GEN='V2'
  AZ_ARCH='x64'
  _base=$(basename "$DISK_PATH")
  _stem="${_base%.*}"

  case "$_base" in
    linux-*|*linux*) DISTRO_FAMILY='linux' ;;
    freebsd-*|*freebsd*) DISTRO_FAMILY='freebsd' ;;
    illumos-*|*illumos*) DISTRO_FAMILY='illumos' ;;
    reactos-*|*reactos*) DISTRO_FAMILY='reactos'; AZ_OS_TYPE='Windows' ;;
    unikernel-*|*.unikernel.*|*.uefi-gpt.*) DISTRO_FAMILY='unikernel' ;;
  esac
  if [ -n "$DISTRO_TARGET" ]; then
    DISTRO_FAMILY="${DISTRO_TARGET%-distro}"
    if [ "$DISTRO_FAMILY" = 'reactos' ]; then AZ_OS_TYPE='Windows'; fi
  fi

  for _st in "${DISK_PATH}.distro.stamp" "${DISK_PATH}.stamp"; do
    if [ -f "$_st" ]; then
      _prof_line=$(grep '^profile=' "$_st" 2>/dev/null | head -n 1 || true)
      _arch_line=$(grep '^arch=' "$_st" 2>/dev/null | head -n 1 || true)
      _fw_line=$(grep '^framework=' "$_st" 2>/dev/null | head -n 1 || true)
      case "$_prof_line" in
        *freebsd*) DISTRO_FAMILY='freebsd' ;;
        *illumos*) DISTRO_FAMILY='illumos' ;;
        *reactos*) DISTRO_FAMILY='reactos'; AZ_OS_TYPE='Windows' ;;
        *unikernel*) DISTRO_FAMILY='unikernel' ;;
        *linux*|*lfs*) DISTRO_FAMILY='linux' ;;
      esac
      if [ -n "$_fw_line" ]; then DISTRO_FAMILY='unikernel'; fi
      if [ -z "$ARCH_VAL" ] && [ -n "$_arch_line" ]; then
        ARCH_VAL="${_arch_line#arch=}"
      fi
      case "$_prof_line" in
        *i686*|*i386*) HV_GEN='V1' ;;
        *aarch64*|*arm64*) if [ -z "$ARCH_VAL" ]; then ARCH_VAL='Arm64'; fi ;;
      esac
    fi
  done

  case "$_base" in
    *i686*|*i386*) HV_GEN='V1' ;;
    *aarch64*|*arm64*) if [ -z "$ARCH_VAL" ]; then ARCH_VAL='Arm64'; fi ;;
  esac

  case "${ARCH_VAL:-${IMAGE_IMPORT_ARCH:-x86_64}}" in
    arm64|aarch64|ARM64|Arm64) AZ_ARCH='Arm64' ;;
    *) AZ_ARCH='x64' ;;
  esac

  if [ -z "$IMG_NAME" ]; then
    IMG_NAME=$(printf '%s' "$_stem" | tr -cs 'A-Za-z0-9_.-' '-' | sed 's/^-//;s/-$//')
  fi
}

# ## ensure_aligned_azure_vhd
# Converts non-VHD distro artifacts or stub VHDs into 1 MiB-aligned fixed VHDs while rejecting misaligned standalone .vhd inputs.
ensure_aligned_azure_vhd() {
  case "$DISK_PATH" in
    *.vhd|*.VHD)
      _fb=$(wc -c < "$DISK_PATH" | tr -d ' ')
      _rem=$((_fb % 1048576))
      if [ "$_rem" -eq 0 ] || [ "$_rem" -eq 512 ]; then
        UPLOAD_VHD="$DISK_PATH"
        return 0
      fi
      if [ ! -f "${DISK_PATH}.distro.stamp" ] && [ ! -f "${DISK_PATH}.stamp" ] && [ ! -f "${DISK_PATH}.azure-vhd.json" ]; then
        printf '[ERROR] Azure VHD %s (%s bytes) violates 1 MiB alignment (+512-byte fixed footer).\n' "$DISK_PATH" "$_fb" >&2
        exit 1
      fi
      ;;
  esac
  UPLOAD_VHD="${DISK_PATH}.azure-aligned.vhd"
  if [ -f "$UPLOAD_VHD" ]; then
    return 0
  fi
  _raw_src="$DISK_PATH"
  case "$DISK_PATH" in
    *.qcow2)
      if [ "$DRY_RUN" != '1' ] && command -v qemu-img >/dev/null 2>&1; then
        _raw_src="${DISK_PATH}.azure-tmp.raw"
        qemu-img convert -f qcow2 -O raw "$DISK_PATH" "$_raw_src"
      fi
      ;;
  esac
  cp -f "$_raw_src" "$UPLOAD_VHD"
  _cur_sz=$(wc -c < "$UPLOAD_VHD" | tr -d ' ')
  if [ "$_cur_sz" -eq 0 ]; then
    dd if=/dev/zero bs=1048576 count=1 >> "$UPLOAD_VHD" 2>/dev/null
    _cur_sz=1048576
  fi
  _pad_rem=$((_cur_sz % 1048576))
  if [ "$_pad_rem" -ne 0 ]; then
    _pad_len=$((1048576 - _pad_rem))
    dd if=/dev/zero bs=1 count="$_pad_len" >> "$UPLOAD_VHD" 2>/dev/null
  fi
  printf 'conectix' >> "$UPLOAD_VHD"
  dd if=/dev/zero bs=1 count=504 >> "$UPLOAD_VHD" 2>/dev/null
  if [ "$_raw_src" != "$DISK_PATH" ]; then
    rm -f "$_raw_src"
  fi
}

# ## compute_sha256
# Computes a portable SHA-256 hex digest of a file.
compute_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    openssl dgst -sha256 "$1" | awk '{print $NF}'
  fi
}

synthesize_distro_if_needed

if [ -z "$DISK_PATH" ] || [ ! -f "$DISK_PATH" ]; then
  printf '[ERROR] --disk=<existing_artifact> required\n' >&2
  exit 1
fi
if [ -z "$ACCOUNT" ]; then
  printf '[ERROR] --account=<storage_account> required\n' >&2
  exit 1
fi

detect_azure_distro_metadata
if [ -z "$IMG_NAME" ]; then
  printf '[ERROR] --name=<image_name> required\n' >&2
  exit 1
fi

DIGEST=$(compute_sha256 "$DISK_PATH")
SHORT_SHA=$(printf '%s' "$DIGEST" | cut -c1-12)
if [ -z "$OUT_RECEIPT" ]; then OUT_RECEIPT="${DISK_PATH}.azure-sig-receipt.json"; fi

if [ -f "$OUT_RECEIPT" ] && jq -e --arg d "$DIGEST" '.sha256 == $d' "$OUT_RECEIPT" >/dev/null 2>&1; then
  printf '[SKIP] Azure Managed/Gallery image already registered for digest %s: %s\n' "$SHORT_SHA" "$OUT_RECEIPT"
  exit 0
fi

ensure_aligned_azure_vhd

BLOB_URI="https://${ACCOUNT}.blob.core.windows.net/vhds/${IMG_NAME}-${SHORT_SHA}.vhd"
MANAGED_IMAGE_NAME="${IMG_NAME}-${SHORT_SHA}"
MANAGED_IMAGE_ID="/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/${RG}/providers/Microsoft.Compute/images/${MANAGED_IMAGE_NAME}"
REG_MODE='managed-image'
SIG_ID=''
if [ -n "$GALLERY" ]; then
  REG_MODE='compute-gallery+managed-image'
  SIG_ID="/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/${RG}/providers/Microsoft.Compute/galleries/${GALLERY}/images/${IMG_NAME}/versions/${IMG_VER}"
fi

if [ "$DRY_RUN" != "1" ]; then
  az storage blob upload --account-name "$ACCOUNT" --container-name vhds \
    --type page --file "$UPLOAD_VHD" --name "${IMG_NAME}-${SHORT_SHA}.vhd" --overwrite false 2>/dev/null || true
  if ! az image show -g "$RG" -n "$MANAGED_IMAGE_NAME" >/dev/null 2>&1; then
    MANAGED_IMAGE_ID=$(az image create -g "$RG" -n "$MANAGED_IMAGE_NAME" \
      --os-type "$AZ_OS_TYPE" --hyper-v-generation "$HV_GEN" \
      --source "$BLOB_URI" \
      --tags "LibScriptDigest=${DIGEST}" "LibScriptDistro=${DISTRO_FAMILY}" \
      --query 'id' -o tsv)
  fi
  if [ -n "$GALLERY" ]; then
    az sig image-definition create -g "$RG" -r "$GALLERY" -i "$IMG_NAME" \
      --publisher LibScript --offer "$IMG_NAME" --sku "${HV_GEN}-uefi" \
      --os-type "$AZ_OS_TYPE" --os-state Generalized --hyper-v-generation "$HV_GEN" \
      --architecture "$AZ_ARCH" 2>/dev/null || true
    if ! az sig image-version show -g "$RG" -r "$GALLERY" -i "$IMG_NAME" -e "$IMG_VER" >/dev/null 2>&1; then
      SIG_ID=$(az sig image-version create -g "$RG" -r "$GALLERY" -i "$IMG_NAME" -e "$IMG_VER" \
        --managed-image "$MANAGED_IMAGE_ID" \
        --tags "LibScriptDigest=${DIGEST}" "LibScriptDistro=${DISTRO_FAMILY}" --query 'id' -o tsv)
    fi
  fi
fi

mkdir -p "$(dirname "$OUT_RECEIPT")"
cat > "${OUT_RECEIPT}.tmp" <<EOF
{
  "cloud": "azure",
  "registration_mode": "${REG_MODE}",
  "distro_family": "${DISTRO_FAMILY}",
  "source_artifact": "${DISK_PATH}",
  "aligned_vhd": "${UPLOAD_VHD}",
  "resource_group": "${RG}",
  "gallery": "${GALLERY}",
  "image_definition": "${IMG_NAME}",
  "version": "${IMG_VER}",
  "os_type": "${AZ_OS_TYPE}",
  "architecture": "${AZ_ARCH}",
  "managed_image_name": "${MANAGED_IMAGE_NAME}",
  "managed_image_id": "${MANAGED_IMAGE_ID}",
  "gallery_image_version_id": "${SIG_ID}",
  "hyper_v_generation": "${HV_GEN}",
  "blob_uri": "${BLOB_URI}",
  "sha256": "${DIGEST}",
  "dry_run": ${DRY_RUN}
}
EOF
mv "${OUT_RECEIPT}.tmp" "$OUT_RECEIPT"
printf '[OK] Azure Managed/Gallery image receipt written: %s (%s)\n' "$OUT_RECEIPT" "$MANAGED_IMAGE_NAME"
