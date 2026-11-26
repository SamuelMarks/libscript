#!/bin/sh
# ## Overview
# Audits Windows Batch (.cmd and .bat) scripts across the repository using the
# cross-platform wincheck static analyzer from _lib/toolchains/win-cmd-rs,
# automatically bootstrapping win-cmd-rs when wincheck is missing from PATH.
# ## Usage
# ./devtools/audit/audit_cmd.sh [--all | --staged | <file>...]
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

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/engine/common/parallel.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true

# ## show_help
# Prints usage instructions and supported wincheck flags.
show_help() {
  cat <<'EOH'
Usage: ./devtools/audit/audit_cmd.sh [--all | --staged | <file>...] [options]

Audits Windows Batch (.cmd and .bat) scripts using wincheck (_lib/toolchains/win-cmd-rs).

Options:
  --all                 Audit all tracked .cmd and .bat scripts (default).
  --staged              Audit only git-staged .cmd and .bat scripts.
  --severity <level>    Minimum severity: error, warning, info, style (default: warning).
  --dialect <dialect>   Target dialect: cmd, win9x, dos (default: cmd).
  --format <fmt>        Output format: text, json, sarif (default: text).
  --exclude <rules>     Comma-separated rule IDs to suppress (default: CMD1002,CMD2001,CMD2012,CMD2013,CMD3009,CMD4010).
  --include <rules>     Comma-separated rule IDs to include exclusively.
  -h, --help, /?, -?    Show this help message and exit.
EOH
}

# ## load_wincheck_env
# Sources _lib/toolchains/win-cmd-rs/env.sh while preserving caller THIS_FILE and STACK.
load_wincheck_env() {
  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/win-cmd-rs/env.sh" ]; then
    _ac_saved_this="${THIS_FILE}"
    _ac_saved_dir="${SCRIPT_DIR}"
    _ac_saved_stack="${STACK}"
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/toolchains/win-cmd-rs/env.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090,SC1091
    . "${SCRIPT_NAME}" >/dev/null 2>&1 || true
    unset SCRIPT_NAME || true
    THIS_FILE="${_ac_saved_this}"
    SCRIPT_DIR="${_ac_saved_dir}"
    STACK="${_ac_saved_stack}"
    export STACK
    unset _ac_saved_this _ac_saved_dir _ac_saved_stack || true
  fi
}

# ## ensure_wincheck_bootstrapped
# Ensures wincheck is available on PATH, auto-installing via LibScript win-cmd-rs if missing.
ensure_wincheck_bootstrapped() {
  load_wincheck_env
  if command -v wincheck >/dev/null 2>&1; then
    return 0
  fi
  printf '%s\n' '[BOOTSTRAP] wincheck not found on PATH; installing via LibScript win-cmd-rs component...' >&2
  if ! STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install win-cmd-rs "${WIN_CMD_RS_VERSION:-latest}"; then
    printf '%s\n' '[ERROR] Failed to bootstrap wincheck via LibScript win-cmd-rs.' >&2
    return 1
  fi
  load_wincheck_env
  if ! command -v wincheck >/dev/null 2>&1; then
    printf '%s\n' '[ERROR] wincheck binary still missing on PATH after win-cmd-rs bootstrap.' >&2
    return 1
  fi
  return 0
}

MODE='all'
WC_SEVERITY="${LIBSCRIPT_WINCHECK_SEVERITY:-style}"
WC_DIALECT="${LIBSCRIPT_WINCHECK_DIALECT:-cmd}"
WC_FORMAT="${LIBSCRIPT_WINCHECK_FORMAT:-tty}"
WC_EXCLUDE="${LIBSCRIPT_WINCHECK_EXCLUDE:-CMD1002,CMD2001,CMD2012,CMD2013,CMD3009,CMD4010}"
WC_INCLUDE="${LIBSCRIPT_WINCHECK_INCLUDE:-}" 
AC_WORK=$(libscript_make_tmpdir 'batch')
EXPLICIT_LIST="${AC_WORK}/EXPLICIT.TXT"
CANDIDATE_LIST="${AC_WORK}/CANDIDATES.TXT"
: > "${EXPLICIT_LIST}"
: > "${CANDIDATE_LIST}"
trap 'rm -rf "${AC_WORK}"' EXIT INT TERM

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
    -s|--severity)
      WC_SEVERITY="$2"
      shift 2
      ;;
    --severity=*)
      WC_SEVERITY="${1#*=}"
      shift
      ;;
    -d|--dialect)
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
    _del_list="${AC_WORK}/DELETED.TXT"
    git -C "${LIBSCRIPT_ROOT_DIR}" ls-files --deleted -- '*.cmd' '*.bat' > "${_del_list}" 2>/dev/null || : > "${_del_list}"
    git -C "${LIBSCRIPT_ROOT_DIR}" ls-files --cached --others --exclude-standard -- '*.cmd' '*.bat' \
      | awk -v root="${LIBSCRIPT_ROOT_DIR}/" -v del_f="${_del_list}" '
        BEGIN {
          while ((getline d < del_f) > 0) del[d] = 1
          close(del_f)
        }
        NF == 0 { next }
        $0 in del { next }
        $0 ~ /(^|\/)(node_modules|\.git|gen|tests_tmp|cache|build)\// { next }
        { print root $0 }
      ' > "${CANDIDATE_LIST}"
    ;;
esac

if [ ! -s "${CANDIDATE_LIST}" ]; then
  printf '%s\n' '[PASS] No .cmd or .bat scripts matched for auditing.'
  exit 0
fi

ensure_wincheck_bootstrapped

# shellcheck disable=SC2329
# ## _run_wincheck_chunk
# Invokes wincheck on a single batch of .cmd/.bat file paths.
_run_wincheck_chunk() {
  if [ -n "${WC_EXCLUDE}" ] && [ -n "${WC_INCLUDE}" ]; then
    wincheck --severity "${WC_SEVERITY}" --dialect "${WC_DIALECT}" --format "${WC_FORMAT}" --exclude "${WC_EXCLUDE}" --include "${WC_INCLUDE}" "$@"
  elif [ -n "${WC_EXCLUDE}" ]; then
    wincheck --severity "${WC_SEVERITY}" --dialect "${WC_DIALECT}" --format "${WC_FORMAT}" --exclude "${WC_EXCLUDE}" "$@"
  elif [ -n "${WC_INCLUDE}" ]; then
    wincheck --severity "${WC_SEVERITY}" --dialect "${WC_DIALECT}" --format "${WC_FORMAT}" --include "${WC_INCLUDE}" "$@"
  else
    wincheck --severity "${WC_SEVERITY}" --dialect "${WC_DIALECT}" --format "${WC_FORMAT}" "$@"
  fi
  _wc_long=$(wincheck --dialect "${WC_DIALECT}" --format tty --include CMD1002 "$@" 2>&1 | grep 'The input line is too long' || true)
  if [ -n "${_wc_long}" ]; then
    printf '%s\n' "${_wc_long}" >&2
    return 1
  fi
}

# shellcheck disable=SC2329
# ## _run_wincheck_shard
# Worker processing one shard of .cmd/.bat files in batches of 80.
_run_wincheck_shard() {
  libscript_batch_exec "$1" 80 _run_wincheck_chunk
}

libscript_parallel_shards "${CANDIDATE_LIST}" _run_wincheck_shard
printf '%s\n' '[PASS] All audited Windows Batch (.cmd / .bat) scripts pass wincheck static analysis.'
