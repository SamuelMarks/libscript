#!/bin/sh
# ## Overview
# Audits Windows Batch (.cmd and .bat) scripts across the repository using the
# cross-platform wincheck static analyzer from _lib/toolchains/win-cmd-rs,
# automatically bootstrapping win-cmd-rs when wincheck is not yet on PATH.
#
# ## Usage
# ./devtools/audit/audit_cmd.sh [--all | --staged | --severity <sev> | --dialect <d> | --format <fmt> | --exclude <rules> | file1.cmd ...]

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

# ## show_help
# Prints command-line usage and supported options for audit_cmd.sh.
show_help() {
  cat <<'EOH'
Usage: ./devtools/audit/audit_cmd.sh [OPTIONS] [FILES...]

Options:
  --all                 Audit all tracked and untracked non-ignored .cmd/.bat files (default).
  --staged              Audit only git-staged (Added/Copied/Modified) .cmd/.bat files.
  --severity <SEV>      Minimum severity threshold: error, warning, info, style (default: style).
  --dialect <DIALECT>   Target batch dialect: cmd, dos622, freedos (default: cmd).
  --format <FMT>        Output format: tty, gcc, json, sarif (default: tty).
  --exclude <RULES>     Comma-separated rule IDs to exclude.
  --include <RULES>     Comma-separated rule IDs to include exclusively.
  -h, --help, /?, -?    Show this help message and exit.
EOH
}

# ## load_wincheck_env
# Sources the isolated win-cmd-rs component environment while preserving caller THIS_FILE, SCRIPT_DIR, and STACK.
load_wincheck_env() {
  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/win-cmd-rs/env.sh" ]; then
    _ac_saved_this="${THIS_FILE:-}"
    _ac_saved_dir="${SCRIPT_DIR:-}"
    _ac_saved_st="${STACK:-}"
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/win-cmd-rs/env.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090,SC1091
    . "${SCRIPT_NAME}"
    unset SCRIPT_NAME || true
    THIS_FILE="${_ac_saved_this}"
    SCRIPT_DIR="${_ac_saved_dir}"
    STACK="${_ac_saved_st}"
    export STACK
    unset _ac_saved_this _ac_saved_dir _ac_saved_st || true
  fi
}

# ## ensure_wincheck_bootstrapped
# Ensures wincheck is available on PATH, installing win-cmd-rs idempotently via libscript.sh when absent.
ensure_wincheck_bootstrapped() {
  load_wincheck_env
  if command -v wincheck >/dev/null 2>&1; then
    return 0
  fi
  printf '%s\n' '[BOOTSTRAP] wincheck not found on PATH; installing via LibScript version manager...'
  if ! (
    unset SCRIPT_NAME || true
    LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB=1 STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install win-cmd-rs "${WIN_CMD_RS_VERSION:-latest}"
  ); then
    printf '%s\n' '[ERROR] Failed to bootstrap win-cmd-rs via ./libscript.sh install win-cmd-rs.' >&2
    exit 1
  fi
  load_wincheck_env
  if ! command -v wincheck >/dev/null 2>&1; then
    printf '%s\n' '[ERROR] wincheck binary still not found on PATH after bootstrap.' >&2
    exit 1
  fi
}

MODE='all'
WC_SEVERITY="${LIBSCRIPT_WINCHECK_SEVERITY:-style}"
WC_DIALECT="${LIBSCRIPT_WINCHECK_DIALECT:-cmd}"
WC_FORMAT="${LIBSCRIPT_WINCHECK_FORMAT:-tty}"
WC_EXCLUDE="${LIBSCRIPT_WINCHECK_EXCLUDE:-CMD1002,CMD2001,CMD2012,CMD2013,CMD3009,CMD4010}"
WC_INCLUDE="${LIBSCRIPT_WINCHECK_INCLUDE:-}"

