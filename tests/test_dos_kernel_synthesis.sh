#!/bin/sh
# ## Overview
# End-to-end Plane B verification suite for DOS base kernel synthesis across FreeDOS 1.4
# and MIT MS-DOS 1.25/2.0/4.00 (Tier-1 host lint/wincmd/kvikdos/2x-reproducibility + Tier-2 QEMU).
# ## Usage
# ./tests/test_dos_kernel_synthesis.sh
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

WORK="${TMPDIR:-/tmp}/dos_synth_e2e_$$"
mkdir -p "${WORK}"
trap 'rm -rf "${WORK}"' EXIT INT TERM

# 1. Verify dos_batch_lint.sh CMD5004 (& splitting) and CMD5006 (GOTO :EOF -> GOTO EOF)
printf '@ECHO OFF\r\nECHO A & ECHO B\r\nGOTO :EOF\r\n' > "${WORK}/nt_only.bat"
set +e
STACK='' "${LIBSCRIPT_ROOT_DIR}/engine/common/dos_batch_lint.sh" --mode=lint "${WORK}/nt_only.bat" >/dev/null 2>&1
_lint_rc=$?
set -e
[ "${_lint_rc}" -ne 0 ]
STACK='' "${LIBSCRIPT_ROOT_DIR}/engine/common/dos_batch_lint.sh" --mode=rewrite "${WORK}/nt_only.bat"
STACK='' "${LIBSCRIPT_ROOT_DIR}/engine/common/dos_batch_lint.sh" --mode=lint "${WORK}/nt_only.bat"
grep -q 'GOTO EOF' "${WORK}/nt_only.bat"
grep -q '^:EOF' "${WORK}/nt_only.bat"

# 2. Verify Plane A DOS offline trait convergence + --strict exit-86 daemon rejection
mkdir -p "${WORK}/trait_sys"
for _tr in logging maintenance backup; do
  TARGET_OS='msdos' LIBSCRIPT_DOS_STRATUM='dos32-dpmi' LIBSCRIPT_TARGET_SYSROOT="${WORK}/trait_sys" \
    STACK='' "${LIBSCRIPT_ROOT_DIR}/traits/engine.sh" apply "${_tr}" --manifest "${LIBSCRIPT_ROOT_DIR}/synthesis/profiles/dos/msdos-4.0-djgpp-i586.json" >/dev/null
done
[ -f "${WORK}/trait_sys/ETC/TRAITS/LOGGING.BAT" ]
[ -f "${WORK}/trait_sys/ETC/TRAITS/MAINTENA.BAT" ]
[ -f "${WORK}/trait_sys/ETC/TRAITS/BACKUP.BAT" ]
STACK='' "${LIBSCRIPT_ROOT_DIR}/engine/common/dos_batch_lint.sh" --mode=lint \
  "${WORK}/trait_sys/ETC/TRAITS/LOGGING.BAT" \
  "${WORK}/trait_sys/ETC/TRAITS/MAINTENA.BAT" \
  "${WORK}/trait_sys/ETC/TRAITS/BACKUP.BAT"
set +e
TARGET_OS='msdos' LIBSCRIPT_DOS_STRATUM='dos32-dpmi' LIBSCRIPT_TARGET_SYSROOT="${WORK}/trait_sys" \
  STACK='' "${LIBSCRIPT_ROOT_DIR}/traits/engine.sh" apply firewall --strict >/dev/null 2>&1
_strict_rc=$?
set -e
[ "${_strict_rc}" -eq 86 ]

# 3. Synthesize all 4 DOS base kernels + verify 2x bit-for-bit reproducibility (SOURCE_DATE_EPOCH)
export SOURCE_DATE_EPOCH='1700000000'

LIBSCRIPT_TARGET_OS='freedos' LIBSCRIPT_DOS_VERSION='1.4' LIBSCRIPT_DOS_STRATUM='dos32-dpmi' \
  LIBSCRIPT_DOS_SHELL_PROVIDER='win-cmd-asm' \
  STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/distro/dos/assemble.sh" "${WORK}/sys_fd14" "${WORK}/freedos14.raw"
LIBSCRIPT_TARGET_OS='freedos' LIBSCRIPT_DOS_VERSION='1.4' LIBSCRIPT_DOS_STRATUM='dos32-dpmi' \
  LIBSCRIPT_DOS_SHELL_PROVIDER='win-cmd-asm' \
  STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/distro/dos/assemble.sh" "${WORK}/sys_fd14" "${WORK}/freedos14_run2.raw"
cmp -s "${WORK}/freedos14.raw" "${WORK}/freedos14_run2.raw"

