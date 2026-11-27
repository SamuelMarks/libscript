#!/bin/sh
# ## Overview
# Validates or lowers DOS .BAT scripts for legacy COMMAND.COM and FreeCOM compatibility
# using wincheck --dialect dos622 (win-cmd-rs) with deterministic POSIX fallback rules.
# ## Usage
# ./engine/common/dos_batch_lint.sh [--mode=lint|rewrite] <file.bat> [...]
set -feu
_dbl_caller_this="${THIS_FILE:-}"; _dbl_caller_dir="${SCRIPT_DIR:-}"; _dbl_was_sourced=0
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"; _dbl_was_sourced=1
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"; [ "${THIS_FILE}" != "${0}" ] && _dbl_was_sourced=1
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"; [ "${THIS_FILE}" != "${0}" ] && _dbl_was_sourced=1
else
  THIS_FILE="${0}"
fi
case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    [ -n "$_dbl_caller_this" ] && THIS_FILE="$_dbl_caller_this"
    [ -n "$_dbl_caller_dir" ] && SCRIPT_DIR="$_dbl_caller_dir"
    unset SCRIPT_NAME _dbl_caller_this _dbl_caller_dir _dbl_was_sourced || true; if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

# ## show_dos_lint_help
# Prints CLI usage for dos_batch_lint.sh.
show_dos_lint_help() {
  printf '%s\n' "Usage: ${THIS_FILE} [--mode=lint|rewrite] <file.bat> [...]"
  printf '%s\n' 'Validates or lowers DOS batch files for COMMAND.COM / FreeCOM (CMD5004, CMD5006).'
}

# ## resolve_wincheck_bin
# Resolves an installed wincheck executable if present on PATH or inside LIBSCRIPT_HOME.
resolve_wincheck_bin() {
  if command -v wincheck >/dev/null 2>&1; then
    command -v wincheck
    return 0
  fi
  _ls_home="${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}"
  if [ -x "${_ls_home}/bin/wincheck" ]; then
    printf '%s\n' "${_ls_home}/bin/wincheck"
    return 0
  fi
  if [ -x "${_ls_home}/win-cmd-rs/default/bin/wincheck" ]; then
    printf '%s\n' "${_ls_home}/win-cmd-rs/default/bin/wincheck"
    return 0
  fi
  return 1
}

# ## rewrite_dos622_file
# Lowers GOTO :EOF (CMD5006) and unquoted & command chains (CMD5004) into CRLF DOS batch syntax.
rewrite_dos622_file() {
  _rdf_file="$1"
  _rdf_tmp="${_rdf_file}.dos622.$$"
  tr -d '\r' < "${_rdf_file}" | awk '
    BEGIN { need_eof = 0; has_eof = 0 }
    /^[[:space:]]*:[Ee][Oo][Ff][[:space:]]*$/ { has_eof = 1 }
    {
      line = $0
      if (line ~ /[Gg][Oo][Tt][Oo][[:space:]]+:[Ee][Oo][Ff]/) {
        gsub(/[Gg][Oo][Tt][Oo][[:space:]]+:[Ee][Oo][Ff]/, "GOTO EOF", line)
        need_eof = 1
      }
      if (line !~ /^[[:space:]]*(::|[Rr][Ee][Mm][[:space:]])/ && line !~ /"/) {
        n = split(line, parts, /[[:space:]]+&[[:space:]]+/)
        for (i = 1; i <= n; i++) {
          printf "%s\r\n", parts[i]
        }
      } else {
        printf "%s\r\n", line
      }
    }
    END {
      if (need_eof && !has_eof) {
        printf ":EOF\r\n"
      }
    }
  ' > "${_rdf_tmp}"
  mv "${_rdf_tmp}" "${_rdf_file}"
}

# ## lint_dos622_file
# Statically checks a DOS .BAT file for NT-only GOTO :EOF and unquoted & chains.
lint_dos622_file() {
  _ldf_file="$1"
  _ldf_wc="$2"
  if [ -n "${_ldf_wc}" ] && "${_ldf_wc}" --help 2>&1 | grep -q 'dialect'; then
    "${_ldf_wc}" --dialect dos622 --severity warning --exclude CMD2013 "${_ldf_file}"
    return $?
  fi
  _ldf_errs=0
  if tr -d '\r' < "${_ldf_file}" | grep -Eq '[Gg][Oo][Tt][Oo][[:space:]]+:[Ee][Oo][Ff]'; then
    printf '[DOS622 LINT] [CMD5006] %s: GOTO :EOF is unsupported by legacy COMMAND.COM (use GOTO EOF + :EOF).\n' "${_ldf_file}" >&2
    _ldf_errs=$((_ldf_errs + 1))
  fi
  if tr -d '\r' < "${_ldf_file}" | grep -Ev '^[[:space:]]*(::|[Rr][Ee][Mm][[:space:]])' | grep -v '"' | grep -Eq '[[:space:]]+&[[:space:]]+'; then
    printf '[DOS622 LINT] [CMD5004] %s: Unquoted & command separator is unsupported by legacy COMMAND.COM.\n' "${_ldf_file}" >&2
    _ldf_errs=$((_ldf_errs + 1))
  fi
  [ "${_ldf_errs}" -eq 0 ]
}

if [ "${_dbl_was_sourced}" = '1' ]; then
  STACK="${STACK%"${THIS_FILE}":}"
  export STACK
  [ -n "${_dbl_caller_dir:-}" ] && SCRIPT_DIR="${_dbl_caller_dir}"
  [ -n "${_dbl_caller_this:-}" ] && THIS_FILE="${_dbl_caller_this}"
  unset SCRIPT_NAME _dbl_caller_this _dbl_caller_dir _dbl_was_sourced || true
  return 0
fi
unset _dbl_was_sourced _dbl_caller_this _dbl_caller_dir || true

LINT_MODE='lint'
while [ "$#" -gt 0 ]; do
  case "$1" in
    --help|-h|'/?'|'-?')
      show_dos_lint_help
      exit 0
      ;;
    --mode=*)
      LINT_MODE="${1#*=}"
      shift
      ;;
    --rewrite)
      LINT_MODE='rewrite'
      shift
      ;;
    --)
      shift
      break
      ;;
    *)
      break
      ;;
  esac
done

if [ "$#" -eq 0 ]; then
  show_dos_lint_help >&2
  exit 1
fi

WC_BIN=$(resolve_wincheck_bin || true)
OVERALL_RC=0
for TARGET_BAT in "$@"; do
  if [ ! -f "${TARGET_BAT}" ]; then
    printf '[ERROR] Batch file not found: %s\n' "${TARGET_BAT}" >&2
    OVERALL_RC=1
    continue
  fi
  if [ "${LINT_MODE}" = 'rewrite' ]; then
    rewrite_dos622_file "${TARGET_BAT}"
  else
    if ! lint_dos622_file "${TARGET_BAT}" "${WC_BIN}"; then
      OVERALL_RC=1
    fi
  fi
done
exit "${OVERALL_RC}"
