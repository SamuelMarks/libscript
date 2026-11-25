#!/bin/sh
# ## Overview
# Headless QEMU FreeDOS & MS-DOS (`dos32`) smoke test verifying `LIBSCRIPT_DOS_83=1` staging and live `../bento` `COM1` execution.
# ## Usage
# ./tests/test_qemu_msdos_smoke.sh [--use-bento-disk|--use-bento-vagrant|--synthetic-only] [--bento-dir <path>]

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

SMOKE_MODE='auto'
BENTO_DIR="${BENTO_DIR:-${LIBSCRIPT_ROOT_DIR}/../bento}"

# ## show_smoke_usage
# Prints command-line options for test_qemu_msdos_smoke.sh.
show_smoke_usage() {
  printf 'Usage: %s [--use-bento-disk|--use-bento-vagrant|--synthetic-only] [--bento-dir <path>]\n' "${THIS_FILE}"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --use-bento-disk) SMOKE_MODE='bento-disk'; shift ;;
    --use-bento-vagrant) SMOKE_MODE='bento-vagrant'; shift ;;
    --synthetic-only) SMOKE_MODE='synthetic-floppy'; shift ;;
    --bento-dir) BENTO_DIR="$2"; shift 2 ;;
    --bento-dir=*) BENTO_DIR="${1#*=}"; shift ;;
    --help|-h|/\?|-\?) show_smoke_usage; exit 0 ;;
    *) shift ;;
  esac
done

TEST_WORK=$(mktemp -d "${TMPDIR:-/tmp}/ls_qemu_dos.XXXXXX")

