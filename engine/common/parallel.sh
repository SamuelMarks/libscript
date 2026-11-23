#!/bin/sh
# ## Overview
# Tier 0 (`T0`) pure POSIX `/bin/sh` parallel worker pool and static sharding engine (`parallel.sh`),
# auto-detecting CPU cores via `hw_tune.sh`, honoring `LIBSCRIPT_JOBS`, and gracefully falling back to
# sequential execution (`1`) on single-tasking MS-DOS (`IS_MSDOS=1`) or shells without background jobs.
# ## Usage
# SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/engine/common/parallel.sh" . "${LIBSCRIPT_ROOT_DIR}/engine/common/parallel.sh"
set -feu
_parallel_caller_this="${THIS_FILE:-}"; _parallel_caller_dir="${SCRIPT_DIR:-}"
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
    if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2; fi
    [ -n "${_parallel_caller_this:-}" ] && THIS_FILE="$_parallel_caller_this"
    [ -n "${_parallel_caller_dir:-}" ] && SCRIPT_DIR="$_parallel_caller_dir"
    unset SCRIPT_NAME || true; if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2; fi ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

_LSP_TMP_SEQ=0

# ## libscript_make_tmpdir
# Creates an isolated temporary directory using atomic POSIX mkdir without requiring mktemp, using 8.3 names on MS-DOS.
libscript_make_tmpdir() {
  _lmt_pfx="${1:-lsp}"
  _lmt_base="${TMPDIR:-${TEMP:-/tmp}}"
  mkdir -p "$_lmt_base"
  _LSP_TMP_SEQ=$((_LSP_TMP_SEQ + 1))
  _lmt_try=0
  while :; do
    _lmt_try=$((_lmt_try + 1))
    if [ "${IS_MSDOS:-0}" = '1' ] || [ "${LIBSCRIPT_DOS_83:-0}" = '1' ]; then
      _lmt_cand="${_lmt_base}/LSP${_LSP_TMP_SEQ}${_lmt_try}.TMP"
    else
      _lmt_cand="${_lmt_base}/${_lmt_pfx}_${$}_${_LSP_TMP_SEQ}_${_lmt_try}"
    fi
    if ! mkdir "$_lmt_cand" 2>/dev/null; then
      :
    else
      printf '%s\n' "$_lmt_cand"
      return 0
    fi
    if [ "$_lmt_try" -ge 256 ]; then
      printf '%s\n' '[ERROR] [PARALLEL] Failed to allocate temporary directory.' >&2
      return 1
    fi
  done
}

# ## libscript_parallel_jobs
# Resolves worker concurrency from LIBSCRIPT_JOBS or hw_tune.sh CPU detection, falling back to 1 on MS-DOS or non-forking shells.
libscript_parallel_jobs() {
  if [ "${IS_MSDOS:-0}" = '1' ] || [ "${LIBSCRIPT_DOS_83:-0}" = '1' ]; then
    LIBSCRIPT_RESOLVED_JOBS=1
    export LIBSCRIPT_RESOLVED_JOBS
    printf '%s\n' '1'
    return 0
  fi

  case "${UNAME:-}" in
    MS-DOS*|DOS*|FreeDOS*|DJGPP*)
      LIBSCRIPT_RESOLVED_JOBS=1
      export LIBSCRIPT_RESOLVED_JOBS
      printf '%s\n' '1'
      return 0
      ;;
  esac

  _lpj_explicit=0
  _lpj_n=0
  if [ -n "${LIBSCRIPT_JOBS:-}" ]; then
    case "$LIBSCRIPT_JOBS" in
      ''|*[!0-9]*)
        _lpj_n=0
        ;;
      *)
        if [ "$LIBSCRIPT_JOBS" -ge 1 ] 2>/dev/null; then
          _lpj_n="$LIBSCRIPT_JOBS"
          _lpj_explicit=1
        fi
        ;;
    esac
  fi

  if [ "$_lpj_n" -lt 1 ]; then
    if [ -z "${LIBSCRIPT_HW_CORES:-}" ]; then
      if [ -f "${LIBSCRIPT_ROOT_DIR}/engine/common/hw_tune.sh" ]; then
        _lpj_saved_this="${THIS_FILE:-}"
        _lpj_saved_dir="${SCRIPT_DIR:-}"
        _lpj_saved_stack="${STACK:-}"
        SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/engine/common/hw_tune.sh"
        export SCRIPT_NAME
        # shellcheck disable=SC1090,SC1091
        . "${SCRIPT_NAME}"
        unset SCRIPT_NAME || true
        if command -v libscript_detect_hardware >/dev/null 2>&1; then
          libscript_detect_hardware
        fi
        THIS_FILE="$_lpj_saved_this"
        SCRIPT_DIR="$_lpj_saved_dir"
        STACK="$_lpj_saved_stack"
        export STACK
        unset _lpj_saved_this _lpj_saved_dir _lpj_saved_stack || true
      fi
    fi
    _lpj_n="${LIBSCRIPT_HW_CORES:-4}"
    case "$_lpj_n" in
      ''|*[!0-9]*) _lpj_n=4 ;;
    esac
    if [ "$_lpj_n" -lt 1 ]; then
      _lpj_n=1
    fi
    if [ "$_lpj_explicit" -eq 0 ] && [ "$_lpj_n" -gt 16 ]; then
      _lpj_n=16
    fi
  fi

  if [ "$_lpj_n" -gt 1 ]; then
    if [ -z "${LIBSCRIPT_BG_SUPPORTED:-}" ]; then
      if ( : >/dev/null 2>&1 & wait "$!" ) 2>/dev/null; then
        LIBSCRIPT_BG_SUPPORTED=1
      else
        LIBSCRIPT_BG_SUPPORTED=0
      fi
      export LIBSCRIPT_BG_SUPPORTED
    fi
    if [ "$LIBSCRIPT_BG_SUPPORTED" != '1' ]; then
      _lpj_n=1
    fi
  fi

  LIBSCRIPT_RESOLVED_JOBS="$_lpj_n"
  export LIBSCRIPT_RESOLVED_JOBS
  printf '%s\n' "$_lpj_n"
}

