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

# ## resolve_ollama_models_dir
# Resolves the effective Ollama daemon model storage directory from OLLAMA_MODELS_DIR or OLLAMA_MODELS.
resolve_ollama_models_dir() {
  _rom_dir="${OLLAMA_MODELS_DIR:-}"
  if [ -z "$_rom_dir" ]; then
    case "${OLLAMA_MODELS:-}" in
      /*|[A-Za-z]:\\*|[A-Za-z]:/*)
        _rom_dir="$OLLAMA_MODELS"
        ;;
    esac
  fi
  if [ -z "$_rom_dir" ]; then
    _rom_mount="${DATA_DISK_MOUNT:-${DATA_MOUNT_DIR:-/mnt/data}}"
    if [ -d "$_rom_mount" ]; then
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
# Idempotently ensures the OLLAMA_MODELS directory exists with 0755 permissions and service-user ownership, and applies the service override.
configure_ollama_models_dir() {
  _com_dir="${1:-$(resolve_ollama_models_dir)}"
  [ -n "$_com_dir" ] || return 0
  OLLAMA_MODELS="${OLLAMA_MODELS_DIR:-${_com_dir:-${DATA_MOUNT_DIR:-/mnt/data}/ollama_models}}"
  export OLLAMA_MODELS
  mkdir -p "${OLLAMA_MODELS}" 2>/dev/null || priv mkdir -p "${OLLAMA_MODELS}" 2>/dev/null || true
  chmod 0755 "${OLLAMA_MODELS}" 2>/dev/null || priv chmod 0755 "${OLLAMA_MODELS}" 2>/dev/null || true
  migrate_legacy_ollama_models "${OLLAMA_MODELS}"
  SERVICE_USER="${SERVICE_USER:-${REMOTE_USER:-root}}"
  SERVICE_GROUP="${SERVICE_GROUP:-${REMOTE_GROUP:-$SERVICE_USER}}"
  chown -R ollama:ollama "${OLLAMA_MODELS}" 2>/dev/null || priv chown -R ollama:ollama "${OLLAMA_MODELS}" 2>/dev/null || chown -R "${SERVICE_USER}:${SERVICE_GROUP}" "${OLLAMA_MODELS}" 2>/dev/null || priv chown -R "${SERVICE_USER}:${SERVICE_GROUP}" "${OLLAMA_MODELS}" 2>/dev/null || true

  _com_host="${OLLAMA_HOST:-127.0.0.1:11434}"
  case "$_com_host" in
    http://*) _com_host="${_com_host#http://}" ;;
    https://*) _com_host="${_com_host#https://}" ;;
  esac
  _com_par="${OLLAMA_NUM_PARALLEL:-1}"
  _com_max="${OLLAMA_MAX_LOADED_MODELS:-1}"

  libscript_service_override_env "$_ol_svc" \
    "OLLAMA_MODELS=${OLLAMA_MODELS}" \
    "OLLAMA_HOST=${_com_host}" \
    "OLLAMA_NUM_PARALLEL=${_com_par}" \
    "OLLAMA_MAX_LOADED_MODELS=${_com_max}" || true
  if libscript_service is-active "$_ol_svc" >/dev/null 2>&1; then
    libscript_service restart "$_ol_svc" 2>/dev/null || true
  fi
}

# ## wait_for_ollama_ready
# Polls http://127.0.0.1:11434/api/tags for up to 30 seconds until the Ollama daemon is responsive.
wait_for_ollama_ready() {
  if [ "${LIBSCRIPT_MOCK_SYSTEMD:-0}" = "1" ] || [ "${LIBSCRIPT_DRY_RUN:-0}" = "1" ]; then
    return 0
  fi
  _wor_url="${OLLAMA_HOST:-http://127.0.0.1:11434}"
  case "$_wor_url" in
    http://*|https://*) ;;
    *) _wor_url="http://${_wor_url}" ;;
  esac
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
  _iom_list=""
  if command -v ollama >/dev/null 2>&1; then
    _iom_list=$(ollama list 2>/dev/null | awk 'NR>1 {print $1}' || true)
  fi
  if [ -z "$_iom_list" ] && command -v jq >/dev/null 2>&1; then
    _iom_url="${OLLAMA_HOST:-http://127.0.0.1:11434}"
    case "$_iom_url" in
      http://*|https://*) ;;
      *) _iom_url="http://${_iom_url}" ;;
    esac
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
