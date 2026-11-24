#!/bin/sh
# ## Overview
# Packages a distro/disk artifact into `disk.raw.tar.gz`, uploads to GCS, and registers a Shielded GCE Compute Image.
# ## Usage
# ./infrastructure/resources/image-import/gcp_import.sh --disk=<artifact_or_tar_gz> --bucket=<gcs_bucket> --project=<gcp_proj> [--name=<img_name>] [--distro=<target>] [--profile=<preset>] [--arch=<X86_64|ARM64>] [--out=<receipt.json>] [--dry-run]
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
BUCKET="${IMAGE_IMPORT_GCP_BUCKET:-}"
PROJECT_ID="${IMAGE_IMPORT_GCP_PROJECT:-}"
IMG_NAME=''
DISTRO_TARGET=''
PROFILE_ARG=''
ARCH_VAL=''
OUT_RECEIPT=''
DRY_RUN="${IMAGE_IMPORT_DRY_RUN:-0}"
ALLOW_STUB="${LIBSCRIPT_ALLOW_STUB:-0}"

# ## show_help
# Displays CLI usage instructions for gcp_import.sh.
show_help() {
  printf '%s\n' 'Usage: gcp_import.sh [--disk=<path> | --distro=<target> --profile=<preset>] --bucket=<gcs_bucket> --project=<gcp_proj> [--name=<img_name>] [--arch=<X86_64|ARM64>] [--out=<receipt.json>] [--dry-run]'
}

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h) show_help; exit 0 ;;
    --disk=*) DISK_PATH="${1#*=}"; shift ;;
    --disk) DISK_PATH="${2:-}"; shift 2 ;;
    --bucket=*) BUCKET="${1#*=}"; shift ;;
    --bucket) BUCKET="${2:-}"; shift 2 ;;
    --project=*) PROJECT_ID="${1#*=}"; shift ;;
    --project) PROJECT_ID="${2:-}"; shift 2 ;;
    --name=*) IMG_NAME="${1#*=}"; shift ;;
    --name) IMG_NAME="${2:-}"; shift 2 ;;
    --distro=*|--target=*) DISTRO_TARGET="${1#*=}"; shift ;;
    --distro|--target) DISTRO_TARGET="${2:-}"; shift 2 ;;
    --profile=*) PROFILE_ARG="${1#*=}"; shift ;;
    --profile) PROFILE_ARG="${2:-}"; shift 2 ;;
    --arch=*) ARCH_VAL="${1#*=}"; shift ;;
    --arch) ARCH_VAL="${2:-}"; shift 2 ;;
    --out=*) OUT_RECEIPT="${1#*=}"; shift ;;
    --out) OUT_RECEIPT="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN='1'; shift ;;
    --allow-stub) ALLOW_STUB='1'; shift ;;
    *) shift ;;
  esac
done

# ## synthesize_distro_if_needed
# Synthesizes a raw/UEFI disk artifact via package-as when --distro is given without --disk.
synthesize_distro_if_needed() {
  if [ -n "$DISK_PATH" ] || [ -z "$DISTRO_TARGET" ]; then
    return 0
  fi
  case "$DISTRO_TARGET" in
    linux-distro|freebsd-distro|illumos-distro|reactos-distro|unikernel-distro) ;;
    *)
      printf '[ERROR] Unsupported --distro target for GCP import: %s\n' "$DISTRO_TARGET" >&2
      exit 1
      ;;
  esac
  _gcp_fmt='raw'
  if [ "$DISTRO_TARGET" = 'unikernel-distro' ]; then
    _gcp_fmt='uefi-gpt'
  fi
  _gcp_tmp="${LIBSCRIPT_BUILD_DIR:-${LIBSCRIPT_ROOT_DIR}/build}/image-import/gcp-${DISTRO_TARGET}.raw"
  mkdir -p "$(dirname "$_gcp_tmp")"
  set -- package-as "$DISTRO_TARGET" --format "$_gcp_fmt" --output "$_gcp_tmp"
  if [ -n "$PROFILE_ARG" ]; then set -- "$@" --profile "$PROFILE_ARG"; fi
  if [ "$ALLOW_STUB" = '1' ]; then set -- "$@" --allow-stub; fi
  STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" "$@"
  DISK_PATH="$_gcp_tmp"
}

