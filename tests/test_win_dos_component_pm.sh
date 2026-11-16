#!/bin/sh
# ## Overview
# End-to-end verification of the 6 Windows native & MS-DOS component-level package managers
# (`jq`, `gawk`, `busybox`, `toybox`, `dash`, `freebsd-usr-bin`) and target-aware `depends` routing.
#
# ## Usage
# ./tests/test_win_dos_component_pm.sh

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
export LIBSCRIPT_ROOT_DIR

TEST_WORK=$(mktemp -d "${TMPDIR:-/tmp}/ls_win_dos_pm.XXXXXX")
trap 'rm -rf "$TEST_WORK"' EXIT INT TERM

# ## fail_test
# Prints a failure message and exits with status 1.
fail_test() {
  printf '[FAIL] %s\n' "$1" >&2
  exit 1
}

# ## make_zip_fixture
# Creates a zip fixture archive containing a named binary payload and optional DOS32A.EXE extender.
make_zip_fixture() {
  _zip_out="$1"
  _bin_name="$2"
  _payload="$3"
  _with_dos32a="${4:-0}"
  _stage="${TEST_WORK}/zip_stage.$$"
  rm -rf "$_stage"
  mkdir -p "$_stage"
  printf '%s\n' "$_payload" > "${_stage}/${_bin_name}"
  if [ "$_with_dos32a" = '1' ]; then
    printf '%s\n' 'DOS32A-EXTENDER-STUB' > "${_stage}/DOS32A.EXE"
  fi
  mkdir -p "$(dirname "$_zip_out")"
  (
    cd "$_stage"
    if [ "$_with_dos32a" = '1' ]; then
      zip -q "$_zip_out" "$_bin_name" 'DOS32A.EXE'
    else
      zip -q "$_zip_out" "$_bin_name"
    fi
  )
  rm -rf "$_stage"
}

DL_FIXTURES="${TEST_WORK}/downloads"
mkdir -p "${DL_FIXTURES}/jq" "${DL_FIXTURES}/gawk" "${DL_FIXTURES}/busybox" "${DL_FIXTURES}/toybox" "${DL_FIXTURES}/dash" "${DL_FIXTURES}/freebsd-usr-bin"

# 1. Stage distinct MS-DOS (dos32) vs Windows (X64) fixtures for all 6 projects
printf '%s\n' 'MSDOS-DOS32-JQ-1.8.2' > "${DL_FIXTURES}/jq/jq-1.8.2-dos32.exe"
printf '%s\n' 'WIN32-PE-X64-JQ-1.8.2' > "${DL_FIXTURES}/jq/jq-1.8.2-X64.exe"

make_zip_fixture "${DL_FIXTURES}/gawk/gawk-5.4.60-dos32.zip" 'GAWK.EXE' 'MSDOS-DOS32-GAWK-5.4.60' 1
make_zip_fixture "${DL_FIXTURES}/gawk/gawk-5.4.60-X64.zip" 'gawk.exe' 'WIN32-PE-X64-GAWK-5.4.60' 0

make_zip_fixture "${DL_FIXTURES}/busybox/busybox-1.39.0-dos32.zip" 'BUSYBOX.EXE' 'MSDOS-DOS32-BUSYBOX-1.39.0' 1
printf '%s\n' 'WIN32-PE-X64-BUSYBOX-1.39.0' > "${DL_FIXTURES}/busybox/busybox-1.39.0-X64.exe"

make_zip_fixture "${DL_FIXTURES}/toybox/toybox-0.8.15-dos32.zip" 'TOYBOX.EXE' 'MSDOS-DOS32-TOYBOX-0.8.15' 1
make_zip_fixture "${DL_FIXTURES}/toybox/toybox-0.8.15-X64.zip" 'toybox.exe' 'WIN32-PE-X64-TOYBOX-0.8.15' 0

make_zip_fixture "${DL_FIXTURES}/dash/dash-0.5.12-dos32.zip" 'DASH.EXE' 'MSDOS-DOS32-DASH-0.5.12' 1
make_zip_fixture "${DL_FIXTURES}/dash/dash-0.5.12-X64.zip" 'dash.exe' 'WIN32-PE-X64-DASH-0.5.12' 0

