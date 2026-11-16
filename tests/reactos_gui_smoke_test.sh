#!/bin/sh
# ## Overview
# Graphical desktop smoketest for ReactOS distributions verifying Win32k GDI display settings,
# Explorer classic shell, Lautus .msstyles theme staging, autologin registry, and RAPPS default apps.
#
# ## Usage
# ./tests/reactos_gui_smoke_test.sh [sysroot_path]

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

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM HUP
export LIBSCRIPT_HOME="${TMP_DIR}/home"
export LIBSCRIPT_OFFLINE=1
export LIBSCRIPT_ALLOW_STUB=1

TARGET="${1:-${TMP_DIR}/gui-sysroot}"
if [ ! -d "${TARGET}/iso_root" ]; then
  STACK='' "${LIBSCRIPT_ROOT_DIR}/_lib/reactos/distro/assemble.sh" \
    "${LIBSCRIPT_ROOT_DIR}/profiles/reactos/desktop-classic-i686.json" "$TARGET" >/dev/null
fi

grep -q 'protocol=win32-gdi' "${TARGET}/iso_root/libscript/display.conf"
grep -q 'driver=vbemp' "${TARGET}/iso_root/libscript/display.conf"
grep -q 'resolution=1024x768x32' "${TARGET}/iso_root/libscript/display.conf"
grep -q 'executable=explorer.exe' "${TARGET}/iso_root/libscript/desktop.conf"
[ -f "${TARGET}/iso_root/ReactOS/Resources/Themes/lautus/lautus.msstyles" ]
grep -q '"AutoAdminLogon"="1"' "${TARGET}/iso_root/libscript/hivesft_delta.reg"

for _app in 7zip sumatrapdf notepadpp vlc; do
  [ -f "${TARGET}/iso_root/libscript/cache/rapps/${_app}.i686.stamp" ]
  grep -q "$_app" "${TARGET}/iso_root/libscript/firstboot.cmd"
done

printf '[OK]       ReactOS GUI & RAPPS default apps smoketest PASSED.\n'
