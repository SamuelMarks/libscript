#!/bin/sh
# ## Overview
# Compiles and caches C89 MS-DOS (`dos32`) helpers (`ls-wincmd`, `ls-dash-dos`, `ls-watt-curl`, `ls-mkdos-smoke`) via OpenWatcom `wcl386` or host C89 compilers.
# ## Usage
# ./engine/common/dos32/build_dos32.sh <ls-wincmd|ls-dash-dos|ls-watt-curl|ls-mkdos-smoke> [--target=host|dos32] [--out=<path>]

set -feu
_bd_caller_this="${THIS_FILE-}"; _bd_caller_dir="${SCRIPT_DIR-}"
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
    [ -n "${_bd_caller_dir:-}" ] && SCRIPT_DIR="$_bd_caller_dir"; [ -n "${_bd_caller_this:-}" ] && THIS_FILE="$_bd_caller_this"
    unset SCRIPT_NAME _bd_caller_this _bd_caller_dir || true
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) [ "${LIBSCRIPT_DEBUG:-0}" = '1' ] && printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

# ## libscript_build_dos32_tool
# Resolves or compiles ls-wincmd, ls-dash-dos, or ls-watt-curl for dos32 (wcl386) or host C89.
libscript_build_dos32_tool() {
  _tool="$1"
  shift
  _target='host'
  _out=''
  while [ $# -gt 0 ]; do
    case "$1" in
      --target=*) _target="${1#*=}" ;;
      --target) shift; _target="${1:-host}" ;;
      --out=*) _out="${1#*=}" ;;
      --out) shift; _out="${1:-}" ;;
    esac
    shift
  done

  case "${_tool}" in
    ls-wincmd|wincmd)
      _src="${LIBSCRIPT_ROOT_DIR}/engine/common/dos32/ls_wincmd.c"
      _dos_name='WINCMD.EXE'
      _host_name='LSWINCMD'
      ;;
    ls-dash-dos|dash-dos|sh-dos)
      _src="${LIBSCRIPT_ROOT_DIR}/engine/common/dos32/ls_dash_dos.c"
      _dos_name='DASH.EXE'
      _host_name='LSDASHD'
      ;;
    ls-watt-curl|watt-curl|curl-dos)
      _src="${LIBSCRIPT_ROOT_DIR}/engine/common/dos32/ls_watt_curl.c"
      _dos_name='CURL.EXE'
      _host_name='LSWCURL'
      ;;
    ls-mkdos-smoke|mkdos-smoke)
      _src="${LIBSCRIPT_ROOT_DIR}/engine/common/dos32/ls_mkdos_smoke_img.c"
      _dos_name='MKDOSSMK.EXE'
      _host_name='LSMKDOSS'
      ;;
    *)
      printf '[ERROR] Unknown dos32 helper: %s\n' "${_tool}" >&2
      return 1
      ;;
  esac

  [ -f "${_src}" ] || return 1
  _cache_dir="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/DOS32HLP"
  mkdir -p "${_cache_dir}"

  if [ "${_target}" = 'dos32' ]; then
    [ -z "${_out}" ] && _out="${_cache_dir}/${_dos_name}"
    if [ -s "${_out}" ] && [ "${_out}" -nt "${_src}" ]; then
      printf '%s\n' "${_out}"
      return 0
    fi
    _wcl=''
    if command -v wcl386 >/dev/null 2>&1; then
      _wcl='wcl386'
    elif [ -n "${WATCOM:-}" ] && [ -x "${WATCOM}/binl/wcl386" ]; then
      _wcl="${WATCOM}/binl/wcl386"
    elif [ -n "${WATCOM:-}" ] && [ -x "${WATCOM}/binl64/wcl386" ]; then
      _wcl="${WATCOM}/binl64/wcl386"
    fi
    if [ -n "${_wcl}" ]; then
      _watt_flags=''
      if [ -n "${WATT_ROOT:-}" ] && [ -d "${WATT_ROOT}/inc" ]; then
        _watt_flags="-DUSE_WATT32 -I${WATT_ROOT}/inc"
      fi
      # shellcheck disable=SC2086
      if "${_wcl}" -q -bt=dos -mf -3r -ox ${_watt_flags} -fe="${_out}" "${_src}" >/dev/null 2>&1; then
        printf '%s\n' "${_out}"
        return 0
      fi
    fi
    return 1
  fi

  [ -z "${_out}" ] && _out="${_cache_dir}/${_host_name}"
  if [ -x "${_out}" ] && [ "${_out}" -nt "${_src}" ]; then
    printf '%s\n' "${_out}"
    return 0
  fi

  for _cc in "${CC:-}" cc clang gcc; do
    [ -n "${_cc}" ] || continue
    if command -v "${_cc}" >/dev/null 2>&1; then
      mkdir -p "$(dirname -- "${_out}")"
      if "${_cc}" -std=c89 -O2 -Wall -Wextra -Werror "${_src}" -o "${_out}.tmp.$$"; then
        chmod +x "${_out}.tmp.$$"
        mv -f "${_out}.tmp.$$" "${_out}"
        printf '%s\n' "${_out}"
        return 0
      fi
      rm -f "${_out}.tmp.$$"
    fi
  done
  return 1
}

STACK="${STACK%"${THIS_FILE}":}"
export STACK
[ -n "${_bd_caller_dir:-}" ] && SCRIPT_DIR="$_bd_caller_dir"
[ -n "${_bd_caller_this:-}" ] && THIS_FILE="$_bd_caller_this"
unset SCRIPT_NAME _bd_caller_this _bd_caller_dir || true

if ! (return 0 2>/dev/null); then
  libscript_build_dos32_tool "$@"
fi
