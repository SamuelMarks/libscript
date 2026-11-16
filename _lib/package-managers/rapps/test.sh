#!/bin/sh
# ## Overview
# Smoke and 2-pass idempotency test suite for the rapps component.
# Verifies isolated installation, INI parsing across i686 and x86_64, search, and offline prefetch stamps.
#
# ## Usage
# ./_lib/package-managers/rapps/test.sh

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

_tmp_home=$(mktemp -d)
trap 'rm -rf "$_tmp_home"' EXIT INT TERM HUP
export LIBSCRIPT_HOME="${_tmp_home}/home"
unset LIBSCRIPT_RAPPS_DB_DIR LIBSCRIPT_RAPPS_CACHE_DIR || true
export LIBSCRIPT_OFFLINE=1

ACTION='install' STACK='' "${SCRIPT_DIR}/setup.sh"
_pass2=$(ACTION='install' STACK='' "${SCRIPT_DIR}/setup.sh" 2>&1)
printf '%s\n' "$_pass2" | grep -q '\[SKIP\]'

_parsed_x86=$(STACK="" "${SCRIPT_DIR}/cli.sh" parse-ini "${LIBSCRIPT_HOME}/rapps/0.4.16/db/7zip.txt" i686)
printf '%s\n' "$_parsed_x86" | grep -q '7z2408\.exe'

_parsed_x64=$(STACK="" "${SCRIPT_DIR}/cli.sh" parse-ini "${LIBSCRIPT_HOME}/rapps/0.4.16/db/7zip.txt" x86_64)
printf '%s\n' "$_parsed_x64" | grep -q '7z2408-x64\.exe'

STACK="" "${SCRIPT_DIR}/cli.sh" search 7zip | grep -qx '7zip'

_pf_dir="${_tmp_home}/prefetch"
STACK="" "${SCRIPT_DIR}/cli.sh" prefetch 7zip --arch=i686 --dest="$_pf_dir"
[ -f "${_pf_dir}/7zip.i686.stamp" ]
[ -f "${_pf_dir}/7zip.flags" ]
_pf_pass2=$(STACK="" "${SCRIPT_DIR}/cli.sh" prefetch 7zip --arch=i686 --dest="$_pf_dir")
printf '%s\n' "$_pf_pass2" | grep -q '\[SKIP\]'

printf '[PASS] rapps component tests passed.\n'
