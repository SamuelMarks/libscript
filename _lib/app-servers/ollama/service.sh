#!/bin/sh
# ## Overview
# Manages background service lifecycle operations (start, stop, status, configure, override-env)
# and OLLAMA_MODELS directory configuration for the ollama component across all init systems.
#
# ## Usage
# ./service.sh [action]

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

for _ol_lib in "_lib/_common/log.sh" "_lib/_common/priv.sh" "_lib/_common/pkg_mgr.sh" "_lib/app-servers/ollama/env.sh" "_lib/_common/service.sh" "_lib/_common/service_install.sh"; do
  if [ -f "${LIBSCRIPT_ROOT_DIR}/${_ol_lib}" ]; then
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/${_ol_lib}"
    export SCRIPT_NAME
    # shellcheck disable=SC1090
    . "${SCRIPT_NAME}"
  fi
done
unset SCRIPT_NAME || true

_ol_action="${1:-${ACTION:-status}}"
_ol_svc="${LIBSCRIPT_SERVICE_NAME:-ollama}"
if [ ! -f "/etc/systemd/system/ollama.service" ] && [ ! -f "/lib/systemd/system/ollama.service" ]; then
  if [ -f "/etc/systemd/system/libscript_ollama.service" ]; then
    _ol_svc='libscript_ollama'
  fi
fi

# ## sanitize_ollama_host_value
# Strips http://, https://, and any /v1 or /v1/ suffix from an OLLAMA_HOST value.
sanitize_ollama_host_value() {
  _soh_val="${1:-127.0.0.1:11434}"
  _soh_val="${_soh_val#http://}"
  _soh_val="${_soh_val#https://}"
  _soh_val="${_soh_val%/}"
  _soh_val="${_soh_val%/v1}"
  _soh_val="${_soh_val%/}"
  [ -n "$_soh_val" ] || _soh_val='127.0.0.1:11434'
  printf '%s\n' "$_soh_val"
}

# ## ensure_ollama_systemd_unit
# Idempotently registers /etc/systemd/system/ollama.service when ollama is installed as a native binary on a systemd system and no unit file exists yet.
ensure_ollama_systemd_unit() {
  if [ "$(libscript_detect_init_system 2>/dev/null || printf 'fallback')" != "systemd" ]; then
    return 0
  fi
  if [ -f "/etc/systemd/system/ollama.service" ] || [ -f "/lib/systemd/system/ollama.service" ]; then
    return 0
  fi
  _eos_bin=""
  for _eos_cand in \
    "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/ollama/default/bin/ollama" \
    "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/ollama/latest/bin/ollama" \
    "/usr/local/bin/ollama" \
    "/usr/bin/ollama" \
    "$(command -v ollama 2>/dev/null || true)"; do
    if [ -n "$_eos_cand" ] && [ -x "$_eos_cand" ]; then
      _eos_bin="$_eos_cand"
      break
    fi
  done
  [ -n "$_eos_bin" ] || return 0
  _eos_user="${SERVICE_USER:-root}"
  if id ollama >/dev/null 2>&1; then
    _eos_user='ollama'
  fi
  libscript_install_service "ollama" "${_eos_bin} serve" "/" "Ollama Service" "" "$_eos_user" || true
  # libscript-allow-raw-daemon
  priv systemctl daemon-reload 2>/dev/null || systemctl daemon-reload 2>/dev/null || true
  _ol_svc='ollama'
  return 0
}