LIBSCRIPT_TARGET_OS='msdos' LIBSCRIPT_DOS_VERSION='4.0' LIBSCRIPT_DOS_STRATUM='dos32-dpmi' \
  LIBSCRIPT_DOS_SHELL_PROVIDER='win-cmd-asm' \
  STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/distro/dos/assemble.sh" "${WORK}/sys_ms40" "${WORK}/msdos40.raw"

LIBSCRIPT_TARGET_OS='msdos' LIBSCRIPT_DOS_VERSION='2.0' LIBSCRIPT_DOS_STRATUM='dos16-handle' \
  LIBSCRIPT_DOS_SHELL_PROVIDER='win-cmd-asm' \
  STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/distro/dos/assemble.sh" "${WORK}/sys_ms20" "${WORK}/msdos20.img"

LIBSCRIPT_TARGET_OS='msdos' LIBSCRIPT_DOS_VERSION='1.25' LIBSCRIPT_DOS_STRATUM='dos16-fcb' \
  LIBSCRIPT_DOS_SHELL_PROVIDER='win-cmd-asm' \
  STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/distro/dos/assemble.sh" "${WORK}/sys_ms125" "${WORK}/msdos125.img"
LIBSCRIPT_TARGET_OS='msdos' LIBSCRIPT_DOS_VERSION='1.25' LIBSCRIPT_DOS_STRATUM='dos16-fcb' \
  LIBSCRIPT_DOS_SHELL_PROVIDER='win-cmd-asm' \
  STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/distro/dos/assemble.sh" "${WORK}/sys_ms125" "${WORK}/msdos125_run2.img"
cmp -s "${WORK}/msdos125.img" "${WORK}/msdos125_run2.img"

# 3b. Tier-1 Host Execution: canonical LibScript .cmd via wincmd + 16-bit .COM via kvikdos/vm8086
STACK='' "${LIBSCRIPT_ROOT_DIR}/engine/common/dos_batch_lint.sh" --mode=lint \
  "${WORK}/sys_fd14/AUTOEXEC.BAT" \
  "${WORK}/sys_ms40/AUTOEXEC.BAT" \
  "${WORK}/sys_ms20/AUTOEXEC.BAT" \
  "${WORK}/sys_ms125/AUTOEXEC.BAT"

printf 'ROOT\n' > "${WORK}/sys_ms40/ROOT"
mkdir -p "${WORK}/sys_ms40/LIBSCRIP/BIN"
cat << 'EOF_CANON_CMD' > "${WORK}/sys_ms40/LIBSCRIP/BIN/HELLO.CMD"
@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 exit /b 0
)
set "STACK=%STACK%:!THIS_FILE!:"
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
set "d=!SCRIPT_DIR!"
call :find_root
echo [DOSFATVFS] ROOT=!LIBSCRIPT_ROOT_DIR!
exit /b 0
:find_root
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" exit /b 1
goto :find_root
EOF_CANON_CMD

_wincmd_host=$(LIBSCRIPT_HOME="${WORK}/h_dos32" STACK='' "${LIBSCRIPT_ROOT_DIR}/engine/common/dos32/build_dos32.sh" ls-wincmd)
"${_wincmd_host}" "${WORK}/sys_ms20/AUTOEXEC.BAT" | grep -q 'MSDOS_20_WINCMD_ASM'
"${_wincmd_host}" "${WORK}/sys_fd14/AUTOEXEC.BAT" | grep -q 'freedos 1.4'

_rs_wincmd="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/win-cmd-rs/default/bin/wincmd"
if command -v wincmd >/dev/null 2>&1; then _rs_wincmd=$(command -v wincmd); fi
if [ -x "${_rs_wincmd}" ]; then
  "${_rs_wincmd}" --hermetic --dialect dos622 --host-root "${WORK}/sys_ms40" /C 'C:\AUTOEXEC.BAT' < /dev/null 2>/dev/null | grep -q 'msdos 4.0'
  "${_rs_wincmd}" --hermetic --host-root "${WORK}/sys_ms40" /C 'C:\LIBSCRIP\BIN\HELLO.CMD' < /dev/null | grep -q '\[DOSFATVFS\] ROOT=C:'
fi

LIBSCRIPT_HOME="${WORK}/h_kvikdos" ACTION='install' STACK='' "${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/kvikdos/setup.sh" >/dev/null
"${WORK}/h_kvikdos/kvikdos/default/bin/kvikdos" --dos-ver=1.25 "${WORK}/sys_ms125/WINCMD1.COM" < /dev/null | LC_ALL=C tr -d '\r' | grep -q 'WINCMD1'
"${WORK}/h_kvikdos/kvikdos/default/bin/kvikdos" --dos-ver=2.0 "${WORK}/sys_ms20/DOS/WINCMD.COM" < /dev/null | LC_ALL=C tr -d '\r' | grep -q 'WINCMD'
printf ':C:\\LIBSCRIP\\BIN\\HELLO.CMD:\r\n' | "${WORK}/h_kvikdos/kvikdos/default/bin/kvikdos" --dos-ver=2.0 "${WORK}/sys_ms20/DOS/FINDSTR.COM" '/I' '/C:":C:\LIBSCRIP\BIN\HELLO.CMD:"' >/dev/null

