#!/bin/sh
# ## Overview
# Hermetic test suite for _lib/cloud-providers/gcp-tpu-vm/cli.sh testing scp/ssh --all-workers, runtime auto-selection, idempotent create/delete (2x), wait-ready polling, 1-worker/4-worker topology-info, sync-repo digest skip, arm-ttl, and release-locks.
#
# ## Usage
# ./tests/test_gcp_tpu_vm_qr_multihost.sh
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
export LIBSCRIPT_ROOT_DIR

WORK_DIR="${LIBSCRIPT_ROOT_DIR}/tests_tmp/tpu_qr_mh_$$"
mkdir -p "${WORK_DIR}/bin" "${WORK_DIR}/state" "${WORK_DIR}/sample_repo"
trap 'rm -rf "${WORK_DIR}"' EXIT

printf 'print("hello tpu")\n' > "${WORK_DIR}/sample_repo/main.py"
GCLOUD_LOG="${WORK_DIR}/gcloud.log"
: > "${GCLOUD_LOG}"
export WORK_DIR GCLOUD_LOG

cat <<'MOCK_EOF' > "${WORK_DIR}/bin/gcloud"
#!/bin/sh
for _a in "$@"; do
  if [ -z "${_a}" ]; then
    printf 'EMPTY_ARG_ERROR\n' >> "${GCLOUD_LOG}"
    exit 99
  fi
done
printf '%s\n' "$*" >> "${GCLOUD_LOG}"

case "$*" in
  *"value(labels.libscript)"*)
    printf 'managed\n'
    exit 0
    ;;
  *"disks describe"*)
    exit 1
    ;;
  *"queued-resources create"*)
    touch "${WORK_DIR}/state/qr_exists"
    printf '0\n' > "${WORK_DIR}/state/poll_cnt"
    touch "${WORK_DIR}/state/vm_exists"
    exit 0
    ;;
  *"queued-resources describe"*)
    [ -f "${WORK_DIR}/state/qr_exists" ] || exit 1
    _c=$(cat "${WORK_DIR}/state/poll_cnt" 2>/dev/null || printf '2')
    _c=$((_c + 1))
    printf '%s\n' "${_c}" > "${WORK_DIR}/state/poll_cnt"
    if [ "${_c}" -eq 1 ]; then
      printf '{"state":{"state":"WAITING_FOR_RESOURCES"}}\n'
    elif [ "${_c}" -eq 2 ]; then
      printf '{"state":{"state":"PROVISIONING"}}\n'
    else
      printf '{"state":{"state":"ACTIVE"}}\n'
    fi
    exit 0
    ;;
  *"queued-resources delete"*)
    rm -f "${WORK_DIR}/state/qr_exists"
    exit 0
    ;;
  *"tpu-vm describe pod-v4-32"*)
    printf '{"name":"projects/p/locations/us-central2-b/nodes/pod-v4-32","acceleratorType":"v4-32","runtimeVersion":"tpu-ubuntu2204-base","schedulingConfig":{"spot":true},"networkEndpoints":[{"ipAddress":"10.0.0.2"},{"ipAddress":"10.0.0.3"},{"ipAddress":"10.0.0.4"},{"ipAddress":"10.0.0.5"}]}\n'
    exit 0
    ;;
  *"tpu-vm describe"*)
    [ -f "${WORK_DIR}/state/vm_exists" ] || exit 1
    printf '{"name":"projects/p/locations/us-central2-b/nodes/node-1","state":"READY","acceleratorType":"v6e-8","runtimeVersion":"v2-alpha-tpuv6e","schedulingConfig":{"spot":true},"networkEndpoints":[{"ipAddress":"10.128.0.10"}]}\n'
    exit 0
    ;;
  *"tpu-vm delete"*)
    rm -f "${WORK_DIR}/state/vm_exists"
    exit 0
    ;;
  *"tpu-vm ssh"*"tar -xzf /tmp/libscript_repo_sync.tar.gz"*)
    _h=$(printf '%s' "$*" | sed -n "s/.*> [^ ]*\.libscript_sync\.sha256.*/FOUND/p")
    _h=$(printf '%s' "$*" | awk -F"'" '{print $(NF-1)}')
    if [ -n "${_h}" ]; then
      printf '%s\n' "${_h}" > "${WORK_DIR}/state/remote_sync_hash"
    fi
    exit 0
    ;;
  *"tpu-vm ssh"*".libscript_sync.sha256"*)
    if [ -f "${WORK_DIR}/state/remote_sync_hash" ]; then
      cat "${WORK_DIR}/state/remote_sync_hash"
    else
      printf 'MISSING\n'
    fi
    exit 0
    ;;
  *"tpu-vm ssh"*|*"tpu-vm scp"*)
    exit 0
    ;;
