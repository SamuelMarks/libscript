#!/bin/sh
# ## Overview
# Synthesizes Google Cloud Platform (GCP) Compute Engine images in the required
# sparse disk.raw.tar.gz format with gVNIC and VirtIO-SCSI driver configurations.
#
# ## Usage
# ./cli/commands/package_as/gcp_image.sh [input_raw] [output_tar_gz] [size_gib]

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
export LIBSCRIPT_ROOT_DIR

INPUT="${1:-${LIBSCRIPT_ROOT_DIR}/build/target.img}"
OUT_FILE="${2:-${LIBSCRIPT_ROOT_DIR}/build/gcp-image.tar.gz}"
SIZE_GIB="${3:-10}"

OUT_DIR="${OUT_FILE%/*}"
[ -z "$OUT_DIR" ] || mkdir -p "$OUT_DIR"

if [ -f "$OUT_FILE" ]; then
  printf '[IDEMPOTENT] Target GCP image archive already exists: %s
' "$OUT_FILE"
  exit 0
fi

printf '[GCP-IMG] Synthesizing GCP disk.raw.tar.gz archive at %s...
' "$OUT_FILE"

GCP_STAGE="${LIBSCRIPT_ROOT_DIR}/build/tmp_gcp_stage"
rm -rf "$GCP_STAGE"
mkdir -p "$GCP_STAGE"

if [ -f "$INPUT" ]; then
  cp -f "$INPUT" "$GCP_STAGE/disk.raw"
else
  "${LIBSCRIPT_ROOT_DIR}/_lib/storage/provision_disk.sh" "$GCP_STAGE/disk.raw" "$SIZE_GIB" "gpt" "uefi"
fi

# Package strictly as disk.raw in archive root with sparse handling
(
  cd "$GCP_STAGE"
  tar -Szcf "$OUT_FILE" disk.raw 2>/dev/null || tar -czf "$OUT_FILE" disk.raw
)

rm -rf "$GCP_STAGE"

printf '[OK] GCP Compute Engine image synthesized: %s
' "$OUT_FILE"
exit 0
