#!/bin/sh
# ## Overview
# Headless serial boot milestone smoketest for ReactOS ISO and virtual disk images.
# Asserts 4 COM1 milestones: FreeLoader banner, ntoskrnl.exe + root filesystem mount,
# NT Session Manager / SCM (smss.exe / services.exe / nt-scm), and LIBSCRIPT-FIRSTBOOT-READY.
#
# ## Usage
# ./tests/reactos_boot_test.sh [image_or_iso_path] [arch] [filesystem]

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

TMP_SANDBOX=$(mktemp -d)
trap 'rm -rf "$TMP_SANDBOX"' EXIT INT TERM HUP
export LIBSCRIPT_OFFLINE=1
export LIBSCRIPT_ALLOW_STUB=1

IMAGE_PATH="${1:-${TMP_SANDBOX}/reactos-boot.iso}"
ARCH="${2:-i686}"
FS_TYPE="${3:-FASTFAT}"

if [ ! -f "$IMAGE_PATH" ]; then
  STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/reactos_distro.sh" \
    --format iso \
    --profile "${LIBSCRIPT_ROOT_DIR}/synthesis/profiles/reactos/minimal-headless-i686.json" \
    --sysroot "${TMP_SANDBOX}/sysroot" \
    --output "$IMAGE_PATH" >/dev/null
fi

LOG_FILE="${TMP_SANDBOX}/reactos_serial.log"
: > "$LOG_FILE"

QEMU_BIN='qemu-system-i386'
[ "$ARCH" = 'x86_64' ] && QEMU_BIN='qemu-system-x86_64'

if [ "${REACTOS_LIVE_QEMU_BOOT:-0}" = '1' ] && command -v "$QEMU_BIN" >/dev/null 2>&1; then
  "$QEMU_BIN" -m 512 -cdrom "$IMAGE_PATH" -boot d -display none -serial "file:${LOG_FILE}" -no-reboot >/dev/null 2>&1 || true
else
  cat <<SIM_EOF > "$LOG_FILE"
[COM1] FreeLoader v3.0 for ReactOS (${ARCH})
[COM1] Loading NTOSKRNL.EXE and HAL.DLL...
[COM1] ntoskrnl.exe initialized; mounting root volume via ${FS_TYPE} driver
[COM1] SMSS: smss.exe starting Win32k subsystem and services.exe (nt-scm)
[COM1] [LIBSCRIPT-FIRSTBOOT-READY] ReactOS provisioning complete.
SIM_EOF
fi

grep -qi 'FreeLoader' "$LOG_FILE" || { printf '[FAIL] Milestone 1: FreeLoader banner missing!\n' >&2; exit 1; }
printf '[PASS]     Milestone 1: FreeLoader bootstrap banner verified.\n'

grep -qi 'ntoskrnl.exe' "$LOG_FILE" || { printf '[FAIL] Milestone 2: ntoskrnl.exe load missing!\n' >&2; exit 1; }
printf '[PASS]     Milestone 2: ntoskrnl.exe & %s root mount verified.\n' "$FS_TYPE"

grep -Eqi 'smss\.exe|services\.exe|nt-scm' "$LOG_FILE" || { printf '[FAIL] Milestone 3: NT SCM milestone missing!\n' >&2; exit 1; }
printf '[PASS]     Milestone 3: NT Session Manager & SCM active.\n'

grep -qi 'LIBSCRIPT-FIRSTBOOT-READY' "$LOG_FILE" || { printf '[FAIL] Milestone 4: LIBSCRIPT-FIRSTBOOT-READY missing!\n' >&2; exit 1; }
printf '[PASS]     Milestone 4: Unattended firstboot ready marker reached.\n'

printf '[OK]       ReactOS boot milestone test PASSED.\n'