# Verify multi-format exporters (qcow2, iso, vagrant-box)
STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/dos_qcow2.sh" "${WORK}/sys_fd14" "${WORK}/freedos14.qcow2"
STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/dos_iso.sh" "${WORK}/sys_ms40" "${WORK}/msdos40.iso"
STACK='' "${LIBSCRIPT_ROOT_DIR}/synthesis/formats/dos_vagrant_box.sh" "${WORK}/sys_ms20" "${WORK}/msdos20.box"
[ -s "${WORK}/freedos14.qcow2" ]
[ -s "${WORK}/msdos40.iso" ]
[ -s "${WORK}/msdos20.box" ]
tar -tzf "${WORK}/msdos20.box" | grep -q 'metadata.json'
tar -tzf "${WORK}/msdos20.box" | grep -q 'box.img'

# 4. Boot all 4 synthesized DOS kernels headlessly in QEMU when qemu-system-i386 is installed
QEMU_I386=''
if command -v qemu-system-i386 >/dev/null 2>&1; then
  QEMU_I386=$(command -v qemu-system-i386)
elif command -v qemu-system-x86_64 >/dev/null 2>&1; then
  QEMU_I386=$(command -v qemu-system-x86_64)
fi

# ## boot_qemu_dos_and_assert
# Boots a synthesized DOS disk or floppy in QEMU with COM1 capture and isa-debug-exit and checks markers.
boot_qemu_dos_and_assert() {
  _bq_mode="$1"
  _bq_img="$2"
  _bq_fmt="$3"
  _bq_pat1="$4"
  _bq_pat2="$5"
  _bq_log="${WORK}/com1_$(basename -- "${_bq_img}").log"
  if [ "${_bq_mode}" = 'floppy' ]; then
    "${QEMU_I386}" -M pc -m 16M -display none -no-reboot \
      -device isa-debug-exit,iobase=0xf4,iosize=0x04 \
      -boot a -drive "file=${_bq_img},format=${_bq_fmt},if=floppy" \
      -serial "file:${_bq_log}" >/dev/null 2>&1 &
  else
    "${QEMU_I386}" -M pc -m 32M -display none -no-reboot \
      -device isa-debug-exit,iobase=0xf4,iosize=0x04 \
      -boot c -drive "file=${_bq_img},format=${_bq_fmt},index=0,media=disk" \
      -serial "file:${_bq_log}" >/dev/null 2>&1 &
  fi
  _q_pid=$!
  _q_wait=0
  while kill -0 "${_q_pid}" 2>/dev/null; do
    if [ "${_q_wait}" -ge 15 ]; then
      kill "${_q_pid}" 2>/dev/null || true
      break
    fi
    sleep 1
    _q_wait=$((_q_wait + 1))
  done
  wait "${_q_pid}" 2>/dev/null || true
  grep -q "${_bq_pat1}" "${_bq_log}" || {
    printf '[FAIL] Missing "%s" in %s:\n' "${_bq_pat1}" "${_bq_log}" >&2
    cat "${_bq_log}" >&2 || true
    exit 1
  }
  grep -q "${_bq_pat2}" "${_bq_log}" || {
    printf '[FAIL] Missing "%s" in %s:\n' "${_bq_pat2}" "${_bq_log}" >&2
    cat "${_bq_log}" >&2 || true
    exit 1
  }
}

if [ -n "${QEMU_I386}" ]; then
  boot_qemu_dos_and_assert 'hdd' "${WORK}/freedos14.qcow2" 'qcow2' 'FreeDOS Kernel 1.4' 'FREEDOS_KERNEL_READY'
  boot_qemu_dos_and_assert 'hdd' "${WORK}/msdos40.raw" 'raw' 'MS-DOS(R) Version 4.0' 'MSDOS_4.0_KERNEL_READY'
  boot_qemu_dos_and_assert 'floppy' "${WORK}/msdos20.img" 'raw' 'MSDOS_20_WINCMD_ASM' 'MSDOS_2.0_KERNEL_READY'
  boot_qemu_dos_and_assert 'floppy' "${WORK}/msdos125.img" 'raw' 'MSDOS_125_WINCMD1_ASM' 'MSDOS_1.25_KERNEL_READY'
  printf '[INFO] Headless QEMU COM1 boot verified across FreeDOS 1.4, MS-DOS 4.0, MS-DOS 2.0, and MS-DOS 1.25!\n'
fi

printf '[PASS] End-to-end DOS base-kernel synthesis and QEMU boot verification passed.\n'
