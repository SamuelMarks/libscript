#!/bin/sh
# ## Overview
# Command-line interface router for ReactOS Build Environment (rosbe).
# Supports target-add (i686-w64-mingw32, x86_64-w64-mingw32) and standard Version Manager verbs.
#
# ## Usage
# ./_lib/toolchains/rosbe/cli.sh <install|ls|ls-remote|use|uninstall|target-add|which|exec> [args]

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

# ## rosbe_target_add
# Registers and stages cross-compilation target support (i686-w64-mingw32 or x86_64-w64-mingw32) idempotently.
rosbe_target_add() {
  _tgt="${1:-}"
  case "$_tgt" in
    i686-w64-mingw32|i386)
      _norm_tgt='i686-w64-mingw32'
      _sub='i386'
      ;;
    x86_64-w64-mingw32|amd64)
      _norm_tgt='x86_64-w64-mingw32'
      _sub='amd64'
      ;;
    *)
      printf '[ERROR] Unsupported RosBE target "%s" (expected i686-w64-mingw32 or x86_64-w64-mingw32).\n' "$_tgt" >&2
      return 1
      ;;
  esac
  _ver="${ROSBE_VERSION:-${LIBSCRIPT_ROSBE_VERSION:-2.2.1}}"
  [ "$_ver" = 'latest' ] && _ver='2.2.1'
  _inst_dir="${LIBSCRIPT_ROSBE_INSTALL_DIR:-${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/rosbe/${_ver}}"
  if [ ! -d "$_inst_dir" ]; then
    ACTION='install' "${SCRIPT_DIR}/setup_generic.sh" >/dev/null
  fi
  mkdir -p "${_inst_dir}/${_sub}/bin"
  if [ -f "${_inst_dir}/targets.list" ] && grep -qx "$_norm_tgt" "${_inst_dir}/targets.list" 2>/dev/null; then
    printf '[SKIP] RosBE target %s already enabled.\n' "$_norm_tgt"
    return 0
  fi
  printf '%s\n' "$_norm_tgt" >> "${_inst_dir}/targets.list"
  printf '[OK] Enabled RosBE target %s.\n' "$_norm_tgt"
}

if [ "${1:-}" = 'target-add' ]; then
  shift
  rosbe_target_add "${1:-}"
  exit $?
fi

: "${PACKAGE_NAME:=$(basename "$SCRIPT_DIR")}"
SCRIPT_NAME="${SCRIPT_DIR}/../../_common/component_core.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"
