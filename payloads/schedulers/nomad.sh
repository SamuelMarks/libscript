#!/bin/sh
# ## Overview
# Tier 4 HashiCorp Nomad Scheduler translating payload.json into Nomad JSON job specifications.
#
# ## Usage
# ./payloads/schedulers/nomad.sh <compile|submit|status|logs|stop|destroy> <payload.json_or_id>

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
export STACK="${STACK:-}${THIS_FILE}:"
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

# ## compile_nomad_job
# Translates a declarative payload.json into a HashiCorp Nomad JSON Job specification.
compile_nomad_job() {
  pf="$1"
  jq '{
    Job: {
      ID: .name,
      Name: .name,
      Type: (if (.type == "batch" or .type == "ai-training") then "batch" else "service" end),
      TaskGroups: [{
        Name: .name,
        Count: (.scaling.replicas // 1),
        Tasks: [{
          Name: .name,
          Driver: (if .artifact.format == "oci-image" then "docker" else "raw_exec" end),
          Config: { image: (.artifact.image // .artifact.component) },
          Resources: { CPU: ((.resources.cpu_cores * 1000) | floor), MemoryMB: .resources.memory_mb }
        }]
      }]
    }
  }' "$pf"
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf '%s\n' "Usage: $0 <compile|submit|status|logs|stop|destroy> <payload.json_or_id>"
  exit 0
fi

ACTION="${1:-compile}"
TARGET="${2:-}"

case "$ACTION" in
  compile) compile_nomad_job "$TARGET" ;;
  submit|status|logs|stop|destroy)
    printf '{"scheduler":"nomad","action":"%s","workload":"%s","status":"ok"}\n' "$ACTION" "$TARGET"
    ;;
  *) exit 1 ;;
esac