esac
exit 0
MOCK_EOF
chmod +x "${WORK_DIR}/bin/gcloud"
PATH="${WORK_DIR}/bin:${PATH}"
export PATH

TPU_CLI="${LIBSCRIPT_ROOT_DIR}/_lib/cloud-providers/gcp-tpu-vm/cli.sh"
GCP_PROJECT_ID='trc-test-proj'
TPU_ZONE='us-central1-a'
TPU_ACCELERATOR_TYPE='v6e-8'
TPU_SCHEDULING_TYPE='spot'
export GCP_PROJECT_ID TPU_ZONE TPU_ACCELERATOR_TYPE TPU_SCHEDULING_TYPE

# ## run_qr_multihost_tests
# Validates runtime auto-resolution, Queued Resource idempotency, topology-info, sync-repo skip, arm-ttl, release-locks, and delete cleanup.
run_qr_multihost_tests() {
  # 1. Create via Queued Resource (2x idempotent) + auto runtime v2-alpha-tpuv6e
  TPU_USE_QUEUED_RESOURCE='true' "${TPU_CLI}" create node-1
  grep -q -- '--runtime-version=v2-alpha-tpuv6e' "${GCLOUD_LOG}"
  _creates_1=$(grep -c 'queued-resources create' "${GCLOUD_LOG}")
  TPU_USE_QUEUED_RESOURCE='true' "${TPU_CLI}" create node-1
  _creates_2=$(grep -c 'queued-resources create' "${GCLOUD_LOG}")
  [ "${_creates_1}" -eq 1 ] && [ "${_creates_2}" -eq 1 ]

  # 2. wait-ready transitions WAITING_FOR_RESOURCES -> PROVISIONING -> ACTIVE
  printf '0\n' > "${WORK_DIR}/state/poll_cnt"
  TPU_WAIT_POLL_SEC='0' "${TPU_CLI}" wait-ready node-1

  # 3. topology-info for 1-worker (node-1) and 4-worker (pod-v4-32)
  _t1=$("${TPU_CLI}" topology-info node-1)
  [ "$(printf '%s' "${_t1}" | jq -r '.worker_count')" = '1' ]
  [ "$(printf '%s' "${_t1}" | jq -r '.worker0_internal_ip')" = '10.128.0.10' ]

  _t4=$("${TPU_CLI}" topology-info pod-v4-32)
  [ "$(printf '%s' "${_t4}" | jq -r '.worker_count')" = '4' ]
  [ "$(printf '%s' "${_t4}" | jq -r '.worker_ips')" = '10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.5' ]

  # 4. scp --all-workers and ssh --all-workers --forward-port (zero empty args)
  "${TPU_CLI}" scp node-1 "${WORK_DIR}/sample_repo/main.py" './main.py' --all-workers
  grep -q 'tpu-vm scp --worker=all' "${GCLOUD_LOG}"
  "${TPU_CLI}" ssh node-1 --all-workers --forward-port 6006:6006 'echo ok'
  grep -q -- '--worker=all --ssh-flag=-L6006:6006' "${GCLOUD_LOG}"
  if grep -q 'EMPTY_ARG_ERROR' "${GCLOUD_LOG}"; then exit 1; fi

  # 5. sync-repo transfers once and skips on 2nd run when tree hash matches
  "${TPU_CLI}" sync-repo node-1 "${WORK_DIR}/sample_repo" './workspace' --all-workers
  _scp_1=$(grep -c 'libscript_repo_sync.tar.gz' "${GCLOUD_LOG}")
  "${TPU_CLI}" sync-repo node-1 "${WORK_DIR}/sample_repo" './workspace' --all-workers
  _scp_2=$(grep -c 'libscript_repo_sync.tar.gz' "${GCLOUD_LOG}")
  [ "${_scp_1}" -eq 2 ] && [ "${_scp_2}" -eq 2 ]

  # 6. arm-ttl (2x idempotent replacement) and release-locks
  "${TPU_CLI}" arm-ttl node-1 --minutes 90
  "${TPU_CLI}" arm-ttl node-1 --minutes 120
  "${TPU_CLI}" release-locks node-1

  # 7. delete cleans up BOTH -qr and tpu-vm even when TPU_USE_QUEUED_RESOURCE is unset, and 2x delete exits 0
  unset TPU_USE_QUEUED_RESOURCE || true
  "${TPU_CLI}" delete node-1
  [ ! -f "${WORK_DIR}/state/qr_exists" ] && [ ! -f "${WORK_DIR}/state/vm_exists" ]
  "${TPU_CLI}" delete node-1

  printf '[PASS] All hermetic GCP TPU VM Queued Resource & multi-host tests passed!\n'
}

run_qr_multihost_tests
