#!/bin/sh
# ## Overview
# Generates reactos/unattend.inf ([Unattend] + [GuiRunOnce]) inside the ReactOS ISO root
# for zero-prompt Stage-1 (usetup) and Stage-2 (syssetup) unattended OS installation.
#
# ## Usage
# ./synthesis/distro/reactos/unattend.sh [sysroot_path] [computer_name] [admin_password] [locale_id] [tz_index] [fs_type]

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

SYSROOT="${1:-${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/reactos-sysroot}}"
COMP_NAME="${2:-REACTOS-NODE}"
ADMIN_PASS="${3:-}"
LOCALE_ID="${4:-00000409}"
TZ_INDEX="${5:-85}"
FS_TYPE="${6:-fat32}"
EXTRA_RUN_ONCE="${7:-}"

STAMP_DIR="${SYSROOT}/.libscript-stamps"
STAMP_FILE="${STAMP_DIR}/unattend.stamp"
ISO_ROOT="${SYSROOT}/iso_root"

mkdir -p "$STAMP_DIR" "${ISO_ROOT}/reactos"

if [ -f "$STAMP_FILE" ] && [ -f "${ISO_ROOT}/reactos/unattend.inf" ]; then
  printf '[SKIP]     ReactOS unattend.inf already generated in %s\n' "$SYSROOT"
  exit 0
fi

FS_FORMAT_CODE='1'
case "$FS_TYPE" in
  btrfs) FS_FORMAT_CODE='2' ;;
  ntfs) FS_FORMAT_CODE='3' ;;
  *) FS_FORMAT_CODE='1' ;;
esac

cat <<UNATTEND_EOF > "${ISO_ROOT}/reactos/unattend.inf"
[Version]
Signature = "\$ReactOS\$"

[Unattend]
Signature = "\$ReactOS\$"
UnattendSetupEnabled = yes
DestinationDiskNumber = 0
DestinationPartitionNumber = 1
InstallationDirectory = ReactOS
MBRInstallType = 2
FullName = "LibScript User"
OrgName = "LibScript"
ComputerName = ${COMP_NAME}
AdminPassword = ${ADMIN_PASS}
TimeZoneIndex = ${TZ_INDEX}
DisableAutoDaylightTimeSet = 1
ConfirmHardware = no
FormatPartition = 1
AutoPartition = 1
FileSystem = ${FS_FORMAT_CODE}
LocaleID = ${LOCALE_ID}
DisableGeckoInst = yes

[GuiRunOnce]
%SystemDrive%\libscript\firstboot.cmd
UNATTEND_EOF

if [ -n "$EXTRA_RUN_ONCE" ]; then
  _oifs="$IFS"
  IFS=';'
  for _cmd_line in $EXTRA_RUN_ONCE; do
    [ -n "$_cmd_line" ] && printf '%s\n' "$_cmd_line" >> "${ISO_ROOT}/reactos/unattend.inf"
  done
  IFS="$_oifs"
fi

awk '{ sub(/\r$/, ""); printf "%s\r\n", $0 }' "${ISO_ROOT}/reactos/unattend.inf" > "${ISO_ROOT}/reactos/unattend.inf.tmp"
mv "${ISO_ROOT}/reactos/unattend.inf.tmp" "${ISO_ROOT}/reactos/unattend.inf"

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
printf '[OK]       Generated reactos/unattend.inf (ComputerName=%s, FileSystem=%s).\n' "$COMP_NAME" "$FS_TYPE"