# ## resolve_ollama_models_dir
# Resolves the effective Ollama daemon model storage directory from OLLAMA_MODELS_DIR or OLLAMA_MODELS.
resolve_ollama_models_dir() {
  _rom_dir=""
  case "${OLLAMA_MODELS_DIR:-}" in
    /*|[A-Za-z]:\\*|[A-Za-z]:/*)
      _rom_dir="$OLLAMA_MODELS_DIR"
      ;;
    *)
      OLLAMA_MODELS_DIR=""
      ;;
  esac
  if [ -z "$_rom_dir" ]; then
    case "${OLLAMA_MODELS:-}" in
      /*|[A-Za-z]:\\*|[A-Za-z]:/*)
        _rom_dir="$OLLAMA_MODELS"
        ;;
    esac
  fi
  if [ -z "$_rom_dir" ]; then
    _rom_mount="${DATA_DISK_MOUNT:-${DATA_MOUNT_DIR:-/mnt/data}}"
    if [ -d "$_rom_mount" ] || [ -n "${DATA_DISK_MOUNT:-}" ] || [ -n "${DATA_MOUNT_DIR:-}" ]; then
      _rom_dir="${_rom_mount}/ollama_models"
    else
      _rom_dir="${LIBSCRIPT_DATA_DIR:-${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/data}/ollama/models"
    fi
  fi
  OLLAMA_MODELS="$_rom_dir"
  OLLAMA_MODELS_DIR="$_rom_dir"
  export OLLAMA_MODELS OLLAMA_MODELS_DIR
  printf '%s\n' "$_rom_dir"
}

resolve_ollama_models_dir >/dev/null
OLLAMA_HOST="http://$(sanitize_ollama_host_value "${OLLAMA_HOST:-127.0.0.1:11434}")"
export OLLAMA_HOST

# ## migrate_legacy_ollama_models
# Migrates allowed lightweight CPU models from /usr/share/ollama/.ollama/models into the target OLLAMA_MODELS directory and purges oversized 26B/27B blobs on GPU-less nodes.
migrate_legacy_ollama_models() {
  _mlom_dest="$1"
  [ -n "$_mlom_dest" ] || return 0
  _mlom_legacy='/usr/share/ollama/.ollama/models'
  if [ -d "$_mlom_legacy" ] && [ "$_mlom_legacy" != "$_mlom_dest" ]; then
    if [ ! -d "${_mlom_dest}/manifests" ] || [ -z "$(ls -A "${_mlom_dest}/manifests" 2>/dev/null || true)" ]; then
      if command -v nvidia-smi >/dev/null 2>&1; then
        log_info "[OLLAMA] [MIGRATE] Copying existing models from ${_mlom_legacy} to ${_mlom_dest}..."
        for _mlom_sub in blobs manifests; do
          if [ -d "${_mlom_legacy}/${_mlom_sub}" ]; then
            priv mkdir -p "${_mlom_dest}/${_mlom_sub}"
            if command -v rsync >/dev/null 2>&1; then
              priv rsync -a "${_mlom_legacy}/${_mlom_sub}/" "${_mlom_dest}/${_mlom_sub}/" 2>/dev/null || true
            else
              priv cp -rn "${_mlom_legacy}/${_mlom_sub}/." "${_mlom_dest}/${_mlom_sub}/" 2>/dev/null || priv cp -r "${_mlom_legacy}/${_mlom_sub}/." "${_mlom_dest}/${_mlom_sub}/" 2>/dev/null || true
            fi
          fi
        done
      else
        log_info "[OLLAMA] [MIGRATE] GPU-less node detected; migrating only lightweight CPU models (gemma:2b, llama3.2:1b, phi4-mini) from ${_mlom_legacy}..."
        for _mlom_allow in "gemma/2b" "llama3.2/1b" "phi4-mini/latest" "phi4-mini"; do
          _mlom_mpath="${_mlom_legacy}/manifests/registry.ollama.ai/library/${_mlom_allow}"
          if [ -f "$_mlom_mpath" ]; then
            _mlom_dpath="${_mlom_dest}/manifests/registry.ollama.ai/library/${_mlom_allow}"
            priv mkdir -p "$(dirname "$_mlom_dpath")" "${_mlom_dest}/blobs"
            priv cp -f "$_mlom_mpath" "$_mlom_dpath" 2>/dev/null || true
            for _mlom_digest in $(grep -oE 'sha256:[0-9a-f]{64}' "$_mlom_mpath" 2>/dev/null | tr ':' '-' || true); do
              if [ -f "${_mlom_legacy}/blobs/${_mlom_digest}" ] && [ ! -f "${_mlom_dest}/blobs/${_mlom_digest}" ]; then
                priv cp -f "${_mlom_legacy}/blobs/${_mlom_digest}" "${_mlom_dest}/blobs/${_mlom_digest}" 2>/dev/null || true
              fi
            done
          fi
        done
      fi
    fi
  fi
  if ! command -v nvidia-smi >/dev/null 2>&1 && [ -d "$_mlom_dest" ]; then
    for _mlom_heavy in "26b" "27b" "32b" "70b"; do
      find "${_mlom_dest}/manifests" -type f -name "*${_mlom_heavy}*" -exec rm -f {} + 2>/dev/null || true
    done
    if [ -d "${_mlom_dest}/blobs" ]; then
      find "${_mlom_dest}/blobs" -type f -size +10G -exec rm -f {} + 2>/dev/null || true
    fi
  fi
}

# ## configure_ollama_models_dir
# Idempotently ensures the OLLAMA_MODELS directory exists with 02775 permissions and appropriate ownership, and applies the service override.
configure_ollama_models_dir() {
  ensure_ollama_systemd_unit
  _com_dir="${1:-}"
  case "$_com_dir" in
    /*|[A-Za-z]:\\*|[A-Za-z]:/*) ;;
    *) _com_dir="" ;;
  esac
  if [ -z "$_com_dir" ]; then
    _com_dir=$(resolve_ollama_models_dir)
  fi
  case "${OLLAMA_MODELS_DIR:-}" in
    /*|[A-Za-z]:\\*|[A-Za-z]:/*) ;;
    *) unset OLLAMA_MODELS_DIR || true ;;
  esac
  OLLAMA_MODELS="$_com_dir"
  case "${OLLAMA_MODELS:-}" in
    /*|[A-Za-z]:\\*|[A-Za-z]:/*) ;;
    *)
      OLLAMA_MODELS="${OLLAMA_MODELS_DIR:-${DATA_DISK_MOUNT:-${DATA_MOUNT_DIR:-/mnt/data}}/ollama_models}"
      ;;
  esac
  OLLAMA_MODELS_DIR="$OLLAMA_MODELS"
  export OLLAMA_MODELS OLLAMA_MODELS_DIR
  mkdir -p "${OLLAMA_MODELS}" "${OLLAMA_MODELS}/manifests" "${OLLAMA_MODELS}/blobs" 2>/dev/null || priv mkdir -p "${OLLAMA_MODELS}" "${OLLAMA_MODELS}/manifests" "${OLLAMA_MODELS}/blobs" 2>/dev/null || true
  migrate_legacy_ollama_models "${OLLAMA_MODELS}"
  SERVICE_USER="${SERVICE_USER:-${REMOTE_USER:-$(id -un 2>/dev/null || printf 'root')}}"
  SERVICE_GROUP="${SERVICE_GROUP:-${REMOTE_GROUP:-$SERVICE_USER}}"
  if id ollama >/dev/null 2>&1; then
    if [ -n "$SERVICE_USER" ] && [ "$SERVICE_USER" != "root" ] && id "$SERVICE_USER" >/dev/null 2>&1; then
      usermod -aG ollama "$SERVICE_USER" 2>/dev/null || priv usermod -aG ollama "$SERVICE_USER" 2>/dev/null || true
      usermod -aG "$SERVICE_GROUP" ollama 2>/dev/null || priv usermod -aG "$SERVICE_GROUP" ollama 2>/dev/null || true
    fi
    chown -R ollama:ollama "${OLLAMA_MODELS}" 2>/dev/null || priv chown -R ollama:ollama "${OLLAMA_MODELS}" 2>/dev/null || true
  else
    chown -R "${SERVICE_USER:-$(id -un)}" "${OLLAMA_MODELS}" 2>/dev/null || priv chown -R "${SERVICE_USER:-$(id -un)}" "${OLLAMA_MODELS}" 2>/dev/null || true
  fi
  chmod 02775 "${OLLAMA_MODELS}" "${OLLAMA_MODELS}/manifests" "${OLLAMA_MODELS}/blobs" 2>/dev/null || priv chmod 02775 "${OLLAMA_MODELS}" "${OLLAMA_MODELS}/manifests" "${OLLAMA_MODELS}/blobs" 2>/dev/null || true
  chmod -R u+rwX,g+rwXs,o+rX "${OLLAMA_MODELS}" 2>/dev/null || priv chmod -R u+rwX,g+rwXs,o+rX "${OLLAMA_MODELS}" 2>/dev/null || true

  _com_host=$(sanitize_ollama_host_value "${OLLAMA_HOST:-127.0.0.1:11434}")
  OLLAMA_HOST="http://${_com_host}"
  export OLLAMA_HOST
  _com_par="${OLLAMA_NUM_PARALLEL:-1}"
  _com_max="${OLLAMA_MAX_LOADED_MODELS:-1}"
  _com_fa="${OLLAMA_FLASH_ATTENTION:-0}"
  _com_kv="${OLLAMA_KV_CACHE_TYPE:-f16}"
  _com_ctx="${OLLAMA_CONTEXT_LENGTH:-2048}"
  _com_q="${OLLAMA_MAX_QUEUE:-16}"
  _com_ka="${OLLAMA_KEEP_ALIVE:-10m}"
  _com_amx="${GGML_BACKEND_AMX:-0}"
  _com_llm_lib="${OLLAMA_LLM_LIBRARY:-}"
  _com_num_gpu="${OLLAMA_NUM_GPU:-}"
  if ! command -v nvidia-smi >/dev/null 2>&1; then
    _com_llm_lib="${_com_llm_lib:-cpu_avx2}"
    _com_num_gpu="${_com_num_gpu:-0}"
  fi

  set -- "$_ol_svc" \
    "OLLAMA_MODELS=${OLLAMA_MODELS}" \
    "OLLAMA_HOST=${_com_host}" \
    "OLLAMA_NUM_PARALLEL=${_com_par}" \
    "OLLAMA_MAX_LOADED_MODELS=${_com_max}" \
    "OLLAMA_FLASH_ATTENTION=${_com_fa}" \
    "OLLAMA_KV_CACHE_TYPE=${_com_kv}" \
    "OLLAMA_CONTEXT_LENGTH=${_com_ctx}" \
    "OLLAMA_MAX_QUEUE=${_com_q}" \
    "OLLAMA_KEEP_ALIVE=${_com_ka}" \
    "GGML_BACKEND_AMX=${_com_amx}"
  if [ -n "$_com_llm_lib" ]; then
    set -- "$@" "OLLAMA_LLM_LIBRARY=${_com_llm_lib}"
  fi
  if [ -n "$_com_num_gpu" ]; then
    set -- "$@" "OLLAMA_NUM_GPU=${_com_num_gpu}"
  fi
  libscript_service_override_env "$@" || true
  if [ "${LIBSCRIPT_OVERRIDE_CHANGED:-0}" = "1" ] && libscript_service status "$_ol_svc" >/dev/null 2>&1; then
    libscript_service restart "$_ol_svc" 2>/dev/null || true
    wait_for_ollama_ready
  fi
}

# ## verify_authentic_gemma_model
# Verifies that gemma:2b has its genuine Google Gemma family/digest and was not aliased to llama3.2:1b; if aliased, removes and re-pulls authentic gemma:2b.
verify_authentic_gemma_model() {
  _vag_model="${1:-gemma:2b}"
  [ "$_vag_model" = "gemma:2b" ] || return 0
  if [ "${LIBSCRIPT_MOCK_SYSTEMD:-0}" = "1" ] || [ "${LIBSCRIPT_DRY_RUN:-0}" = "1" ]; then
    return 0
  fi
  command -v ollama >/dev/null 2>&1 || return 0
  _vag_host=$(sanitize_ollama_host_value "${OLLAMA_HOST:-127.0.0.1:11434}")
  OLLAMA_HOST="http://${_vag_host}"
  export OLLAMA_HOST
  _vag_needs_repull=0
  _vag_gemma_id=$(ollama list 2>/dev/null | awk '$1 == "gemma:2b" {print $2}' || true)
  _vag_llama_id=$(ollama list 2>/dev/null | awk '$1 == "llama3.2:1b" {print $2}' || true)
  if [ -n "$_vag_gemma_id" ] && [ -n "$_vag_llama_id" ] && [ "$_vag_gemma_id" = "$_vag_llama_id" ]; then
    _vag_needs_repull=1
  fi
  if [ "$_vag_needs_repull" -eq 0 ] && command -v curl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    _vag_url="http://${_vag_host}"
    _vag_tags=$(curl -sS --connect-timeout 5 --max-time 10 "${_vag_url%/}/api/tags" 2>/dev/null || true)
    if [ -n "$_vag_tags" ]; then
      _vag_fam=$(printf '%s\n' "$_vag_tags" | jq -r '.models[]? | select(.name == "gemma:2b") | .details.family // empty' 2>/dev/null | head -n 1 || true)
      if [ -n "$_vag_fam" ] && [ "$_vag_fam" != "gemma" ]; then
        _vag_needs_repull=1
      fi
    fi
  fi
  if [ "$_vag_needs_repull" -eq 1 ]; then
    log_warn "[OLLAMA] [AUTHENTICITY] Detected non-genuine 'gemma:2b' alias (family/digest mismatch); restoring authentic Google Gemma 2B weights..."
    ollama rm "gemma:2b" 2>/dev/null || true
    ollama pull "gemma:2b" || return 1
  fi
  return 0
}

# ## verify_ollama_model_inference
# Sends a 1-token /api/generate smoke request for a model and re-pulls the authentic model once if llama-server crashes.
verify_ollama_model_inference() {
  _vomi_model="${1:-}"
  [ -n "$_vomi_model" ] || return 0
  if [ "${LIBSCRIPT_MOCK_SYSTEMD:-0}" = "1" ] || [ "${LIBSCRIPT_DRY_RUN:-0}" = "1" ]; then
    return 0
  fi
  if [ "$_vomi_model" = "gemma:2b" ]; then
    verify_authentic_gemma_model "gemma:2b" || return 1
  fi
  command -v curl >/dev/null 2>&1 || return 0
  _vomi_host=$(sanitize_ollama_host_value "${OLLAMA_HOST:-127.0.0.1:11434}")
  OLLAMA_HOST="http://${_vomi_host}"
  export OLLAMA_HOST
  _vomi_url="http://${_vomi_host}"
  _vomi_gen="${_vomi_url%/}/api/generate"
  _vomi_ka="${OLLAMA_KEEP_ALIVE:-30m}"
  _vomi_payload="{\"model\":\"${_vomi_model}\",\"prompt\":\"SELECT 1;\",\"stream\":false,\"keep_alive\":\"${_vomi_ka}\",\"options\":{\"num_predict\":1,\"num_ctx\":512,\"num_gpu\":0,\"num_thread\":4,\"use_mmap\":false}}"
  _vomi_resp=$(curl -sS --connect-timeout 5 --max-time 60 -H "Content-Type: application/json" -d "$_vomi_payload" "$_vomi_gen" 2>/dev/null || true)
  case "$_vomi_resp" in
    *"llama-server process has terminated"*|*"segmentation fault"*|*"core dumped"*|*"signal: "*)
      log_warn "[OLLAMA] [HEAL] Model '${_vomi_model}' crashed during 1-token smoke test (${_vomi_resp}); applying GGML_BACKEND_AMX=0 / cpu_avx2 overrides, repairing permissions, and re-pulling authentic model..."
      _vomi_mdir=$(resolve_ollama_models_dir)
      if [ -n "$_vomi_mdir" ] && [ -d "$_vomi_mdir" ]; then
        if id ollama >/dev/null 2>&1; then
          chown -R ollama:ollama "$_vomi_mdir" 2>/dev/null || priv chown -R ollama:ollama "$_vomi_mdir" 2>/dev/null || true
        else
          chown -R "${SERVICE_USER:-$(id -un)}" "$_vomi_mdir" 2>/dev/null || priv chown -R "${SERVICE_USER:-$(id -un)}" "$_vomi_mdir" 2>/dev/null || true
        fi
        chmod 02775 "$_vomi_mdir" "${_vomi_mdir}/manifests" "${_vomi_mdir}/blobs" 2>/dev/null || priv chmod 02775 "$_vomi_mdir" "${_vomi_mdir}/manifests" "${_vomi_mdir}/blobs" 2>/dev/null || true
        chmod -R u+rwX,g+rwXs,o+rX "$_vomi_mdir" 2>/dev/null || priv chmod -R u+rwX,g+rwXs,o+rX "$_vomi_mdir" 2>/dev/null || true
      fi
      configure_ollama_models_dir "$_vomi_mdir"
      if libscript_service status "$_ol_svc" >/dev/null 2>&1; then
        libscript_service restart "$_ol_svc" 2>/dev/null || true
        wait_for_ollama_ready
      fi
      if command -v ollama >/dev/null 2>&1; then
        ollama rm "$_vomi_model" 2>/dev/null || true
        ollama pull "$_vomi_model" || true
      fi
      _vomi_resp2=$(curl -sS --connect-timeout 5 --max-time 60 -H "Content-Type: application/json" -d "$_vomi_payload" "$_vomi_gen" 2>/dev/null || true)
      case "$_vomi_resp2" in
        *"llama-server process has terminated"*|*"segmentation fault"*|*"core dumped"*|*"signal: "*)
          log_error "[OLLAMA] Model '${_vomi_model}' still failed 1-token smoke test after re-pull: ${_vomi_resp2}"
          return 1
          ;;
      esac
      ;;
  esac
  return 0
}

# ## wait_for_ollama_ready
# Polls http://127.0.0.1:11434/api/tags for up to 30 seconds until the Ollama daemon is responsive.
wait_for_ollama_ready() {
  if [ "${LIBSCRIPT_MOCK_SYSTEMD:-0}" = "1" ] || [ "${LIBSCRIPT_DRY_RUN:-0}" = "1" ]; then
    return 0
  fi
  _wor_host=$(sanitize_ollama_host_value "${OLLAMA_HOST:-127.0.0.1:11434}")
  OLLAMA_HOST="http://${_wor_host}"
  export OLLAMA_HOST
  _wor_url="http://${_wor_host}"
  _wor_tags="${_wor_url%/}/api/tags"
  _wor_elapsed=0
  _wor_max="${OLLAMA_READY_TIMEOUT:-30}"
  while [ "$_wor_elapsed" -lt "$_wor_max" ]; do
    if libscript_fetch_stdout "$_wor_tags" >/dev/null 2>&1; then
      return 0
    fi
    if command -v ollama >/dev/null 2>&1 && ollama list >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
    _wor_elapsed=$((_wor_elapsed + 1))
  done
  log_warn "Ollama readiness poll timed out after ${_wor_max}s waiting for ${_wor_tags}."
  return 0
}

# ## is_ollama_model_installed
# Checks whether the requested model (or model:latest) is already registered in the local Ollama catalog.
is_ollama_model_installed() {
  _iom_model="${1:-}"
  [ -n "$_iom_model" ] || return 1
  _iom_alt="$_iom_model"
  case "$_iom_model" in
    *:*) ;;
    *) _iom_alt="${_iom_model}:latest" ;;
  esac
  _iom_host=$(sanitize_ollama_host_value "${OLLAMA_HOST:-127.0.0.1:11434}")
  OLLAMA_HOST="http://${_iom_host}"
  export OLLAMA_HOST
  _iom_list=""
  if command -v ollama >/dev/null 2>&1; then
    _iom_list=$(ollama list 2>/dev/null | awk 'NR>1 {print $1}' || true)
  fi
  if [ -z "$_iom_list" ] && command -v jq >/dev/null 2>&1; then
    _iom_url="http://${_iom_host}"
    _iom_json=$(libscript_fetch_stdout "${_iom_url%/}/api/tags" 2>/dev/null || true)
    if [ -n "$_iom_json" ]; then
      _iom_list=$(printf '%s\n' "$_iom_json" | jq -r '.models[]?.name // empty' 2>/dev/null || true)
    fi
  fi
  [ -n "$_iom_list" ] || return 1
  printf '%s\n' "$_iom_list" | grep -Fxq "$_iom_model" && return 0
  printf '%s\n' "$_iom_list" | grep -Fxq "$_iom_alt" && return 0
  return 1
}

# ## ensure_ollama_models
# Idempotently ensures each requested model is present, pulling missing models and verifying registration.
ensure_ollama_models() {
  configure_ollama_models_dir "$(resolve_ollama_models_dir)"
  wait_for_ollama_ready
  _eom_raw="$*"
  if [ -z "$_eom_raw" ]; then
    _eom_raw="${OLLAMA_MODEL_LIST:-${OLLAMA_DEFAULT_MODEL:-}}"
  fi
  _eom_models=$(printf '%s\n' "$_eom_raw" | tr ',' ' ')
  for _eom_m in $_eom_models; do
    [ -n "$_eom_m" ] || continue
    if is_ollama_model_installed "$_eom_m"; then
      log_info "[OLLAMA] [REUSE] Model '${_eom_m}' is already present."
      if [ "${OLLAMA_VERIFY_INFERENCE:-0}" = "1" ] || [ "$_eom_m" = "gemma:2b" ]; then
        verify_ollama_model_inference "$_eom_m" || return 1
      fi
      continue
    fi
    log_info "[OLLAMA] [PULL] Pulling model '${_eom_m}'..."
    if ! ollama pull "$_eom_m"; then
      log_error "[OLLAMA] Failed to pull model '${_eom_m}'."
      return 1
    fi
    if ! is_ollama_model_installed "$_eom_m"; then
      log_error "[OLLAMA] Model '${_eom_m}' was not registered in 'ollama list' after pull."
      return 1
    fi
    if [ "${OLLAMA_VERIFY_INFERENCE:-0}" = "1" ] || [ "$_eom_m" = "gemma:2b" ]; then
      verify_ollama_model_inference "$_eom_m" || return 1
    fi
    log_info "[OLLAMA] Verified model '${_eom_m}' is registered."
  done
  return 0
}

# ## prune_ollama_models
# Removes any locally installed Ollama models that are not in the allowed model list.
prune_ollama_models() {
  wait_for_ollama_ready
  _pom_raw="$*"
  if [ -z "$_pom_raw" ]; then
    _pom_raw="${OLLAMA_MODEL_LIST:-${OLLAMA_DEFAULT_MODEL:-}}"
  fi
  [ -n "$_pom_raw" ] || return 0
  command -v ollama >/dev/null 2>&1 || return 0
  _pom_keep=$(printf '%s\n' "$_pom_raw" | tr ',' '\n' | tr ' ' '\n' | sed '/^$/d')
  _pom_installed=$(ollama list 2>/dev/null | awk 'NR>1 {print $1}' || true)
  for _pom_m in $_pom_installed; do
    [ -n "$_pom_m" ] || continue
    _pom_base="${_pom_m%:latest}"
    if printf '%s\n' "$_pom_keep" | grep -Fxq "$_pom_m" || printf '%s\n' "$_pom_keep" | grep -Fxq "$_pom_base"; then
      continue
    fi
    log_info "[OLLAMA] [PRUNE] Removing unconfigured model '${_pom_m}'..."
    ollama rm "$_pom_m" || true
  done
  return 0
}

case "$_ol_action" in
  ensure-models)
    shift || true
    if [ "${1:-}" = "ollama" ] || [ "${1:-}" = "libscript_ollama" ]; then
      shift || true
    fi
    ensure_ollama_models "$@"
    exit $?
    ;;
  prune-models)
    shift || true
    if [ "${1:-}" = "ollama" ] || [ "${1:-}" = "libscript_ollama" ]; then
      shift || true
    fi
    prune_ollama_models "$@"
    exit $?
    ;;
  start|restart|up|install-service|configure|override-env)
    _ol_target_dir=""
    if [ "$_ol_action" = "configure" ] || [ "$_ol_action" = "override-env" ]; then
      if [ -n "${2:-}" ] && [ "${2:-}" != "ollama" ] && [ "${2:-}" != "libscript_ollama" ]; then
        _ol_target_dir="$2"
      elif [ -n "${3:-}" ]; then
        _ol_target_dir="$3"
      fi
    fi
    if [ -z "$_ol_target_dir" ]; then
      _ol_target_dir=$(resolve_ollama_models_dir)
    fi
    configure_ollama_models_dir "$_ol_target_dir"
    if [ "$_ol_action" = "configure" ] || [ "$_ol_action" = "override-env" ]; then
      if libscript_service status "$_ol_svc" >/dev/null 2>&1; then
        libscript_service restart "$_ol_svc" 2>/dev/null || true
        wait_for_ollama_ready
      fi
      exit 0
    fi
    libscript_service "$_ol_action" "$_ol_svc"
    if [ "$_ol_action" = "start" ] || [ "$_ol_action" = "restart" ] || [ "$_ol_action" = "up" ]; then
      wait_for_ollama_ready
    fi
    exit 0
    ;;
esac

libscript_service "$_ol_action" "$_ol_svc"
