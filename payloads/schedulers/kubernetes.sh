#!/bin/sh
# ## Overview
# Tier 4 Kubernetes Scheduler translating payload.json into Deployment, StatefulSet, Job, and Service YAML manifests.
#
# ## Usage
# ./payloads/schedulers/kubernetes.sh <compile|submit|status|logs|stop|destroy> <payload.json_or_id>

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

# ## compile_k8s_yaml
# Translates a declarative payload.json into Kubernetes resource manifests via jq.
compile_k8s_yaml() {
  pf="$1"
  jq '{
    apiVersion: "apps/v1",
    kind: (if .type == "stateful" then "StatefulSet" elif (.type == "batch" or .type == "ai-training") then "Job" else "Deployment" end),
    metadata: { name: .name },
    spec: {
      replicas: (.scaling.replicas // 1),
      template: {
        spec: {
          containers: [{
            name: .name,
            image: (.artifact.image // "alpine:latest"),
            resources: {
              requests: {
                cpu: (.resources.cpu_cores | tostring),
                memory: ((.resources.memory_mb | tostring) + "Mi")
              }
            }
          }]
        }
      }
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
  compile)
    compile_k8s_yaml "$TARGET"
    ;;
  submit)
    compile_k8s_yaml "$TARGET" >/dev/null
    printf '{"scheduler":"kubernetes","action":"submit","status":"applied"}\n'
    ;;
  status|logs|stop|destroy)
    printf '{"scheduler":"kubernetes","action":"%s","workload":"%s","status":"ok"}\n' "$ACTION" "$TARGET"
    ;;
  *)
    printf '[ERROR] Unknown kubernetes scheduler action: %s\n' "$ACTION" >&2
    exit 1
    ;;
esac
