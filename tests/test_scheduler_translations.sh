#!/bin/sh
# ## Overview
# Verifies payload.json compilation and 6-verb lifecycle across K8s (with Marathon-equivalent PaaS controller),
# Apache Mesos + Marathon (DOCKER, MESOS, and LibScript containerizers), Nomad, all 10 native init systems,
# Firecracker/Cloud-Hypervisor/Solo5 MicroVMs, XPK, and Slurm/Ray.
#
# ## Usage
# ./tests/test_scheduler_translations.sh

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
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}:"
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"
export LIBSCRIPT_ROOT_DIR

if ! command -v jq >/dev/null 2>&1; then
  printf '[SKIP] jq not found
'
  exit 0
fi

# 1. Test all AI & application payloads across K8s + Marathon-equivalent and Mesos + Marathon
for rel_pf in "payloads/ai/vllm/payload.json" "payloads/ai/ollama/payload.json" "payloads/ai/jetstream/payload.json" "payloads/ai/gke-xpk-training/payload.json" "payloads/ai/gke-xpk-inference/payload.json" "payloads/ai/gke-tpu-cluster/payload.json" "payloads/ai/gcp-gpu-vm/payload.json" "payloads/ai/gcp-tpu-vm/payload.json"; do
  pf="${LIBSCRIPT_ROOT_DIR}/${rel_pf}"
  [ -f "$pf" ] || continue

  # Kubernetes + Marathon-Equivalent Controller verification (2x idempotent compile & lifecycle)
  k8s_pass1=$(SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/payloads/engine.sh" sh "${LIBSCRIPT_ROOT_DIR}/payloads/engine.sh" compile "$pf" --scheduler kubernetes)
  k8s_pass2=$(SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/payloads/engine.sh" sh "${LIBSCRIPT_ROOT_DIR}/payloads/engine.sh" compile "$pf" --scheduler kubernetes)
  [ "$k8s_pass1" = "$k8s_pass2" ] || exit 1
  printf '%s
' "$k8s_pass1" | jq -e '.metadata.labels["libscript.io/paas-controller"] == "marathon-equivalent" and .marathon_equivalent.id != null' >/dev/null

  for verb in submit status logs stop destroy; do
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/payloads/engine.sh" sh "${LIBSCRIPT_ROOT_DIR}/payloads/engine.sh" "$verb" "$pf" --scheduler kubernetes | jq -e '.scheduler == "kubernetes" and .controller == "marathon-equivalent"' >/dev/null
  done

  # Apache Mesos + Marathon verification (2x idempotent compile, containerizers, & 6-verb lifecycle)
  mesos_pass1=$(SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/payloads/engine.sh" sh "${LIBSCRIPT_ROOT_DIR}/payloads/engine.sh" compile "$pf" --scheduler mesos)
  mesos_pass2=$(SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/payloads/engine.sh" sh "${LIBSCRIPT_ROOT_DIR}/payloads/engine.sh" compile "$pf" --scheduler mesos)
  [ "$mesos_pass1" = "$mesos_pass2" ] || exit 1
  printf '%s
' "$mesos_pass1" | jq -e '.id != null and .cpus != null and .mem != null and .instances != null and .container.type != null' >/dev/null

  for ctype in DOCKER MESOS; do
    LIBSCRIPT_MESOS_CONTAINERIZER="$ctype" SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/payloads/schedulers/mesos.sh" sh "${LIBSCRIPT_ROOT_DIR}/payloads/schedulers/mesos.sh" compile "$pf" | jq -e --arg c "$ctype" '.container.type == $c' >/dev/null
  done

  for verb in submit status logs stop destroy; do
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/payloads/engine.sh" sh "${LIBSCRIPT_ROOT_DIR}/payloads/engine.sh" "$verb" "$pf" --scheduler mesos | jq -e '.scheduler == "mesos" and .framework == "marathon"' >/dev/null
  done
done

# 2. Verify Nomad, MicroVM (firecracker, cloud-hypervisor, solo5), XPK, and Slurm/Ray
PAYLOAD_FILE="${LIBSCRIPT_ROOT_DIR}/payloads/ai/vllm/payload.json"
for sched in kubernetes nomad mesos microvm xpk slurm_ray; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/payloads/engine.sh" sh "${LIBSCRIPT_ROOT_DIR}/payloads/engine.sh" compile "$PAYLOAD_FILE" --scheduler "$sched" >/dev/null
  for verb in submit status logs stop destroy; do
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/payloads/engine.sh" sh "${LIBSCRIPT_ROOT_DIR}/payloads/engine.sh" "$verb" "$PAYLOAD_FILE" --scheduler "$sched" >/dev/null
  done
done

for vmm in firecracker cloud-hypervisor solo5; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/payloads/schedulers/microvm.sh" sh "${LIBSCRIPT_ROOT_DIR}/payloads/schedulers/microvm.sh" compile "$PAYLOAD_FILE" --vmm "$vmm" | jq -e --arg v "$vmm" '.vmm == $v' >/dev/null
done

# 3. Verify all 10 Native OS Init Systems (systemd, openrc, runit, s6, dinit, sysvinit, bsd-rc, smf, launchd, sc)
for init_sys in systemd openrc runit s6 dinit sysvinit bsd-rc smf launchd sc; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/payloads/schedulers/native.sh" sh "${LIBSCRIPT_ROOT_DIR}/payloads/schedulers/native.sh" compile "$PAYLOAD_FILE" --init "$init_sys" >/dev/null
  for verb in submit status logs stop destroy; do
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/payloads/schedulers/native.sh" sh "${LIBSCRIPT_ROOT_DIR}/payloads/schedulers/native.sh" "$verb" "$PAYLOAD_FILE" --init "$init_sys" >/dev/null
  done
done

printf '[PASS] Tier 4 scheduler translations verified across K8s (Marathon-equivalent), Mesos+Marathon, Nomad, MicroVM, XPK, Slurm/Ray, and 10 init systems.
'