EXPLICIT_LIST=$(mktemp "${TMPDIR:-/tmp}/audit_cmd_explicit.XXXXXX")
CANDIDATE_LIST=$(mktemp "${TMPDIR:-/tmp}/audit_cmd_candidates.XXXXXX")
trap 'rm -f "${EXPLICIT_LIST}" "${CANDIDATE_LIST}"' EXIT INT TERM

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help|'/?'|'-?')
      show_help
      exit 0
      ;;
    --all)
      MODE='all'
      shift
      ;;
    --staged)
      MODE='staged'
      shift
      ;;
    -S|--severity)
      WC_SEVERITY="$2"
      shift 2
      ;;
    --severity=*)
      WC_SEVERITY="${1#*=}"
      shift
      ;;
    --dialect)
      WC_DIALECT="$2"
      shift 2
      ;;
    --dialect=*)
      WC_DIALECT="${1#*=}"
      shift
      ;;
    -f|--format)
      WC_FORMAT="$2"
      shift 2
      ;;
    --format=*)
      WC_FORMAT="${1#*=}"
      shift
      ;;
    -e|--exclude)
      WC_EXCLUDE="$2"
      shift 2
      ;;
    --exclude=*)
      WC_EXCLUDE="${1#*=}"
      shift
      ;;
    -i|--include)
      WC_INCLUDE="$2"
      shift 2
      ;;
    --include=*)
      WC_INCLUDE="${1#*=}"
      shift
      ;;
    *)
      MODE='explicit'
      printf '%s\n' "$1" >> "${EXPLICIT_LIST}"
      shift
      ;;
  esac
done

printf '%s\n' '=== LibScript Windows Batch (.cmd / .bat) Static Analysis Audit (wincheck) ==='

case "${MODE}" in
  staged)
    git -C "${LIBSCRIPT_ROOT_DIR}" diff --no-ext-diff --cached --name-only --diff-filter=ACM -- '*.cmd' '*.bat' | while IFS= read -r _rel || [ -n "${_rel}" ]; do
      [ -n "${_rel}" ] || continue
      case "${_rel}" in
        node_modules/*|*/node_modules/*|.git/*|*/.git/*|gen/*|*/gen/*|tests_tmp/*|*/tests_tmp/*|cache/*|*/cache/*|build/*|*/build/*) continue ;;
      esac
      if [ -f "${LIBSCRIPT_ROOT_DIR}/${_rel}" ]; then
        printf '%s\n' "${LIBSCRIPT_ROOT_DIR}/${_rel}"
      fi
    done > "${CANDIDATE_LIST}"
    ;;
  explicit)
    while IFS= read -r _in_p || [ -n "${_in_p}" ]; do
      [ -n "${_in_p}" ] || continue
      case "${_in_p}" in
        *.cmd|*.bat|*.CMD|*.BAT)
          if [ -f "${_in_p}" ]; then
            printf '%s\n' "${_in_p}"
          elif [ -f "${LIBSCRIPT_ROOT_DIR}/${_in_p}" ]; then
            printf '%s\n' "${LIBSCRIPT_ROOT_DIR}/${_in_p}"
          fi
          ;;
      esac
    done < "${EXPLICIT_LIST}" > "${CANDIDATE_LIST}"
    ;;
  *)
    git -C "${LIBSCRIPT_ROOT_DIR}" ls-files --cached --others --exclude-standard -- '*.cmd' '*.bat' | while IFS= read -r _rel || [ -n "${_rel}" ]; do
      [ -n "${_rel}" ] || continue
      case "${_rel}" in
        node_modules/*|*/node_modules/*|.git/*|*/.git/*|gen/*|*/gen/*|tests_tmp/*|*/tests_tmp/*|cache/*|*/cache/*|build/*|*/build/*) continue ;;
      esac
      if [ -f "${LIBSCRIPT_ROOT_DIR}/${_rel}" ]; then
        printf '%s\n' "${LIBSCRIPT_ROOT_DIR}/${_rel}"
      fi
    done > "${CANDIDATE_LIST}"
    ;;
esac

if [ ! -s "${CANDIDATE_LIST}" ]; then
  printf '%s\n' '[PASS] No .cmd or .bat scripts matched for auditing.'
  exit 0
fi

ensure_wincheck_bootstrapped

set -- --severity "${WC_SEVERITY}" --dialect "${WC_DIALECT}" --format "${WC_FORMAT}"
if [ -n "${WC_EXCLUDE}" ]; then
  set -- "$@" --exclude "${WC_EXCLUDE}"
fi
if [ -n "${WC_INCLUDE}" ]; then
  set -- "$@" --include "${WC_INCLUDE}"
fi

tr '\n' '\0' < "${CANDIDATE_LIST}" | xargs -0 -n 80 -P 4 wincheck "$@"
printf '%s\n' '[PASS] All audited Windows Batch (.cmd / .bat) scripts pass wincheck static analysis.'