# ## libscript_parallel_shards
# Splits non-empty lines of input_list_file into static worker shards and invokes worker_fn concurrently with live output streaming.
libscript_parallel_shards() {
  _lps_list="$1"
  _lps_worker="$2"
  _lps_cap="${3:-}"

  if [ ! -s "$_lps_list" ]; then
    return 0
  fi

  _lps_total=$(awk 'NF > 0 { c++ } END { print c + 0 }' "$_lps_list")
  if [ "$_lps_total" -le 0 ]; then
    return 0
  fi

  _lps_jobs=$(libscript_parallel_jobs)
  if [ -n "$_lps_cap" ]; then
    case "$_lps_cap" in
      ''|*[!0-9]*) ;;
      *)
        if [ "$_lps_cap" -ge 1 ] && [ "$_lps_cap" -lt "$_lps_jobs" ]; then
          _lps_jobs="$_lps_cap"
        fi
        ;;
    esac
  fi

  if [ "$_lps_total" -lt "$_lps_jobs" ]; then
    _lps_jobs="$_lps_total"
  fi

  if [ "$_lps_jobs" -le 1 ]; then
    "$_lps_worker" "$_lps_list"
    return $?
  fi

  _lps_dir=$(libscript_make_tmpdir 'shards')
  LPS_DIR="$_lps_dir" awk -v n="$_lps_jobs" '
    BEGIN {
      d = ENVIRON["LPS_DIR"]
      gsub(/\\/, "/", d)
    }
    NF > 0 {
      idx = (c % n) + 1
      c++
      out = d "/S" idx ".TXT"
      print $0 >> out
      close(out)
    }
  ' "$_lps_list"

  _lps_pids=''
  _lps_i=1
  while [ "$_lps_i" -le "$_lps_jobs" ]; do
    _lps_sf="${_lps_dir}/S${_lps_i}.TXT"
    if [ -s "$_lps_sf" ]; then
      ( "$_lps_worker" "$_lps_sf" ) &
      _lps_pids="${_lps_pids} $!"
    fi
    _lps_i=$((_lps_i + 1))
  done

  _lps_rc=0
  for _lps_pid in $_lps_pids; do
    if ! wait "$_lps_pid"; then
      _lps_rc=1
    fi
  done

  rm -rf "$_lps_dir"
  return "$_lps_rc"
}

# ## _libscript_map_shard_worker
# Internal worker invoking LIBSCRIPT_MAP_FN once per non-empty line in a shard file.
_libscript_map_shard_worker() {
  _lms_shard="$1"
  _lms_rc=0
  while IFS= read -r _lms_item || [ -n "$_lms_item" ]; do
    [ -n "$_lms_item" ] || continue
    if ! "$LIBSCRIPT_MAP_FN" "$_lms_item"; then
      _lms_rc=1
    fi
  done < "$_lms_shard"
  return "$_lms_rc"
}

# ## libscript_parallel_map
# Executes item_fn concurrently across non-empty items in items_file up to max_jobs workers without eval.
libscript_parallel_map() {
  _lpm_file="$1"
  _lpm_fn="$2"
  _lpm_cap="${3:-}"
  _lpm_prev_fn="${LIBSCRIPT_MAP_FN:-}"
  LIBSCRIPT_MAP_FN="$_lpm_fn"
  if libscript_parallel_shards "$_lpm_file" _libscript_map_shard_worker "$_lpm_cap"; then
    _lpm_rc=0
  else
    _lpm_rc=1
  fi
  LIBSCRIPT_MAP_FN="$_lpm_prev_fn"
  return "$_lpm_rc"
}

# ## libscript_batch_exec
# Invokes batch_fn with chunks of up to batch_size arguments read safely from list_file without xargs -0 or arrays.
libscript_batch_exec() {
  _lbe_list="$1"
  _lbe_sz="$2"
  _lbe_fn="$3"

  if [ ! -s "$_lbe_list" ]; then
    return 0
  fi

  _lbe_had_noglob=0
  case "$-" in *f*) _lbe_had_noglob=1 ;; esac
  set -f

  set --
  _lbe_cnt=0
  _lbe_rc=0
  while IFS= read -r _lbe_item || [ -n "$_lbe_item" ]; do
    [ -n "$_lbe_item" ] || continue
    set -- "$@" "$_lbe_item"
    _lbe_cnt=$((_lbe_cnt + 1))
    if [ "$_lbe_cnt" -ge "$_lbe_sz" ]; then
      if ! "$_lbe_fn" "$@"; then
        _lbe_rc=1
      fi
      set --
      _lbe_cnt=0
    fi
  done < "$_lbe_list"

  if [ "$_lbe_cnt" -gt 0 ]; then
    if ! "$_lbe_fn" "$@"; then
      _lbe_rc=1
    fi
  fi

  if [ "$_lbe_had_noglob" -eq 0 ]; then
    set +f
  fi
  return "$_lbe_rc"
}

STACK="${STACK%"${THIS_FILE}":}"
export STACK
[ -n "${_parallel_caller_dir:-}" ] && SCRIPT_DIR="$_parallel_caller_dir"
[ -n "${_parallel_caller_this:-}" ] && THIS_FILE="$_parallel_caller_this"
unset SCRIPT_NAME _parallel_caller_this _parallel_caller_dir || true
