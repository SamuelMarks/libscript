#!/bin/sh
# ## Overview
# Tier 4 XPK Gang Scheduler translating AI/ML payload.json into Google Cloud XPK TPU slice workload commands.
#
# ## Usage
# ./payloads/schedulers/xpk.sh <compile|submit|status|logs|stop|destroy> <payload.json_or_id>

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

# ## compile_xpk_command
# Emits the xpk workload create CLI invocation for a multi-slice TPU payload.
compile_xpk_command() {
  pf="$1"
  jq -r '"xpk workload create --workload \(.name) --tpu-type \(.resources.tpu_accelerator_type // "v4-8") --num-slices \(.resources.tpu_slice_count // 1) --docker-image \(.artifact.image // "gcr.io/cloud-tpu-v2-images/jax-ai-image:latest") --command '\''\((.artifact.entrypoint // ["python3"]) | join(" "))'\''"' "$pf"
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf '%s\n' "Usage: $0 <compile|submit|status|logs|stop|destroy> <payload.json_or_id>"
  exit 0
fi

ACTION="${1:-compile}"
TARGET="${2:-}"

case "$ACTION" in
  compile) compile_xpk_command "$TARGET" ;;
  submit|status|logs|stop|destroy)
    printf '{"scheduler":"xpk","action":"%s","workload":"%s","status":"ok"}\n' "$ACTION" "$TARGET"
    ;;
  *) exit 1 ;;
esac