# ## detect_gcp_distro_metadata
# Infers distro_family, GCE architecture, guest OS features, and clean image name from artifact and stamps.
detect_gcp_distro_metadata() {
  DISTRO_FAMILY='generic'
  UEFI_ENABLED='1'
  _base=$(basename "$DISK_PATH")
  _stem="${_base%.tar.gz}"
  _stem="${_stem%.tgz}"
  _stem="${_stem%.*}"

  case "$_base" in
    linux-*|*linux*) DISTRO_FAMILY='linux' ;;
    freebsd-*|*freebsd*) DISTRO_FAMILY='freebsd' ;;
    illumos-*|*illumos*) DISTRO_FAMILY='illumos' ;;
    reactos-*|*reactos*) DISTRO_FAMILY='reactos' ;;
    unikernel-*|*.unikernel.*|*.uefi-gpt.*) DISTRO_FAMILY='unikernel' ;;
  esac
  if [ -n "$DISTRO_TARGET" ]; then
    DISTRO_FAMILY="${DISTRO_TARGET%-distro}"
  fi

  for _st in "${DISK_PATH}.distro.stamp" "${DISK_PATH}.stamp"; do
    if [ -f "$_st" ]; then
      _prof_line=$(grep '^profile=' "$_st" 2>/dev/null | head -n 1 || true)
      _arch_line=$(grep '^arch=' "$_st" 2>/dev/null | head -n 1 || true)
      _fw_line=$(grep '^framework=' "$_st" 2>/dev/null | head -n 1 || true)
      case "$_prof_line" in
        *freebsd*) DISTRO_FAMILY='freebsd' ;;
        *illumos*) DISTRO_FAMILY='illumos' ;;
        *reactos*) DISTRO_FAMILY='reactos' ;;
        *unikernel*) DISTRO_FAMILY='unikernel' ;;
        *linux*|*lfs*) DISTRO_FAMILY='linux' ;;
      esac
      if [ -n "$_fw_line" ]; then DISTRO_FAMILY='unikernel'; fi
      if [ -z "$ARCH_VAL" ] && [ -n "$_arch_line" ]; then
        ARCH_VAL="${_arch_line#arch=}"
      fi
      case "$_prof_line" in
        *i686*|*i386*) UEFI_ENABLED='0' ;;
        *aarch64*|*arm64*) if [ -z "$ARCH_VAL" ]; then ARCH_VAL='ARM64'; fi ;;
      esac
    fi
  done

  case "$_base" in
    *i686*|*i386*) UEFI_ENABLED='0' ;;
    *aarch64*|*arm64*) if [ -z "$ARCH_VAL" ]; then ARCH_VAL='ARM64'; fi ;;
  esac

  if [ -z "$ARCH_VAL" ]; then ARCH_VAL="${IMAGE_IMPORT_ARCH:-X86_64}"; fi
  case "$ARCH_VAL" in
    arm64|aarch64|ARM64) ARCH_VAL='ARM64' ;;
    *) ARCH_VAL='X86_64' ;;
  esac

  if [ -z "$IMG_NAME" ]; then
    IMG_NAME=$(printf '%s' "$_stem" | tr '[:upper:]_.' '[:lower:]--' | tr -cs 'a-z0-9-' '-' | sed 's/^-//;s/-$//')
  fi
}

# ## ensure_gcp_tar_gz
# Wraps non-.tar.gz distro artifacts (raw, qcow2, vhd, iso, elf) into a GCE-compliant disk.raw.tar.gz bundle.
ensure_gcp_tar_gz() {
  case "$DISK_PATH" in
    *.tar.gz|*.tgz)
      PACKAGED_ARCHIVE="$DISK_PATH"
      return 0
      ;;
  esac
  PACKAGED_ARCHIVE="${DISK_PATH}.gcp-disk.raw.tar.gz"
  if [ -f "$PACKAGED_ARCHIVE" ]; then
    return 0
  fi
  _stage_dir="${DISK_PATH}.gcp_stage_$$"
  mkdir -p "$_stage_dir"
  case "$DISK_PATH" in
    *.qcow2)
      if [ "$DRY_RUN" != '1' ] && command -v qemu-img >/dev/null 2>&1; then
        qemu-img convert -f qcow2 -O raw "$DISK_PATH" "${_stage_dir}/disk.raw"
      else
        cp -f "$DISK_PATH" "${_stage_dir}/disk.raw"
      fi
      ;;
    *)
      cp -f "$DISK_PATH" "${_stage_dir}/disk.raw"
      ;;
  esac
  (
    cd "$_stage_dir"
    tar -Szcf "$PACKAGED_ARCHIVE" disk.raw 2>/dev/null || tar -czf "$PACKAGED_ARCHIVE" disk.raw
  )
  rm -rf "$_stage_dir"
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
if [ -z "$BUCKET" ]; then
  printf '[ERROR] --bucket=<gcs_bucket> required\n' >&2
  exit 1
