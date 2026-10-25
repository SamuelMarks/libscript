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
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"

for _ol_lib in "_lib/_common/priv.sh" "_lib/app-servers/ollama/env.sh" "_lib/_common/service.sh" "_lib/_common/service_install.sh"; do
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

if [ "$_ol_action" = "start" ] || [ "$_ol_action" = "restart" ] || [ "$_ol_action" = "install-service" ] || [ "$_ol_action" = "configure" ]; then
  mkdir -p "${OLLAMA_MODELS}" 2>/dev/null || priv mkdir -p "${OLLAMA_MODELS}" 2>/dev/null || true
  chmod 0777 "${OLLAMA_MODELS}" 2>/dev/null || priv chmod 0777 "${OLLAMA_MODELS}" 2>/dev/null || true
  libscript_service_override_env "$_ol_svc" "OLLAMA_MODELS=${OLLAMA_MODELS}" || true
  if [ "$_ol_action" = "configure" ]; then
    if libscript_service status "$_ol_svc" >/dev/null 2>&1; then
      libscript_service restart "$_ol_svc" 2>/dev/null || true
    fi
    exit 0
  fi
fi

libscript_service "$_ol_action" "$_ol_svc"
