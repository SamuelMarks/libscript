#!/bin/sh
# ## Overview
# Compiler driver wrapper and telemetry shim for custom-cc. Normalizes/strips
# GCC/Clang-specific flags when CUSTOM_CC_STRIP_GNU_FLAGS is enabled and logs
# per-translation-unit compilation events to JSONL.
#
# ## Usage
# ./_lib/languages/custom-cc/cc_wrapper.sh [compiler_args...]

set -feu

if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
elif [ "${ZSH_VERSION-}" ]; then
  # libscript-allow-eval
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

# ## filter_compiler_args
# Inspects compiler arguments, identifies the primary source file, and determines whether GNU-specific flags should be stripped.
filter_compiler_args() {
  _src_file=""
  for _arg in "$@"; do
    case "${_arg}" in
      *.c|*.S|*.s|*.cc|*.cpp)
        _src_file="${_arg}"
        ;;
    esac
  done
  WRAPPER_SOURCE_FILE="${_src_file}"
}

# ## record_compile_event
# Appends a structured JSONL telemetry line for a compilation invocation.
record_compile_event() {
  _ev_src="${1:-}"
  _ev_rc="${2:-0}"
  _ev_fallback="${3:-false}"
  _ev_ms="${4:-1}"
  _log_file="${CUSTOM_CC_LOG_FILE:-${LIBSCRIPT_HOME:-$HOME/.libscript}/custom-cc/compile_events.jsonl}"
  _log_dir="$(dirname -- "${_log_file}")"
  mkdir -p "${_log_dir}"
  _safe_src=$(printf '%s' "${_ev_src}" | tr '"' "'" | tr -d '
')
  printf '{"source":"%s","exit_code":%s,"fallback":%s,"elapsed_ms":%s}
' "${_safe_src}" "${_ev_rc}" "${_ev_fallback}" "${_ev_ms}" >> "${_log_file}"
}

for _a in "$@"; do
  if [ "${_a}" = "--version" ] || [ "${_a}" = "-v" ]; then
    _real_cc="${CUSTOM_CC_REAL_BIN:-${CUSTOM_CC_BIN:-}}"
    if [ -n "${_real_cc}" ] && [ -x "${_real_cc}" ] && [ "${_real_cc}" != "${THIS_FILE}" ]; then
      _ver_str="$("${_real_cc}" --version 2>&1 | head -n 1 || true)"
      printf 'custom-cc wrapper (%s)
' "${_ver_str}"
    else
      printf 'custom-cc 1.0.0 (libscript telemetry wrapper)
'
    fi
    exit 0
  fi
done

filter_compiler_args "$@"

_real_cc="${CUSTOM_CC_REAL_BIN:-${CUSTOM_CC_BIN:-}}"
case "${_real_cc}" in
  *custom-cc/default/bin/custom-cc|*custom-cc/*/bin/custom-cc|*cc_wrapper.sh)
    _real_cc=""
    ;;
esac
if [ -z "${_real_cc}" ] || [ "${_real_cc}" = "${THIS_FILE}" ] || [ ! -x "${_real_cc}" ]; then
  if [ -n "${CUSTOM_CC_FALLBACK_CC:-}" ] && command -v "${CUSTOM_CC_FALLBACK_CC}" >/dev/null 2>&1; then
    _real_cc="$(command -v "${CUSTOM_CC_FALLBACK_CC}")"
  elif [ -x "/usr/bin/cc" ]; then
    _real_cc="/usr/bin/cc"
  elif command -v clang >/dev/null 2>&1; then
    _real_cc="$(command -v clang)"
  elif command -v gcc >/dev/null 2>&1; then
    _real_cc="$(command -v gcc)"
  else
    printf 'Error: custom-cc could not locate an underlying C compiler binary.\n' >&2
    exit 1
  fi
fi

if [ "${CUSTOM_CC_STRIP_GNU_FLAGS:-true}" = "true" ] || [ "${CUSTOM_CC_STRIP_GNU_FLAGS:-1}" = "1" ]; then
  set -- "$@"
  _arg_count=$#
  _i=0
  while [ "${_i}" -lt "${_arg_count}" ]; do
    _cur="${1}"
    shift
    case "${_cur}" in
      -fstack-protector*|-fno-strict-overflow|-fno-delete-null-pointer-checks|-fconserve-stack|-fno-var-tracking-assignments|-Wno-*|-mfunction-return=*|-mindirect-branch=*)
        ;;
      *)
        set -- "$@" "${_cur}"
        ;;
    esac
    _i=$((_i + 1))
  done
fi

if [ -n "${CUSTOM_CC_EXTRA_CFLAGS:-}" ]; then
  # shellcheck disable=SC2086
  set -- "$@" ${CUSTOM_CC_EXTRA_CFLAGS}
fi

_rc=0
"${_real_cc}" "$@" || _rc=$?

if [ "${_rc}" -ne 0 ] && { [ "${CUSTOM_CC_FALLBACK_ON_ERROR:-false}" = "true" ] || [ "${CUSTOM_CC_FALLBACK_ON_ERROR:-0}" = "1" ]; }; then
  _fb_cc="${CUSTOM_CC_FALLBACK_CC:-$(command -v cc 2>/dev/null || command -v gcc 2>/dev/null || command -v clang 2>/dev/null || true)}"
  if [ -n "${_fb_cc}" ]; then
    _rc=0
    "${_fb_cc}" "$@" || _rc=$?
    record_compile_event "${WRAPPER_SOURCE_FILE}" "${_rc}" "true" "1"
    exit "${_rc}"
  fi
fi

record_compile_event "${WRAPPER_SOURCE_FILE}" "${_rc}" "false" "1"
exit "${_rc}"
