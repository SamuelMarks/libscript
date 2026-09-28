#!/bin/sh
# ## Overview
# Unified CLI entrypoint to package an illumos distribution profile into
# raw, qcow2, vagrant box, vhd, vmdk, or iso target formats.
#
# ## Usage
# Package illumos distribution:
#   cli/commands/package_as/illumos_distro.sh --format <qcow2|box|raw|vhd|vmdk|iso> --profile <profile_json> [--output <path>]

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
REPO_ROOT="${LIBSCRIPT_ROOT_DIR}"

FORMAT="qcow2"
PROFILE="${REPO_ROOT}/profiles/illumos/minimal-server.json"
OUTPUT=""

while [ $# -gt 0 ]; do
  case "$1" in
    --format|-f)
      FORMAT="$2"
      shift 2
      ;;
    --profile|-p)
      PROFILE="$2"
      shift 2
      ;;
    --output|-o)
      OUTPUT="$2"
      shift 2
      ;;
    --help|-h)
      printf 'Usage: %s --format <qcow2|box|raw|vhd|vmdk|iso> --profile <path> [--output <path>]
' "$0"
      exit 0
      ;;
    *)
      printf '[ERROR] Unknown argument: %s
' "$1" >&2
      exit 1
      ;;
  esac
done

SYSROOT="${REPO_ROOT}/build/illumos-sysroot"

# Step 1: Assemble sysroot from profile
printf '[DISTRO]   Synthesizing illumos sysroot from %s...
' "${PROFILE}"
"${REPO_ROOT}/_lib/illumos/distro/assemble.sh" "${PROFILE}" "${SYSROOT}"

# Step 2: Dispatch to requested format exporter
case "${FORMAT}" in
  raw)
    : "${OUTPUT:=${REPO_ROOT}/build/illumos.raw}"
    "${SCRIPT_DIR}/illumos_raw.sh" "${SYSROOT}" "${OUTPUT}" 20
    ;;
  qcow2)
    : "${OUTPUT:=${REPO_ROOT}/build/illumos.qcow2}"
    "${SCRIPT_DIR}/illumos_qcow2.sh" "${SYSROOT}" "${OUTPUT}" 20
    ;;
  box)
    : "${OUTPUT:=${REPO_ROOT}/build/illumos.box}"
    QCOW_TMP="${REPO_ROOT}/build/illumos.qcow2"
    "${SCRIPT_DIR}/illumos_qcow2.sh" "${SYSROOT}" "${QCOW_TMP}" 20
    "${SCRIPT_DIR}/illumos_vagrant_box.sh" "${QCOW_TMP}" "${OUTPUT}" "qemu"
    ;;
  vhd)
    : "${OUTPUT:=${REPO_ROOT}/build/illumos.vhd}"
    "${SCRIPT_DIR}/illumos_vhd.sh" "${SYSROOT}" "${OUTPUT}" 20
    ;;
  vmdk)
    : "${OUTPUT:=${REPO_ROOT}/build/illumos.vmdk}"
    "${SCRIPT_DIR}/illumos_vmdk.sh" "${SYSROOT}" "${OUTPUT}" 20
    ;;
  iso)
    : "${OUTPUT:=${REPO_ROOT}/build/illumos.iso}"
    "${SCRIPT_DIR}/illumos_iso.sh" "${SYSROOT}" "${OUTPUT}"
    ;;
  *)
    printf '[ERROR] Unsupported packaging format: %s
' "${FORMAT}" >&2
    printf 'Supported formats: qcow2, box, raw, vhd, vmdk, iso
' >&2
    exit 1
    ;;
esac

printf '[OK]       Packaging complete: %s
' "${OUTPUT}"