fi
if [ -z "$PROJECT_ID" ]; then
  printf '[ERROR] --project=<gcp_project> required\n' >&2
  exit 1
fi

detect_gcp_distro_metadata
if [ -z "$IMG_NAME" ]; then
  printf '[ERROR] --name=<gce_image_name> required\n' >&2
  exit 1
fi

DIGEST=$(compute_sha256 "$DISK_PATH")
SHORT_SHA=$(printf '%s' "$DIGEST" | cut -c1-12)
CLEAN_NAME=$(printf '%s-%s' "$IMG_NAME" "$SHORT_SHA" | tr '[:upper:]_.' '[:lower:]--' | tr -cs 'a-z0-9-' '-' | sed 's/^-//;s/-$//')
GCS_URI="gs://${BUCKET}/libscript-images/${CLEAN_NAME}.disk.raw.tar.gz"
SELF_LINK="projects/${PROJECT_ID}/global/images/${CLEAN_NAME}"
if [ -z "$OUT_RECEIPT" ]; then OUT_RECEIPT="${DISK_PATH}.gcp-image-receipt.json"; fi

if [ -f "$OUT_RECEIPT" ] && jq -e --arg d "$DIGEST" '.sha256 == $d' "$OUT_RECEIPT" >/dev/null 2>&1; then
  printf '[SKIP] GCP Compute Engine image already registered for digest %s: %s\n' "$SHORT_SHA" "$OUT_RECEIPT"
  exit 0
fi

ensure_gcp_tar_gz

GUEST_FEATURES_CLI='UEFI_COMPATIBLE,GVNIC,VIRTIO_SCSI_MULTIQUEUE'
GUEST_FEATURES_JSON='["UEFI_COMPATIBLE", "GVNIC", "VIRTIO_SCSI_MULTIQUEUE"]'
if [ "$UEFI_ENABLED" = '0' ]; then
  GUEST_FEATURES_CLI='GVNIC,VIRTIO_SCSI_MULTIQUEUE'
  GUEST_FEATURES_JSON='["GVNIC", "VIRTIO_SCSI_MULTIQUEUE"]'
fi

if [ "$DRY_RUN" != "1" ]; then
  if ! gcloud compute images describe "$CLEAN_NAME" --project="$PROJECT_ID" >/dev/null 2>&1; then
    gcloud storage cp "$PACKAGED_ARCHIVE" "$GCS_URI" --project="$PROJECT_ID"
    if [ "$UEFI_ENABLED" = '1' ]; then
      gcloud compute images create "$CLEAN_NAME" \
        --project="$PROJECT_ID" \
        --source-uri="$GCS_URI" \
        --architecture="$ARCH_VAL" \
        --guest-os-features="$GUEST_FEATURES_CLI" \
        --shielded-integrity-monitoring \
        --labels="libscript-digest=${SHORT_SHA},libscript-distro=${DISTRO_FAMILY}"
    else
      gcloud compute images create "$CLEAN_NAME" \
        --project="$PROJECT_ID" \
        --source-uri="$GCS_URI" \
        --architecture="$ARCH_VAL" \
        --guest-os-features="$GUEST_FEATURES_CLI" \
        --labels="libscript-digest=${SHORT_SHA},libscript-distro=${DISTRO_FAMILY}"
    fi
  fi
fi

mkdir -p "$(dirname "$OUT_RECEIPT")"
cat > "${OUT_RECEIPT}.tmp" <<EOF
{
  "cloud": "gcp",
  "distro_family": "${DISTRO_FAMILY}",
  "source_artifact": "${DISK_PATH}",
  "packaged_archive": "${PACKAGED_ARCHIVE}",
  "project_id": "${PROJECT_ID}",
  "image_name": "${CLEAN_NAME}",
  "self_link": "${SELF_LINK}",
  "architecture": "${ARCH_VAL}",
  "guest_os_features": ${GUEST_FEATURES_JSON},
  "gcs_uri": "${GCS_URI}",
  "sha256": "${DIGEST}",
  "dry_run": ${DRY_RUN}
}
EOF
mv "${OUT_RECEIPT}.tmp" "$OUT_RECEIPT"
printf '[OK] GCP Compute Engine image receipt written: %s (%s)\n' "$OUT_RECEIPT" "$CLEAN_NAME"
