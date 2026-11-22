#!/bin/sh
# ## Overview
# Configures the ReactOS Winlogon user shell (explorer-classic vs cmd-minimal vs custom)
# and stages visual style (.msstyles) theme metadata (classic, lautus, lunar, mizu).
#
# ## Usage
# ./synthesis/distro/reactos/desktop.sh [sysroot_path] [shell] [theme] [custom_shell_path]

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
SHELL_MODE="${2:-explorer-classic}"
THEME_NAME="${3:-classic}"
CUSTOM_SHELL="${4:-}"

STAMP_DIR="${SYSROOT}/.libscript-stamps"
STAMP_FILE="${STAMP_DIR}/desktop.stamp"
LS_STAGE="${SYSROOT}/iso_root/libscript"
THEMES_DIR="${SYSROOT}/iso_root/ReactOS/Resources/Themes/${THEME_NAME}"

if [ -f "$STAMP_FILE" ]; then
  printf '[SKIP]     ReactOS desktop shell (%s) already configured in %s\n' "$SHELL_MODE" "$SYSROOT"
  exit 0
fi

mkdir -p "$STAMP_DIR" "$LS_STAGE" "$THEMES_DIR"

_shell_bin='explorer.exe'
case "$SHELL_MODE" in
  cmd-minimal) _shell_bin='cmd.exe' ;;
  custom) _shell_bin="${CUSTOM_SHELL:-explorer.exe}" ;;
  *) _shell_bin='explorer.exe' ;;
esac

printf 'shell=%s\nexecutable=%s\ntheme=%s\n' "$SHELL_MODE" "$_shell_bin" "$THEME_NAME" > "${LS_STAGE}/desktop.conf"
if [ "$THEME_NAME" != 'classic' ]; then
  printf 'MSSTYLES-REACTOS-%s\n' "$THEME_NAME" > "${THEMES_DIR}/${THEME_NAME}.msstyles"
fi

cat <<DESK_EOF >> "${LS_STAGE}/hivesft_delta.reg"

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon]
"Shell"="${_shell_bin}"

[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\ThemeManager]
"DllName"="%SystemRoot%\\\\Resources\\\\Themes\\\\${THEME_NAME}\\\\${THEME_NAME}.msstyles"
DESK_EOF

awk '{ sub(/\r$/, ""); printf "%s\r\n", $0 }' "${LS_STAGE}/hivesft_delta.reg" > "${LS_STAGE}/hivesft_delta.reg.tmp"
mv "${LS_STAGE}/hivesft_delta.reg.tmp" "${LS_STAGE}/hivesft_delta.reg"

date -u +"%Y-%m-%dT%H:%M:%SZ" > "${STAMP_FILE}.tmp"
mv "${STAMP_FILE}.tmp" "$STAMP_FILE"
printf '[OK]       ReactOS desktop shell (%s -> %s, theme=%s) configured.\n' "$SHELL_MODE" "$_shell_bin" "$THEME_NAME"
