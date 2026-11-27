#!/bin/sh
# ## Overview
# Pre-warms an Ollama model into memory via /api/generate so the first inference request avoids cold-load latency.
# ## Usage
# ./_lib/app-servers/ollama/warmup.sh [model_tag]
set -feu
_owm_caller_this="${THIS_FILE:-}"; _owm_caller_dir="${SCRIPT_DIR:-}"; _owm_was_sourced=0
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"; _owm_was_sourced=1
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"; [ "${THIS_FILE}" != "${0}" ] && _owm_was_sourced=1
elif [ "${ZSH_VERSION-}" ]; then
  # shellcheck disable=SC2296
  THIS_FILE="${(%):-%x}"; [ "${THIS_FILE}" != "${0}" ] && _owm_was_sourced=1
else
  THIS_FILE="${0}"
fi
case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    [ -n "${_owm_caller_this}" ] && THIS_FILE="${_owm_caller_this}"
    [ -n "${_owm_caller_dir}" ] && SCRIPT_DIR="${_owm_caller_dir}"
    unset SCRIPT_NAME _owm_caller_this _owm_caller_dir _owm_was_sourced || true
    if (return 0 2>/dev/null); then return 0; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
# ## ollama_warmup_model
# Pre-warms the requested model (defaulting to gemma:2b) in Ollama with keep_alive and CPU-safe defaults.
ollama_warmup_model() {
  _lwo_model="${1:-${OLLAMA_DEFAULT_MODEL:-gemma:2b}}"
  _lwo_ka="${OLLAMA_KEEP_ALIVE:-30m}"
  export OLLAMA_KEEP_ALIVE="$_lwo_ka"
  export OLLAMA_NUM_GPU="${OLLAMA_NUM_GPU:-0}"
  if [ "${LIBSCRIPT_MOCK_SYSTEMD:-0}" = "1" ] || [ "${LIBSCRIPT_DRY_RUN:-0}" = "1" ]; then
    unset _lwo_model _lwo_ka || true
    return 0
  fi
  _lwo_saved_this="${THIS_FILE}"
  _lwo_saved_dir="${SCRIPT_DIR}"
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/engine/common/pkg_mgr.sh"
  export SCRIPT_NAME
  # shellcheck disable=SC1090,SC1091
  . "${SCRIPT_NAME}"
  unset SCRIPT_NAME || true
  THIS_FILE="${_lwo_saved_this}"
  SCRIPT_DIR="${_lwo_saved_dir}"
  unset _lwo_saved_this _lwo_saved_dir || true
  _lwo_host="${OLLAMA_HOST:-http://127.0.0.1:11434}"
  case "$_lwo_host" in
    http://*|https://*) _lwo_url="${_lwo_host%/}" ;;
    *) _lwo_url="http://${_lwo_host%/}" ;;
  esac
  _lwo_url="${_lwo_url%/v1}"
  _lwo_payload=$(printf '{"model":"%s","prompt":"warmup","stream":false,"keep_alive":"%s","options":{"num_predict":1,"num_ctx":512,"num_gpu":0}}' "$_lwo_model" "$_lwo_ka")
  libscript_http_post_json "${_lwo_url}/api/generate" "$_lwo_payload" 120 || true
  unset _lwo_model _lwo_ka _lwo_host _lwo_url _lwo_payload || true
  return 0
}

if [ "${_owm_was_sourced}" = '0' ]; then
  unset _owm_was_sourced || true
  ollama_warmup_model "$@"
fi

STACK="${STACK%"${THIS_FILE}":}"
export STACK
[ -n "${_owm_caller_dir:-}" ] && SCRIPT_DIR="${_owm_caller_dir}"
[ -n "${_owm_caller_this:-}" ] && THIS_FILE="${_owm_caller_this}"
unset SCRIPT_NAME _owm_caller_this _owm_caller_dir _owm_was_sourced || true