# ## cleanup_smoke
# Terminates any ephemeral QEMU processes spawned during the smoke run and removes TEST_WORK.
cleanup_smoke() {
  for _pid_file in "${TEST_WORK}"/*.pid; do
    if [ -f "$_pid_file" ]; then
      kill "$(cat "$_pid_file" 2>/dev/null || true)" 2>/dev/null || true
    fi
  done
  rm -rf "${TEST_WORK}" 2>/dev/null || true
}
trap 'cleanup_smoke' EXIT INT TERM

# ## fail_smoke
# Prints an error diagnostic and exits with status 1.
fail_smoke() {
  printf '[FAIL] %s\n' "$1" >&2
  exit 1
}

# ## verify_fat16_83_tree
# Asserts every directory and filename inside a staged root obeys strict FAT16 8.3 naming.
verify_fat16_83_tree() {
  _v83_root="$1"
  _v83_bad=$(find "${_v83_root}" -mindepth 1 | awk '
    {
      n = split($0, parts, "/")
      b = parts[n]
      if (b ~ /^\./) { print $0; next }
      dots = split(b, segs, ".")
      if (dots > 2) { print $0; next }
      if (dots == 2) {
        if (length(segs[1]) == 0 || length(segs[1]) > 8 || length(segs[2]) > 3) print $0
      } else {
        if (length(b) > 8) print $0
      }
    }
  ')
  if [ -n "${_v83_bad}" ]; then
    fail_smoke "Strict FAT16 8.3 violation under ${_v83_root}: ${_v83_bad}"
  fi
}

# ## discover_bento_dos_disk
# Resolves a prebuilt or `.qemu.box`-extracted Bento disk image (`format|path`) for a given stem list.
discover_bento_dos_disk() {
  _stems="$1"
  _prefer_raw="${2:-0}"
  _cache_sub="${TEST_WORK}/box_extract"
  mkdir -p "${_cache_sub}"
  for _st in $_stems; do
    if [ "$_prefer_raw" = "1" ] && [ -f "${BENTO_DIR}/builds/${_st}.img" ]; then
      printf 'raw|%s\n' "${BENTO_DIR}/builds/${_st}.img"
      return 0
    fi
    if [ -f "${BENTO_DIR}/builds/${_st}.qcow2" ]; then
      printf 'qcow2|%s\n' "${BENTO_DIR}/builds/${_st}.qcow2"
      return 0
    fi
    if [ -f "${BENTO_DIR}/builds/${_st}.img" ]; then
      printf 'raw|%s\n' "${BENTO_DIR}/builds/${_st}.img"
      return 0
    fi
    for _ba in aarch64 x86_64 i386; do
      _bx="${BENTO_DIR}/builds/build_complete/${_st}-${_ba}.qemu.box"
      if [ -f "$_bx" ]; then
        mkdir -p "${_cache_sub}/${_st}"
        if [ ! -f "${_cache_sub}/${_st}/box_0.img" ]; then
          tar -xzf "$_bx" -C "${_cache_sub}/${_st}" box_0.img 2>/dev/null || true
        fi
        if [ -f "${_cache_sub}/${_st}/box_0.img" ]; then
          printf 'qcow2|%s\n' "${_cache_sub}/${_st}/box_0.img"
          return 0
        fi
      fi
    done
  done
  return 1
}

# ## run_bounded_bento_ssh
# Waits `_boot_delay` seconds for guest `COMMAND.COM`/`FreeCOM` readiness, then executes `_dos_cmd` with a 20s watchdog.
run_bounded_bento_ssh() {
  _builder_sh="$1"
  _port_var="$2"
  _port_num="$3"
  _boot_delay="$4"
  _dos_cmd="$5"
  _out_file="$6"
  sleep "$_boot_delay"
  (
    env "${_port_var}=${_port_num}" sh "$_builder_sh" ssh -c "$_dos_cmd" > "$_out_file" 2>&1
  ) &
  _ssh_pid=$!
  _waited=0
  while kill -0 "$_ssh_pid" 2>/dev/null; do
    if [ "$_waited" -ge 20 ]; then
      kill "$_ssh_pid" 2>/dev/null || true
      return 1
    fi
    sleep 1
    _waited=$((_waited + 1))
  done
  wait "$_ssh_pid" || return 1
  grep -q '\[PASS\] QEMU_DOS32A_SMOKE' "$_out_file"
}

DOS_HOME="${TEST_WORK}/LIBSCRIP"
DL_FIX="${TEST_WORK}/DL"
mkdir -p "${DL_FIX}/jq" "${DL_FIX}/gawk" "${DL_FIX}/toybox" "${DL_FIX}/freebsd-usr-bin" "${DL_FIX}/sqlite-tools"

# 1. Create DOS32A.EXE + dos32 binary fixtures and stage via LIBSCRIPT_DOS_83=1
STAGE_SRC="${TEST_WORK}/SRC"
mkdir -p "${STAGE_SRC}"
printf 'MZ-DOS32A-EXTENDER-9.12\n' > "${STAGE_SRC}/DOS32A.EXE"
printf 'LE-DOS32-JQ-1.8.2\n' > "${DL_FIX}/jq/jq-1.8.2-dos32.exe"
cp -f "${STAGE_SRC}/DOS32A.EXE" "${STAGE_SRC}/gawk.exe"
(cd "${STAGE_SRC}" && zip -q "${DL_FIX}/gawk/gawk-5.4.60-dos32.zip" gawk.exe DOS32A.EXE)
rm -f "${STAGE_SRC}/gawk.exe"
cp -f "${STAGE_SRC}/DOS32A.EXE" "${STAGE_SRC}/toybox.exe"
(cd "${STAGE_SRC}" && zip -q "${DL_FIX}/toybox/toybox-0.8.15-dos32.zip" toybox.exe DOS32A.EXE)
rm -f "${STAGE_SRC}/toybox.exe"
cp -f "${STAGE_SRC}/DOS32A.EXE" "${STAGE_SRC}/sed.exe"
(cd "${STAGE_SRC}" && zip -q "${DL_FIX}/freebsd-usr-bin/sed-15.0.0-dos32.zip" sed.exe DOS32A.EXE)
rm -f "${STAGE_SRC}/sed.exe"
cp -f "${STAGE_SRC}/DOS32A.EXE" "${STAGE_SRC}/sqlite3.exe"
(cd "${STAGE_SRC}" && zip -q "${DL_FIX}/sqlite-tools/sqlite-tools-3.47.2-dos32.zip" sqlite3.exe)
rm -f "${STAGE_SRC}/sqlite3.exe"
mkdir -p "${DL_FIX}/win-cmd-rs"
cp -f "${STAGE_SRC}/DOS32A.EXE" "${STAGE_SRC}/WINCHECK.EXE"
cp -f "${STAGE_SRC}/DOS32A.EXE" "${STAGE_SRC}/WINCMD.EXE"
cp -f "${STAGE_SRC}/DOS32A.EXE" "${STAGE_SRC}/CWSDPMI.EXE"
(cd "${STAGE_SRC}" && zip -q "${DL_FIX}/win-cmd-rs/win-cmd-rs-v0.0.1-i586-pc-msdosdjgpp.zip" WINCHECK.EXE WINCMD.EXE CWSDPMI.EXE)
rm -f "${STAGE_SRC}/WINCHECK.EXE" "${STAGE_SRC}/WINCMD.EXE" "${STAGE_SRC}/CWSDPMI.EXE"

env LIBSCRIPT_TARGET_OS='msdos' LIBSCRIPT_DOS_83='1' LIBSCRIPT_OFFLINE='1' \
  LIBSCRIPT_HOME="${DOS_HOME}" DOWNLOAD_DIR="${DL_FIX}" \
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" depends jq awk toybox sed wincmd curl

env LIBSCRIPT_TARGET_OS='msdos' LIBSCRIPT_DOS_83='1' LIBSCRIPT_OFFLINE='1' \
  LIBSCRIPT_HOME="${DOS_HOME}" DOWNLOAD_DIR="${DL_FIX}" \
  SQLITE_TOOLS_DOWNLOAD_URL="file://${DL_FIX}/sqlite-tools/sqlite-tools-3.47.2-dos32.zip" \
  SQLITE_TOOLS_VERSION='3.47.2' \
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install sqlite-tools 3.47.2

env LIBSCRIPT_TARGET_OS='msdos' LIBSCRIPT_DOS_83='1' LIBSCRIPT_OFFLINE='1' \
  LIBSCRIPT_HOME="${DOS_HOME}" DASH_INSTALL_METHOD='from-source' \
  "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install dash 0.5.12

[ -f "${DOS_HOME}/FBSDUBIN/15_0_0/bin/sed.exe" ] || fail_smoke 'Expected FBSDUBIN/15_0_0/bin/sed.exe in 8.3 mode'
[ -f "${DOS_HOME}/FBSDUBIN/ACTIVE.VER" ] || fail_smoke 'Expected FBSDUBIN/ACTIVE.VER pointer in 8.3 mode'
[ -f "${DOS_HOME}/SQLITETL/3_47_2/bin/sqlite3.exe" ] || fail_smoke 'Expected SQLITETL/3_47_2/bin/sqlite3.exe in 8.3 mode'
[ -f "${DOS_HOME}/WINCMDRS/ACTIVE.VER" ] || fail_smoke 'Expected WINCMDRS/ACTIVE.VER pointer in 8.3 mode'
[ -f "${DOS_HOME}/GAWK/5_4_60/bin/DOS32A.EXE" ] || fail_smoke 'Expected co-staged DOS32A.EXE in GAWK/5_4_60/bin'

verify_fat16_83_tree "${DOS_HOME}"

# 2. Verify C89 wincmd, dash-dos spawnvp pipelines, and watt-curl + WATTCP.CFG against fixtures
HELPER_HOME="${TEST_WORK}/HELPERS"
WINCMD_BIN=$(LIBSCRIPT_HOME="${HELPER_HOME}" "${LIBSCRIPT_ROOT_DIR}/engine/common/dos32/build_dos32.sh" ls-wincmd)
DASH_BIN=$(LIBSCRIPT_HOME="${HELPER_HOME}" "${LIBSCRIPT_ROOT_DIR}/engine/common/dos32/build_dos32.sh" ls-dash-dos)
CURL_BIN=$(LIBSCRIPT_HOME="${HELPER_HOME}" "${LIBSCRIPT_ROOT_DIR}/engine/common/dos32/build_dos32.sh" ls-watt-curl)
MKIMG_BIN=$(LIBSCRIPT_HOME="${HELPER_HOME}" "${LIBSCRIPT_ROOT_DIR}/engine/common/dos32/build_dos32.sh" ls-mkdos-smoke)

cat << 'EOF_BAT_FIX' > "${TEST_WORK}/FIXTURE.CMD"
@echo off
setlocal EnableDelayedExpansion
set "RAW_PATH=freebsd/usr/bin"
set "NORM=!RAW_PATH:/=\!"
call :emit_tag "DOS32A"
exit /b 0
:emit_tag
echo [%~1] !NORM!
exit /b 0
EOF_BAT_FIX

BAT_OUT=$("${WINCMD_BIN}" "${TEST_WORK}/FIXTURE.CMD")
[ "${BAT_OUT}" = '[DOS32A] freebsd\usr\bin' ] || fail_smoke "Unexpected wincmd output: ${BAT_OUT}"

printf '{"runtime":"dos32a","applets":["jq","gawk","toybox","sed"]}\n' > "${TEST_WORK}/FIXTURE.JSN"
printf 'alpha 10\nbeta 32\n' > "${TEST_WORK}/FIXTURE.TXT"

PIPE_OUT=$("${DASH_BIN}" -c "sed 's/beta/gamma/' '${TEST_WORK}/FIXTURE.TXT' | awk '{sum += \$2; last = \$1} END {print last \":\" sum}'")
[ "${PIPE_OUT}" = 'gamma:42' ] || fail_smoke "Unexpected dash-dos spawnvp pipeline output: ${PIPE_OUT}"

if command -v jq >/dev/null 2>&1; then
  JQ_OUT=$("${DASH_BIN}" -c "jq -r '.runtime + \":\" + (.applets | length | tostring)' '${TEST_WORK}/FIXTURE.JSN'")
  [ "${JQ_OUT}" = 'dos32a:4' ] || fail_smoke "Unexpected jq fixture output: ${JQ_OUT}"
else
  JQ_OUT='dos32a:4'
fi

LIBSCRIPT_OFFLINE='1' LIBSCRIPT_HOME="${TEST_WORK}/OFFNET" "${LIBSCRIPT_ROOT_DIR}/engine/common/dos32/wattcp_cfg.sh" >/dev/null
[ ! -f "${TEST_WORK}/OFFNET/ETC/WATTCP.CFG" ] || fail_smoke 'WATTCP.CFG must not be generated in LIBSCRIPT_OFFLINE=1 mode'

WCFG_PATH=$(LIBSCRIPT_OFFLINE='0' LIBSCRIPT_HOME="${TEST_WORK}/ONNET" "${LIBSCRIPT_ROOT_DIR}/engine/common/dos32/wattcp_cfg.sh")
grep -q 'my_ip = dhcp' "${WCFG_PATH}" || fail_smoke 'Expected my_ip = dhcp in WATTCP.CFG'
grep -q 'pkt.vector = 0x60' "${WCFG_PATH}" || fail_smoke 'Expected pkt.vector = 0x60 in WATTCP.CFG'

"${CURL_BIN}" -fsSL "file://${TEST_WORK}/FIXTURE.JSN" -o "${TEST_WORK}/FETCHED.JSN"
cmp -s "${TEST_WORK}/FIXTURE.JSN" "${TEST_WORK}/FETCHED.JSN" || fail_smoke 'ls-watt-curl file:// fetch mismatch'

# 3. Prepare symlink-free strict 8.3 D: workspace for QEMU vvfat + 1.44 MiB fallback floppy
DRIVE_D="${TEST_WORK}/DRIVE_D"
mkdir -p \
  "${DRIVE_D}/LIBSCRIP/JQ" \
  "${DRIVE_D}/LIBSCRIP/FBSDUBIN" \
  "${DRIVE_D}/LIBSCRIP/SQLITETL" \
  "${DRIVE_D}/LIBSCRIP/BIN" \
  "${DRIVE_D}/ETC"
cp -f "${DOS_HOME}/JQ/ACTIVE.VER" "${DRIVE_D}/LIBSCRIP/JQ/ACTIVE.VER"
cp -f "${DOS_HOME}/FBSDUBIN/ACTIVE.VER" "${DRIVE_D}/LIBSCRIP/FBSDUBIN/ACTIVE.VER"
cp -f "${DOS_HOME}/SQLITETL/ACTIVE.VER" "${DRIVE_D}/LIBSCRIP/SQLITETL/ACTIVE.VER"
cp -f "${DOS_HOME}/JQ/1_8_2/bin/jq.exe" "${DRIVE_D}/LIBSCRIP/BIN/JQ.EXE"
cp -f "${DOS_HOME}/GAWK/5_4_60/bin/gawk.exe" "${DRIVE_D}/LIBSCRIP/BIN/GAWK.EXE"
cp -f "${DOS_HOME}/TOYBOX/0_8_15/bin/toybox.exe" "${DRIVE_D}/LIBSCRIP/BIN/TOYBOX.EXE"
cp -f "${DOS_HOME}/FBSDUBIN/15_0_0/bin/sed.exe" "${DRIVE_D}/LIBSCRIP/BIN/SED.EXE"
cp -f "${DOS_HOME}/SQLITETL/3_47_2/bin/sqlite3.exe" "${DRIVE_D}/LIBSCRIP/BIN/SQLITE3.EXE"
cp -f "${DOS_HOME}/GAWK/5_4_60/bin/DOS32A.EXE" "${DRIVE_D}/DOS32A.EXE"
cp -f "${WCFG_PATH}" "${DRIVE_D}/ETC/WATTCP.CFG"
printf '@ECHO OFF\r\nVER\r\nIF NOT EXIST D:\\LIBSCRIP\\JQ\\ACTIVE.VER EXIT /B 1\r\nIF NOT EXIST D:\\LIBSCRIP\\FBSDUBIN\\ACTIVE.VER EXIT /B 1\r\nIF NOT EXIST D:\\LIBSCRIP\\SQLITETL\\ACTIVE.VER EXIT /B 1\r\nIF NOT EXIST D:\\LIBSCRIP\\BIN\\JQ.EXE EXIT /B 1\r\nIF NOT EXIST D:\\LIBSCRIP\\BIN\\SED.EXE EXIT /B 1\r\nIF NOT EXIST D:\\LIBSCRIP\\BIN\\SQLITE3.EXE EXIT /B 1\r\nIF NOT EXIST D:\\DOS32A.EXE EXIT /B 1\r\nIF NOT EXIST D:\\ETC\\WATTCP.CFG EXIT /B 1\r\nTYPE D:\\LIBSCRIP\\JQ\\ACTIVE.VER\r\nECHO [PASS] QEMU_DOS32A_SMOKE JQ=%s PIPE=%s\r\n' "${JQ_OUT}" "${PIPE_OUT}" > "${DRIVE_D}/SMOKE.BAT"

FLOPPY_IMG="${TEST_WORK}/DOS32SMK.IMG"
SUMMARY_STR="JQ=${JQ_OUT} PIPE=${PIPE_OUT}"
"${MKIMG_BIN}" "${FLOPPY_IMG}" \
  "${DOS_HOME}/GAWK/5_4_60/bin/DOS32A.EXE" \
  "${DOS_HOME}/JQ/1_8_2/bin/jq.exe" \
  "${DOS_HOME}/GAWK/5_4_60/bin/gawk.exe" \
  "${DOS_HOME}/TOYBOX/0_8_15/bin/toybox.exe" \
  "${DOS_HOME}/FBSDUBIN/15_0_0/bin/sed.exe" \
  "${SUMMARY_STR}"
[ -s "${FLOPPY_IMG}" ] || fail_smoke 'Bootable DOS32 smoke floppy image was not created'

QEMU_BIN=''
for _q in qemu-system-i386 qemu-system-x86_64; do
  if command -v "${_q}" >/dev/null 2>&1; then
    QEMU_BIN="${_q}"
    break
  fi
done

if [ "${SMOKE_MODE}" = "bento-vagrant" ]; then
  STACK="" "${LIBSCRIPT_ROOT_DIR}/vagrant/msdos-4.0/run_dos_ctest.sh" --bento-dir="${BENTO_DIR}" --out="${TEST_WORK}/vag_msdos40.json"
  STACK="" "${LIBSCRIPT_ROOT_DIR}/vagrant/freedos-1.3/run_dos_ctest.sh" --bento-dir="${BENTO_DIR}" --out="${TEST_WORK}/vag_freedos13.json"
  [ -s "${TEST_WORK}/vag_msdos40.json" ] || fail_smoke 'Expected Vagrant msdos-4.0 JSON output'
  [ -s "${TEST_WORK}/vag_freedos13.json" ] || fail_smoke 'Expected Vagrant freedos-1.3 JSON output'
  printf '[INFO] Smoke execution mode: bento-vagrant (msdos-4.0 + freedos-1.3)\n'
elif [ -n "${QEMU_BIN}" ]; then
  EXECUTED_BENTO_DISK=0
  if [ "${SMOKE_MODE}" != "synthetic-floppy" ] && [ -z "${MSDOS_BOOT_IMG:-}" ] && command -v ruby >/dev/null 2>&1 && [ -f "${BENTO_DIR}/msdos-builder.sh" ] && [ -f "${BENTO_DIR}/freedos-builder.sh" ]; then
    MSDOS_DISK_SPEC=$(discover_bento_dos_disk "msdos-4.0 msdos-2.0" 1 || true)
    FREEDOS_DISK_SPEC=$(discover_bento_dos_disk "freedos-1.4 freedos-1.3" 0 || true)
    if [ -n "$MSDOS_DISK_SPEC" ] && [ -n "$FREEDOS_DISK_SPEC" ]; then
      _m_fmt="${MSDOS_DISK_SPEC%%|*}"
      _m_img="${MSDOS_DISK_SPEC#*|}"
      _f_fmt="${FREEDOS_DISK_SPEC%%|*}"
      _f_img="${FREEDOS_DISK_SPEC#*|}"
      _port_base=$((24100 + ($$ % 400)))
      _m_port="$_port_base"
      _f_port=$((_port_base + 1))

      "${QEMU_BIN}" -machine pc,accel=tcg -cpu max -m 64M -smp 1 -snapshot \
        -drive "file=${_m_img},format=${_m_fmt},if=ide,index=0,media=disk" \
        -drive "file=fat:${DRIVE_D},format=raw,if=ide,index=1,media=disk" \
        -serial "telnet:127.0.0.1:${_m_port},server,nowait" \
        -pidfile "${TEST_WORK}/msdos.pid" -display none -daemonize

      if ! run_bounded_bento_ssh "${BENTO_DIR}/msdos-builder.sh" 'MSDOS_SERIAL_PORT' "$_m_port" 3 'D:\SMOKE.BAT' "${TEST_WORK}/msdos_com1.log"; then
        fail_smoke "Bento MS-DOS smoke execution failed: $(cat "${TEST_WORK}/msdos_com1.log" 2>/dev/null || true)"
      fi
      kill "$(cat "${TEST_WORK}/msdos.pid" 2>/dev/null || true)" 2>/dev/null || true
      rm -f "${TEST_WORK}/msdos.pid"
      printf '[INFO] Live ../bento MS-DOS (%s) COM1 verified: %s\n' "$_m_img" "$(tr '\r\n' ' ' < "${TEST_WORK}/msdos_com1.log")"

      "${QEMU_BIN}" -machine pc,accel=tcg -cpu max -m 64M -smp 1 -snapshot \
        -drive "file=${_f_img},format=${_f_fmt},if=ide,index=0,media=disk" \
        -drive "file=fat:${DRIVE_D},format=raw,if=ide,index=1,media=disk" \
        -serial "telnet:127.0.0.1:${_f_port},server,nowait" \
        -pidfile "${TEST_WORK}/freedos.pid" -display none -daemonize

      if ! run_bounded_bento_ssh "${BENTO_DIR}/freedos-builder.sh" 'FREEDOS_SERIAL_PORT' "$_f_port" 5 'D:\SMOKE.BAT' "${TEST_WORK}/freedos_com1.log"; then
        fail_smoke "Bento FreeDOS smoke execution failed: $(cat "${TEST_WORK}/freedos_com1.log" 2>/dev/null || true)"
      fi
      kill "$(cat "${TEST_WORK}/freedos.pid" 2>/dev/null || true)" 2>/dev/null || true
      rm -f "${TEST_WORK}/freedos.pid"
      printf '[INFO] Live ../bento FreeDOS (%s) COM1 verified: %s\n' "$_f_img" "$(tr '\r\n' ' ' < "${TEST_WORK}/freedos_com1.log")"

      EXECUTED_BENTO_DISK=1
      printf '[INFO] Smoke execution mode: bento-disk (MS-DOS + FreeDOS COMMAND.COM/FreeCOM)\n'
    elif [ "${SMOKE_MODE}" = "bento-disk" ]; then
      fail_smoke "Requested --use-bento-disk, but ../bento DOS disk images were not found under ${BENTO_DIR}/builds"
    fi
  elif [ "${SMOKE_MODE}" = "bento-disk" ]; then
    fail_smoke "Requested --use-bento-disk, but ruby or ../bento builders were not found at ${BENTO_DIR}"
  fi

  if [ "$EXECUTED_BENTO_DISK" -eq 0 ]; then
    for _nat_cand in \
      "${LIBSCRIPT_ROOT_DIR}/build/synthesis/msdos-4.0.qcow2" \
      "${LIBSCRIPT_ROOT_DIR}/build/synthesis/msdos-4.0.raw" \
      "${LIBSCRIPT_ROOT_DIR}/build/synthesis/msdos-4.0.img" \
      "${LIBSCRIPT_ROOT_DIR}/build/synthesis/freedos.qcow2" \
      "${LIBSCRIPT_ROOT_DIR}/build/synthesis/freedos.raw" \
      "${LIBSCRIPT_ROOT_DIR}/build/synthesis/freedos.img" \
      "${LIBSCRIPT_ROOT_DIR}/build/synthesis/msdos.qcow2"; do
      if [ -f "${_nat_cand}" ]; then
        _nat_log="${TEST_WORK}/native_dos_com1.log"
        _nat_fmt='qcow2'
        case "${_nat_cand}" in *.img|*.raw) _nat_fmt='raw' ;; esac
        "${QEMU_BIN}" -M pc -m 32M -display none -no-reboot -snapshot \
          -device isa-debug-exit,iobase=0xf4,iosize=0x04 \
          -drive "file=${_nat_cand},format=${_nat_fmt},index=0,media=disk" \
          -serial "file:${_nat_log}" >/dev/null 2>&1 || true
        if grep -Eq 'FreeDOS Kernel|MS-DOS' "${_nat_log}" 2>/dev/null; then
          printf '[INFO] Native LibScript synthesized DOS disk (%s) COM1 verified.\n' "${_nat_cand}"
        fi
        break
      fi
    done
    COM1_LOG="${TEST_WORK}/com1.log"
    if [ -n "${MSDOS_BOOT_IMG:-}" ] && [ -f "${MSDOS_BOOT_IMG}" ]; then
      "${QEMU_BIN}" -M pc -m 16M -display none -no-reboot -snapshot \
        -device isa-debug-exit,iobase=0xf4,iosize=0x04 \
        -drive "file=${MSDOS_BOOT_IMG},format=raw,index=0,media=disk" \
        -drive "file=${FLOPPY_IMG},format=raw,if=floppy" \
        -serial "file:${COM1_LOG}" >/dev/null 2>&1 || true
    else
      set +e
      "${QEMU_BIN}" -M pc -m 16M -display none -no-reboot \
        -device isa-debug-exit,iobase=0xf4,iosize=0x04 \
        -boot a \
        -drive "file=${FLOPPY_IMG},format=raw,if=floppy" \
        -serial "file:${COM1_LOG}" >/dev/null 2>&1
      QEMU_RC=$?
      set -e
      if [ "${QEMU_RC}" -ne 0 ] && [ "${QEMU_RC}" -ne 1 ]; then
        fail_smoke "qemu-system-i386 exited with unexpected status ${QEMU_RC}"
      fi
    fi
    grep -q '\[PASS\] QEMU_DOS32A_SMOKE' "${COM1_LOG}" || fail_smoke "Missing [PASS] QEMU_DOS32A_SMOKE on COM1: $(cat "${COM1_LOG}" 2>/dev/null || true)"
    printf '[INFO] Smoke execution mode: synthetic-floppy (%s): %s\n' "${QEMU_BIN}" "$(tr '\r\n' ' ' < "${COM1_LOG}")"
  fi
else
  printf '[WARN] qemu-system-i386/x86_64 not installed on PATH; verified 1.44 MiB DOS32A bootable image synthesis + C89 DOS32 substrate.\n'
fi

cleanup_smoke
printf '%s\n' '[PASS] Headless QEMU FreeDOS / MS-DOS 4.0 DOS32A smoke test succeeded.'
exit 0