make_zip_fixture "${DL_FIXTURES}/freebsd-usr-bin/sed-15.0.0-dos32.zip" 'SED.EXE' 'MSDOS-DOS32-FBSD-SED-15.0.0' 1
make_zip_fixture "${DL_FIXTURES}/freebsd-usr-bin/sed-15.0.0-windows.zip" 'sed.exe' 'WIN32-PE-FBSD-SED-15.0.0' 0
make_zip_fixture "${DL_FIXTURES}/freebsd-usr-bin/freebsd-usr-bin-15.0.0-dos32.zip" 'SED.EXE' 'MSDOS-DOS32-FBSD-SUITE-15.0.0' 1
make_zip_fixture "${DL_FIXTURES}/freebsd-usr-bin/freebsd-usr-bin-15.0.0-X64.zip" 'sed.exe' 'WIN32-PE-X64-FBSD-SUITE-15.0.0' 0

# 2. Verify MS-DOS target: `depends jq awk busybox toybox sh sed` gets MS-DOS dos32 binaries
DOS_HOME="${TEST_WORK}/dos_home"
env LIBSCRIPT_TARGET_OS='msdos' LIBSCRIPT_OFFLINE='1' LIBSCRIPT_HOME="$DOS_HOME" DOWNLOAD_DIR="$DL_FIXTURES" "$LIBSCRIPT_ROOT_DIR/libscript.sh" depends jq awk busybox toybox sh sed

[ -f "${DOS_HOME}/jq/default/bin/jq.exe" ] || fail_test 'MS-DOS depends jq did not create jq/default/bin/jq.exe'
[ "$(cat "${DOS_HOME}/jq/default/bin/jq.exe")" = 'MSDOS-DOS32-JQ-1.8.2' ] || fail_test 'MS-DOS depends jq fetched wrong binary payload'

[ -f "${DOS_HOME}/gawk/default/bin/gawk.exe" ] || fail_test 'MS-DOS depends awk did not stage gawk.exe'
[ -f "${DOS_HOME}/gawk/default/bin/awk.exe" ] || fail_test 'MS-DOS depends awk did not stage awk.exe alias'
[ -f "${DOS_HOME}/gawk/default/bin/DOS32A.EXE" ] || fail_test 'MS-DOS gawk did not co-stage DOS32A.EXE'
[ "$(cat "${DOS_HOME}/gawk/default/bin/gawk.exe")" = 'MSDOS-DOS32-GAWK-5.4.60' ] || fail_test 'MS-DOS gawk payload mismatch'

[ -f "${DOS_HOME}/busybox/default/bin/busybox.exe" ] || fail_test 'MS-DOS depends busybox did not stage busybox.exe'
[ "$(cat "${DOS_HOME}/busybox/default/bin/busybox.exe")" = 'MSDOS-DOS32-BUSYBOX-1.39.0' ] || fail_test 'MS-DOS busybox payload mismatch'

[ -f "${DOS_HOME}/toybox/default/bin/toybox.exe" ] || fail_test 'MS-DOS depends toybox did not stage toybox.exe'
[ "$(cat "${DOS_HOME}/toybox/default/bin/toybox.exe")" = 'MSDOS-DOS32-TOYBOX-0.8.15' ] || fail_test 'MS-DOS toybox payload mismatch'

[ -f "${DOS_HOME}/dash/default/bin/dash.exe" ] || fail_test 'MS-DOS depends sh did not stage dash.exe'
[ -f "${DOS_HOME}/dash/default/bin/sh.exe" ] || fail_test 'MS-DOS depends sh did not stage sh.exe'
[ "$(cat "${DOS_HOME}/dash/default/bin/dash.exe")" = 'MSDOS-DOS32-DASH-0.5.12' ] || fail_test 'MS-DOS dash payload mismatch'

[ -f "${DOS_HOME}/freebsd-usr-bin/default/bin/sed.exe" ] || fail_test 'MS-DOS depends sed did not stage sed.exe'
[ "$(cat "${DOS_HOME}/freebsd-usr-bin/default/bin/sed.exe")" = 'MSDOS-DOS32-FBSD-SED-15.0.0' ] || fail_test 'MS-DOS freebsd-usr-bin sed payload mismatch'

