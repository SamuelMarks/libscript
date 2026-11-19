#!/bin/sh
# ## Overview
# Resolves or compiles cached zero-dependency C89 helpers (`ls-daemon`, `ls-elevate`, `ls-pe-arch`).
# ## Usage
# . "${LIBSCRIPT_ROOT_DIR}/_lib/_common/win32/build_helper.sh"; libscript_resolve_c_helper ls-pe-arch

set -feu
_wbh_caller_this="${THIS_FILE:-}"; _wbh_caller_dir="${SCRIPT_DIR:-}"

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
    [ "${LIBSCRIPT_DEBUG:-0}" = '1' ] && printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    [ -n "$_wbh_caller_this" ] && THIS_FILE="$_wbh_caller_this"; [ -n "$_wbh_caller_dir" ] && SCRIPT_DIR="$_wbh_caller_dir"
    unset SCRIPT_NAME || true; if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) [ "${LIBSCRIPT_DEBUG:-0}" = '1' ] && printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

# ## libscript_resolve_c_helper
# Prints the path to a prebuilt or freshly compiled C89 helper binary (`ls-daemon`, `ls-elevate`, `ls-pe-arch`).
libscript_resolve_c_helper() {
  _lrh_name="$1"
  case "$_lrh_name" in
    ls-daemon) _lrh_src="ls_daemon.c" ;;
    ls-elevate) _lrh_src="ls_elevate.c" ;;
    ls-pe-arch) _lrh_src="ls_pe_arch.c" ;;
    *) return 1 ;;
  esac
  if command -v "$_lrh_name" >/dev/null 2>&1; then
    command -v "$_lrh_name"
    return 0
  fi
  _lrh_home="${LIBSCRIPT_HOME:-${TMPDIR:-/tmp}/libscript_c_helpers}"
  _lrh_out="${_lrh_home}/bin/${_lrh_name}"
  if [ -x "$_lrh_out" ]; then
    printf '%s\n' "$_lrh_out"
    return 0
  fi
  _lrh_c_path="${LIBSCRIPT_ROOT_DIR}/_lib/_common/win32/${_lrh_src}"
  [ -f "$_lrh_c_path" ] || return 1
  _lrh_cc=""
  for _cand in "${CC:-}" cc clang gcc tcc; do
    [ -n "$_cand" ] || continue
    if command -v "$_cand" >/dev/null 2>&1; then
      _lrh_cc="$_cand"
      break
    fi
  done
  [ -n "$_lrh_cc" ] || return 1
  mkdir -p "${_lrh_home}/bin"
  _lrh_tmp="${_lrh_out}.tmp.$$"
  if "$_lrh_cc" -std=c89 -O2 "$_lrh_c_path" -o "$_lrh_tmp" >/dev/null 2>&1; then
    chmod +x "$_lrh_tmp" 2>/dev/null || true
    mv -f "$_lrh_tmp" "$_lrh_out"
    printf '%s\n' "$_lrh_out"
    return 0
  fi
  rm -f "$_lrh_tmp" 2>/dev/null || true
  return 1
}

case "$(basename -- "${0}")" in
  build_helper.sh)
    if [ "${1:-}" = ":resolve_helper" ] || [ "${1:-}" = "resolve_helper" ]; then
      shift
    fi
    if [ $# -ge 1 ]; then
      libscript_resolve_c_helper "$1"
      exit $?
    fi
    ;;
esac

STACK="${STACK%"${THIS_FILE}":}"
export STACK
[ -n "${_wbh_caller_dir:-}" ] && SCRIPT_DIR="$_wbh_caller_dir"
[ -n "${_wbh_caller_this:-}" ] && THIS_FILE="$_wbh_caller_this"
unset SCRIPT_NAME _wbh_caller_this _wbh_caller_dir || true
