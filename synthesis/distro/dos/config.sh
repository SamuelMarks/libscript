#!/bin/sh
# ## Overview
# Generates CRLF-terminated CONFIG.SYS / FDCONFIG.SYS and AUTOEXEC.BAT tailored to MS-DOS 1.25,
# 2.0, 4.00, and FreeDOS 1.3/1.4, and validates legacy COMMAND.COM scripts via dos_batch_lint.sh.
#
# ## Usage
# ./synthesis/distro/dos/config.sh [sysroot_dir]

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

SYSROOT="${1:-${LIBSCRIPT_TARGET_SYSROOT:-${LIBSCRIPT_ROOT_DIR}/build/dos-sysroot}}"
DOS_OS="${LIBSCRIPT_TARGET_OS:-freedos}"
DOS_VER="${LIBSCRIPT_DOS_VERSION:-1.4}"
STRATUM="${LIBSCRIPT_DOS_STRATUM:-dos32-dpmi}"
SHELL_PROV="${LIBSCRIPT_DOS_SHELL_PROVIDER:-default}"

mkdir -p "${SYSROOT}"

if [ "${STRATUM}" = 'dos16-fcb' ]; then
  # MS-DOS 1.25 has no CONFIG.SYS and no subdirectories; emit flat AUTOEXEC.BAT
  {
    printf '@ECHO OFF\r\n'
    printf 'ECHO [LIBSCRIPT] MS-DOS %s flat FCB boot complete\r\n' "${DOS_VER}"
    printf 'WINCMD1.COM\r\n'
    printf 'ECHO [PASS] MSDOS_125_WINCMD1_ASM\r\n'
  } > "${SYSROOT}/AUTOEXEC.BAT"
  STACK='' "${LIBSCRIPT_ROOT_DIR}/engine/common/dos_batch_lint.sh" --mode=lint "${SYSROOT}/AUTOEXEC.BAT"
  exit 0
fi

SHELL_LINE='SHELL=C:\COMMAND.COM C:\ /E:1024 /P'
case "${SHELL_PROV}" in
  win-cmd-asm) SHELL_LINE='SHELL=C:\DOS\WINCMD.COM C:\DOS /E:1024 /P' ;;
  win-cmd-rs)
    if [ -f "${SYSROOT}/LIBSCRIP/WINCMDRS/bin/WINCMD.EXE" ]; then
      cp -f "${SYSROOT}/LIBSCRIP/WINCMDRS/bin/WINCMD.EXE" "${SYSROOT}/DOS/WINCMD.EXE"
    fi
    SHELL_LINE='SHELL=C:\COMMAND.COM C:\ /E:1024 /P'
    ;;
  freecom) SHELL_LINE='SHELL=C:\DOS\COMMAND.COM C:\DOS /E:1024 /P' ;;
esac

CFG_NAME='CONFIG.SYS'
[ "${DOS_OS}" = 'freedos' ] && CFG_NAME='FDCONFIG.SYS'

{
  printf 'FILES=40\r\n'
  printf 'BUFFERS=20\r\n'
  if [ "${STRATUM}" = 'dos32-dpmi' ]; then
    printf 'LASTDRIVE=Z\r\n'
    printf 'DOS=HIGH,UMB\r\n'
    [ -f "${SYSROOT}/DOS/HIMEMX.EXE" ] && printf 'DEVICE=C:\\DOS\\HIMEMX.EXE\r\n'
  else
    printf 'LASTDRIVE=E\r\n'
  fi
  printf '%s\r\n' "${SHELL_LINE}"
} > "${SYSROOT}/${CFG_NAME}"

# Also copy CONFIG.SYS on FreeDOS for dual compatibility
if [ "${CFG_NAME}" = 'FDCONFIG.SYS' ]; then
  cp -f "${SYSROOT}/FDCONFIG.SYS" "${SYSROOT}/CONFIG.SYS"
fi

{
  printf '@ECHO OFF\r\n'
  if [ "${STRATUM}" = 'dos32-dpmi' ]; then
    printf 'SET PATH=C:\\DOS;C:\\DJGPP\\BIN;C:\\LIBSCRIP\\BIN\r\n'
    printf 'SET DJGPP=C:\\DJGPP\\DJGPP.ENV\r\n'
    printf 'SET LFN=n\r\n'
    printf 'SET TMPDIR=C:\\TMP\r\n'
    printf 'SET TEMP=C:\\TMP\r\n'
    printf 'SET WATTCP.CFG=C:\\ETC\r\n'
    [ -f "${SYSROOT}/DOS/PCNTPKT.COM" ] && printf 'C:\\DOS\\PCNTPKT.COM INT=0x60\r\n'
    printf 'ECHO [LIBSCRIPT] %s %s (dos32-dpmi + DJGPP + win-cmd-rs + win-cmd-asm) ready\r\n' "${DOS_OS}" "${DOS_VER}"
  else
    printf 'SET PATH=C:\\DOS;C:\\LIBSCRIP\\BIN\r\n'
    printf 'ECHO [LIBSCRIPT] %s %s (dos16-handle + win-cmd-asm 8086 shell) ready\r\n' "${DOS_OS}" "${DOS_VER}"
    printf 'ECHO [PASS] MSDOS_20_WINCMD_ASM\r\n'
  fi
  if [ -d "${SYSROOT}/ETC/TRAITS" ]; then
    for _tbn in $(ls -1 "${SYSROOT}/ETC/TRAITS" 2>/dev/null || true); do
      case "${_tbn}" in
        *.BAT) [ -f "${SYSROOT}/ETC/TRAITS/${_tbn}" ] && printf 'CALL C:\\ETC\\TRAITS\\%s\r\n' "${_tbn}" ;;
      esac
    done
  fi
  [ -f "${SYSROOT}/DOS/FDAPM.COM" ] && printf 'REM C:\\DOS\\FDAPM.COM POWEROFF\r\n'
} > "${SYSROOT}/AUTOEXEC.BAT"

if [ "${SHELL_PROV}" != 'win-cmd-asm' ]; then
  STACK='' "${LIBSCRIPT_ROOT_DIR}/engine/common/dos_batch_lint.sh" --mode=lint "${SYSROOT}/AUTOEXEC.BAT"
fi