# 3. Verify Windows target: `depends jq awk busybox toybox sh sed` gets Windows PE X64 binaries
WIN_HOME="${TEST_WORK}/win_home"
env LIBSCRIPT_TARGET_OS='windows' LIBSCRIPT_TARGET_ARCH='x86_64' LIBSCRIPT_OFFLINE='1' LIBSCRIPT_HOME="$WIN_HOME" DOWNLOAD_DIR="$DL_FIXTURES" "$LIBSCRIPT_ROOT_DIR/libscript.sh" depends jq awk busybox toybox sh sed

[ -f "${WIN_HOME}/jq/default/bin/jq.exe" ] || fail_test 'Windows depends jq did not create jq/default/bin/jq.exe'
[ "$(cat "${WIN_HOME}/jq/default/bin/jq.exe")" = 'WIN32-PE-X64-JQ-1.8.2' ] || fail_test 'Windows depends jq fetched wrong binary payload'

[ "$(cat "${WIN_HOME}/gawk/default/bin/gawk.exe")" = 'WIN32-PE-X64-GAWK-5.4.60' ] || fail_test 'Windows gawk payload mismatch'
[ "$(cat "${WIN_HOME}/busybox/default/bin/busybox.exe")" = 'WIN32-PE-X64-BUSYBOX-1.39.0' ] || fail_test 'Windows busybox payload mismatch'
[ "$(cat "${WIN_HOME}/toybox/default/bin/toybox.exe")" = 'WIN32-PE-X64-TOYBOX-0.8.15' ] || fail_test 'Windows toybox payload mismatch'
[ "$(cat "${WIN_HOME}/dash/default/bin/dash.exe")" = 'WIN32-PE-X64-DASH-0.5.12' ] || fail_test 'Windows dash payload mismatch'
[ "$(cat "${WIN_HOME}/freebsd-usr-bin/default/bin/sed.exe")" = 'WIN32-PE-FBSD-SED-15.0.0' ] || fail_test 'Windows freebsd-usr-bin sed payload mismatch'

# 4. Verify *-windows component aliases via `libscript.sh install <alias> <ver>`
ALIAS_HOME="${TEST_WORK}/alias_home"
env LIBSCRIPT_TARGET_OS='windows' LIBSCRIPT_TARGET_ARCH='x86_64' LIBSCRIPT_OFFLINE='1' LIBSCRIPT_HOME="$ALIAS_HOME" DOWNLOAD_DIR="$DL_FIXTURES" "$LIBSCRIPT_ROOT_DIR/libscript.sh" install freebsd-usr-bin-windows 15.0.0
[ "$(cat "${ALIAS_HOME}/freebsd-usr-bin/default/bin/sed.exe")" = 'WIN32-PE-X64-FBSD-SUITE-15.0.0' ] || fail_test 'freebsd-usr-bin-windows suite alias failed'

# 5. Verify in-process `depends jq` shell function from _lib/_common/pkg_mgr.sh updates PATH
FUNC_HOME="${TEST_WORK}/func_home"
(
  LIBSCRIPT_TARGET_OS='msdos'
  LIBSCRIPT_OFFLINE='1'
  LIBSCRIPT_HOME="$FUNC_HOME"
  DOWNLOAD_DIR="$DL_FIXTURES"
  export LIBSCRIPT_TARGET_OS LIBSCRIPT_OFFLINE LIBSCRIPT_HOME DOWNLOAD_DIR
  unset ARCH UNAME UNAME_LOWER TARGET_OS PKG_MGR IS_MSDOS || true
  SCRIPT_NAME="$LIBSCRIPT_ROOT_DIR/_lib/_common/pkg_mgr.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "$SCRIPT_NAME"
  unset SCRIPT_NAME || true
  depends jq
  case ":$PATH:" in
    *":${FUNC_HOME}/jq/default/bin:"*) ;;
    *) exit 1 ;;
  esac
) || fail_test 'In-process depends jq function failed to install and prepend PATH'

printf '%s\n' '[PASS] All 6 Windows native & MS-DOS component-level package managers verified.'
exit 0
