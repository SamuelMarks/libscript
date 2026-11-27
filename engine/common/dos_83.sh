#!/bin/sh
# ## Overview
# MS-DOS FAT16 8.3 filename and path prefix helper (`LIBSCRIPT_DOS_83=1` / `IS_MSDOS=1`), mapping long component names via `dos_83_map.tsv` and defaulting `LIBSCRIPT_HOME` to `C:\LIBSCRIP`.
# ## Usage
# . "${LIBSCRIPT_ROOT_DIR}/engine/common/dos_83.sh"

set -feu
_d83_caller_this="${THIS_FILE:-}"; _d83_caller_dir="${SCRIPT_DIR:-}"; _d83_was_sourced=0
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"; _d83_was_sourced=1
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"; [ "${THIS_FILE}" != "${0}" ] && _d83_was_sourced=1
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"; [ "${THIS_FILE}" != "${0}" ] && _d83_was_sourced=1
else
  THIS_FILE="${0}"
fi
case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    [ "${LIBSCRIPT_DEBUG:-0}" = '1' ] && printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    [ -n "${_d83_caller_dir:-}" ] && SCRIPT_DIR="$_d83_caller_dir"; [ -n "${_d83_caller_this:-}" ] && THIS_FILE="$_d83_caller_this"
    unset SCRIPT_NAME _d83_caller_this _d83_caller_dir _d83_was_sourced || true
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) [ "${LIBSCRIPT_DEBUG:-0}" = '1' ] && printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

# ## libscript_dos83_enabled
# Returns 0 if 8.3 component directory mapping is active (IS_MSDOS=1 or LIBSCRIPT_DOS_83=1, unless LIBSCRIPT_DOS_83=0).
libscript_dos83_enabled() {
  if [ "${LIBSCRIPT_DOS_83:-}" = '0' ]; then
    return 1
  fi
  if [ "${LIBSCRIPT_DOS_83:-0}" = '1' ] || [ "${IS_MSDOS:-0}" = '1' ] || [ "${TARGET_OS:-}" = 'msdos' ]; then
    return 0
  fi
  return 1
}

# ## libscript_dos83_home
# Resolves the default LIBSCRIPT_HOME path, using C:\LIBSCRIP on MS-DOS when unset.
libscript_dos83_home() {
  if [ -n "${LIBSCRIPT_HOME:-}" ]; then
    printf '%s\n' "${LIBSCRIPT_HOME}"
    return 0
  fi
  if [ "${IS_MSDOS:-0}" = '1' ] || [ "${TARGET_OS:-}" = 'msdos' ] || [ "${LIBSCRIPT_DOS_83:-0}" = '1' ]; then
    case "${UNAME:-}" in
      MS-DOS*|DOS*|FreeDOS*|DJGPP*|Windows_NT|MINGW*|MSYS*|CYGWIN*)
        printf '%s\n' 'C:\LIBSCRIP'
        ;;
      *)
        if [ -d 'C:/' ]; then
          printf '%s\n' 'C:/LIBSCRIP'
        else
          printf '%s\n' "${TMPDIR:-/tmp}/LIBSCRIP"
        fi
        ;;
    esac
    return 0
  fi
  printf '%s\n' "${HOME:-/root}/.libscript"
}

# ## libscript_dos83_comp
# Maps a component name to its 8.3 uppercase short directory name via dos_83_map.tsv when MS-DOS / 8.3 mode is active.
libscript_dos83_comp() {
  _d83_in="$1"
  if ! libscript_dos83_enabled; then
    printf '%s\n' "${_d83_in}"
    return 0
  fi
  _d83_tsv="${LIBSCRIPT_ROOT_DIR}/engine/common/dos_83_map.tsv"
  if [ -f "${_d83_tsv}" ]; then
    _d83_hit=$(awk -F '\t' -v key="${_d83_in}" '
      !/^[[:space:]]*(#|$)/ && tolower($1) == tolower(key) { print $2; exit }
    ' "${_d83_tsv}" 2>/dev/null || true)
    if [ -n "${_d83_hit}" ]; then
      printf '%s\n' "${_d83_hit}"
      return 0
    fi
  fi
  _d83_clean=$(printf '%s' "${_d83_in}" | tr '[:lower:]' '[:upper:]' | tr -cd 'A-Z0-9')
  printf '%.8s\n' "${_d83_clean:-COMP}"
}

# ## libscript_dos83_ver
# Normalizes a version directory token to strict FAT16 8.3 rules when LIBSCRIPT_DOS_83=1.
libscript_dos83_ver() {
  _d83_v="$1"
  if [ "${LIBSCRIPT_DOS_83:-0}" != '1' ]; then
    printf '%s\n' "${_d83_v}"
    return 0
  fi
  _d83_v="${_d83_v#v}"
  _d83_san=$(printf '%s' "${_d83_v}" | tr '[:lower:].+-' '[:upper:]___' | tr -cd 'A-Z0-9_')
  printf '%.8s\n' "${_d83_san:-VER}"
}

# ## libscript_dos83_link_compat
# Creates a convenience LFN symlink <home>/<orig_comp> -> <mapped_comp> when cross-staging on LFN hosts without strict LIBSCRIPT_DOS_83=1.
libscript_dos83_link_compat() {
  _d83_h="$1"
  _d83_orig="$2"
  _d83_map="$3"
  if [ "${LIBSCRIPT_DOS_83:-0}" = '1' ] || [ "${_d83_orig}" = "${_d83_map}" ]; then
    return 0
  fi
  if [ -d "${_d83_h}/${_d83_map}" ] && [ ! -e "${_d83_h}/${_d83_orig}" ]; then
    (cd "${_d83_h}" && ln -sf "${_d83_map}" "${_d83_orig}" 2>/dev/null) || true
  fi
}

STACK="${STACK%"${THIS_FILE}":}"
export STACK
[ -n "${_d83_caller_dir:-}" ] && SCRIPT_DIR="$_d83_caller_dir"
[ -n "${_d83_caller_this:-}" ] && THIS_FILE="$_d83_caller_this"
_d83_run_cli=0
[ "${_d83_was_sourced}" = '0' ] && _d83_run_cli=1
unset SCRIPT_NAME _d83_caller_this _d83_caller_dir _d83_was_sourced || true

if [ "${_d83_run_cli}" = '1' ]; then
  unset _d83_run_cli || true
  if [ $# -ge 1 ]; then
    _d83_sub="${1#:}"
    shift
    case "${_d83_sub}" in
      libscript_dos83_home|home) libscript_dos83_home "$@" ;;
      libscript_dos83_comp|comp) libscript_dos83_comp "$@" ;;
      libscript_dos83_ver|ver) libscript_dos83_ver "$@" ;;
      libscript_dos83_enabled|enabled) libscript_dos83_enabled "$@" ;;
      *) exit 1 ;;
    esac
  fi
fi
unset _d83_run_cli || true
