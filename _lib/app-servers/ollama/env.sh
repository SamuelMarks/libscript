#!/bin/sh
# ## Overview
# Internal script for ollama.
#
# ## Usage
# Executes initialization, logic, or testing for ollama.
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
_EB_CALLER_THIS="${THIS_FILE}"
_EB_CALLER_DIR="${SCRIPT_DIR}"
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/env_base.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true

export OLLAMA_INSTALL_METHOD="${OLLAMA_INSTALL_METHOD:-libscript_native}"
OLLAMA_VERSION="${OLLAMA_VERSION:-latest}"
export OLLAMA_HOST="${OLLAMA_HOST:-http://127.0.0.1:11434}"
export OLLAMA_NUM_PARALLEL="${OLLAMA_NUM_PARALLEL:-1}"
export OLLAMA_MAX_LOADED_MODELS="${OLLAMA_MAX_LOADED_MODELS:-1}"
export OLLAMA_FLASH_ATTENTION="${OLLAMA_FLASH_ATTENTION:-0}"
export OLLAMA_KV_CACHE_TYPE="${OLLAMA_KV_CACHE_TYPE:-f16}"
export OLLAMA_CONTEXT_LENGTH="${OLLAMA_CONTEXT_LENGTH:-2048}"
export OLLAMA_MAX_QUEUE="${OLLAMA_MAX_QUEUE:-16}"
export OLLAMA_KEEP_ALIVE="${OLLAMA_KEEP_ALIVE:-10m}"
export GGML_BACKEND_AMX="${GGML_BACKEND_AMX:-0}"
if ! command -v nvidia-smi >/dev/null 2>&1; then
  export OLLAMA_LLM_LIBRARY="${OLLAMA_LLM_LIBRARY:-cpu_avx2}"
  export OLLAMA_NUM_GPU="${OLLAMA_NUM_GPU:-0}"
else
  [ -n "${OLLAMA_LLM_LIBRARY:-}" ] && export OLLAMA_LLM_LIBRARY
  [ -n "${OLLAMA_NUM_GPU:-}" ] && export OLLAMA_NUM_GPU
fi
_ol_mount="${DATA_DISK_MOUNT:-${DATA_MOUNT_DIR:-/mnt/data}}"
if [ -d "$_ol_mount" ]; then
  _ol_default_models="${_ol_mount}/ollama_models"
else
  _ol_default_models="${LIBSCRIPT_DATA_DIR:-${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/data}/ollama/models"
fi
case "${OLLAMA_MODELS_DIR:-}" in
  /*|[A-Za-z]:\\*|[A-Za-z]:/*) ;;
  *) OLLAMA_MODELS_DIR="" ;;
esac
if [ -z "${OLLAMA_MODELS_DIR:-}" ]; then
  case "${OLLAMA_MODELS:-}" in
    /*|[A-Za-z]:\\*|[A-Za-z]:/*) OLLAMA_MODELS_DIR="$OLLAMA_MODELS" ;;
    *) OLLAMA_MODELS_DIR="$_ol_default_models" ;;
  esac
fi
export OLLAMA_MODELS_DIR
if [ -z "${OLLAMA_MODEL_LIST:-}" ]; then
  case "${OLLAMA_MODELS:-}" in
    /*|[A-Za-z]:\\*|[A-Za-z]:/*) ;;
    "") OLLAMA_MODELS="$OLLAMA_MODELS_DIR" ;;
  esac
  export OLLAMA_MODELS
else
  case "${OLLAMA_MODELS:-}" in
    ""|/*|[A-Za-z]:\\*|[A-Za-z]:/*)
      OLLAMA_MODELS="${OLLAMA_MODELS:-${OLLAMA_MODELS_DIR}}"
      export OLLAMA_MODELS
      ;;
  esac
fi
unset _ol_mount _ol_default_models || true
libscript_path_prepend "${LIBSCRIPT_HOME:-${HOME:-/root}/.libscript}/ollama/${OLLAMA_VERSION}/bin"
STACK="${STACK%"${THIS_FILE}":}"
export STACK
