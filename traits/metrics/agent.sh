#!/bin/sh
# ## Overview
# Queries hooks/metrics and emits atomic Prometheus file_sd_configs JSON files into /etc/prometheus/file_sd/.
#
# ## Usage
# ./traits/metrics/agent.sh [component...]

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
export STACK="${STACK:-}${THIS_FILE}:"
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/hooks.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"

# ## emit_prometheus_file_sd
# Writes Prometheus file_sd JSON targets for each component.
emit_prometheus_file_sd() {
  sysroot="${LIBSCRIPT_TARGET_SYSROOT:-/}"
  sd_dir="${sysroot%/}/etc/prometheus/file_sd"
  mkdir -p "$sd_dir"
  for comp in "$@"; do
    m_json="$(libscript_exec_hook "$comp" "metrics" 2>/dev/null || true)"
    if [ -n "$m_json" ]; then
      port="$(printf '%s\n' "$m_json" | jq -r '.scrape_port // 9100')"
      path="$(printf '%s\n' "$m_json" | jq -r '.scrape_path // "/metrics"')"
      printf '[{"targets":["127.0.0.1:%s"],"labels":{"job":"%s","__metrics_path__":"%s"}}]\n' "$port" "$comp" "$path" > "${sd_dir}/${comp}.json.tmp"
      mv -f "${sd_dir}/${comp}.json.tmp" "${sd_dir}/${comp}.json"
    fi
  done
  printf '[INFO] Prometheus file_sd targets emitted to %s.\n' "$sd_dir"
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf '%s\n' "Usage: $0 [component...]"
  exit 0
fi

if [ $# -eq 0 ]; then
  emit_prometheus_file_sd "postgres" "redis" "nginx"
else
  emit_prometheus_file_sd "$@"
fi
