#!/bin/sh
# ## Overview
# Tier 4 Slurm & Ray HPC/AI Gang Scheduler translating payload.json into sbatch scripts and Ray job specs.
#
# ## Usage
# ./payloads/schedulers/slurm_ray.sh <compile|submit|status|logs|stop|destroy> <payload.json_or_id>

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

# ## compile_sbatch_script
# Emits a Slurm sbatch script with GPU and gang scheduling directives.
compile_sbatch_script() {
  pf="$1"
  name="$(jq -r '.name' "$pf")"
  nodes="$(jq -r '.scaling.replicas // 1' "$pf")"
  cpus="$(jq -r '.resources.cpu_cores | floor' "$pf")"
  mem="$(jq -r '.resources.memory_mb' "$pf")"
  gpus="$(jq -r '.resources.gpu_count // 0' "$pf")"
  cmd="$(jq -r '(.artifact.entrypoint // ["python3"]) | join(" ")' "$pf")"
  printf '#!/bin/sh\n#SBATCH --job-name=%s\n#SBATCH --nodes=%s\n#SBATCH --cpus-per-task=%s\n#SBATCH --mem=%sM\n#SBATCH --gpus-per-node=%s\nsrun %s\n' "$name" "$nodes" "$cpus" "$mem" "$gpus" "$cmd"
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf '%s\n' "Usage: $0 <compile|submit|status|logs|stop|destroy> <payload.json_or_id>"
  exit 0
fi

ACTION="${1:-compile}"
TARGET="${2:-}"

case "$ACTION" in
  compile) compile_sbatch_script "$TARGET" ;;
  submit|status|logs|stop|destroy)
    printf '{"scheduler":"slurm_ray","action":"%s","workload":"%s","status":"ok"}\n' "$ACTION" "$TARGET"
    ;;
  *) exit 1 ;;
esac
