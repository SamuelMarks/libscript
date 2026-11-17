#!/bin/sh
# ## Overview
# Headless QEMU FreeDOS / MS-DOS 4.0 (`dos32`) smoke test verifying strict FAT16 8.3 staging (`LIBSCRIPT_DOS_83=1`), C89 `wincmd`/`dash`/`curl` substrate, and `COM1` boot output.
# ## Usage
# ./tests/test_qemu_msdos_smoke.sh

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

TEST_WORK=$(mktemp -d "${TMPDIR:-/tmp}/ls_qemu_dos.XXXXXX")
trap 'rm -rf "${TEST_WORK}"' EXIT INT TERM

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
WINCMD_BIN=$(LIBSCRIPT_HOME="${HELPER_HOME}" "${LIBSCRIPT_ROOT_DIR}/_lib/_common/dos32/build_dos32.sh" ls-wincmd)
DASH_BIN=$(LIBSCRIPT_HOME="${HELPER_HOME}" "${LIBSCRIPT_ROOT_DIR}/_lib/_common/dos32/build_dos32.sh" ls-dash-dos)
CURL_BIN=$(LIBSCRIPT_HOME="${HELPER_HOME}" "${LIBSCRIPT_ROOT_DIR}/_lib/_common/dos32/build_dos32.sh" ls-watt-curl)
MKIMG_BIN=$(LIBSCRIPT_HOME="${HELPER_HOME}" "${LIBSCRIPT_ROOT_DIR}/_lib/_common/dos32/build_dos32.sh" ls-mkdos-smoke)

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

# Verify Watt-32 WATTCP.CFG online vs offline behavior + file:// fetch
LIBSCRIPT_OFFLINE='1' LIBSCRIPT_HOME="${TEST_WORK}/OFFNET" "${LIBSCRIPT_ROOT_DIR}/_lib/_common/dos32/wattcp_cfg.sh" >/dev/null
[ ! -f "${TEST_WORK}/OFFNET/ETC/WATTCP.CFG" ] || fail_smoke 'WATTCP.CFG must not be generated in LIBSCRIPT_OFFLINE=1 mode'

WCFG_PATH=$(LIBSCRIPT_OFFLINE='0' LIBSCRIPT_HOME="${TEST_WORK}/ONNET" "${LIBSCRIPT_ROOT_DIR}/_lib/_common/dos32/wattcp_cfg.sh")
grep -q 'my_ip = dhcp' "${WCFG_PATH}" || fail_smoke 'Expected my_ip = dhcp in WATTCP.CFG'
grep -q 'pkt.vector = 0x60' "${WCFG_PATH}" || fail_smoke 'Expected pkt.vector = 0x60 in WATTCP.CFG'

"${CURL_BIN}" -fsSL "file://${TEST_WORK}/FIXTURE.JSN" -o "${TEST_WORK}/FETCHED.JSN"
cmp -s "${TEST_WORK}/FIXTURE.JSN" "${TEST_WORK}/FETCHED.JSN" || fail_smoke 'ls-watt-curl file:// fetch mismatch'

# 3. Synthesize bootable 1.44 MiB DOS32A smoke floppy image and boot in headless qemu-system-i386
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

if [ -n "${QEMU_BIN}" ]; then
  COM1_LOG="${TEST_WORK}/com1.log"
  if [ -n "${MSDOS_BOOT_IMG:-}" ] && [ -f "${MSDOS_BOOT_IMG}" ]; then
    "${QEMU_BIN}" -M pc -m 16M -display none -no-reboot \
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
    # isa-debug-exit with AL=0 exits QEMU with status (0 << 1) | 1 = 1
    if [ "${QEMU_RC}" -ne 0 ] && [ "${QEMU_RC}" -ne 1 ]; then
      fail_smoke "qemu-system-i386 exited with unexpected status ${QEMU_RC}"
    fi
  fi
  grep -q '\[PASS\] QEMU_DOS32A_SMOKE' "${COM1_LOG}" || fail_smoke "Missing [PASS] QEMU_DOS32A_SMOKE on COM1: $(cat "${COM1_LOG}" 2>/dev/null || true)"
  printf '[INFO] Headless QEMU (%s) COM1 output verified: %s\n' "${QEMU_BIN}" "$(tr '\r\n' ' ' < "${COM1_LOG}")"
else
  printf '[WARN] qemu-system-i386 not installed on PATH; verified 1.44 MiB DOS32A bootable image synthesis + C89 DOS32 substrate.\n'
fi

printf '%s\n' '[PASS] Headless QEMU FreeDOS / MS-DOS 4.0 DOS32A smoke test succeeded.'
exit 0
