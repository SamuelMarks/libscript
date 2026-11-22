#!/bin/sh
# ## Overview
# Regression test suite verifying adherence to LibScript engineering standards,
# zero-dependency C11 ELF patching, Tier 3.5/4 idempotency, and audit rules.
# ## Usage
# ./tests/test_standards_adherence.sh

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

TEST_TMP=$(mktemp -d "${TMPDIR:-/tmp}/ls_std_test.XXXXXX")
trap 'rm -rf -- "${TEST_TMP}"' EXIT HUP INT QUIT TERM

# ## fail_test
# Prints an error diagnostic and terminates the test suite with exit code 1.
fail_test() {
  printf '[FAIL] %s\n' "$1" >&2
  exit 1
}

printf '%s\n' '=== 1. Test Zero-Dependency C11 ELF64 .gnu.version_r Patcher ==='
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/engine/common/elf_verneed_patch.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true

_cc="$(command -v gcc 2>/dev/null || command -v clang 2>/dev/null || command -v cc 2>/dev/null || true)"
if [ -n "$_cc" ]; then
  cat << 'EOF_GEN_ELF' > "${TEST_TMP}/gen_elf.c"
#include <stdint.h>
#include <stdio.h>
#include <string.h>

static void wr16(uint8_t *p, uint16_t v) { p[0] = (uint8_t)v; p[1] = (uint8_t)(v >> 8); }
static void wr32(uint8_t *p, uint32_t v) { p[0] = (uint8_t)v; p[1] = (uint8_t)(v >> 8); p[2] = (uint8_t)(v >> 16); p[3] = (uint8_t)(v >> 24); }
static void wr64(uint8_t *p, uint64_t v) { wr32(p, (uint32_t)v); wr32(p + 4, (uint32_t)(v >> 32)); }

int main(int argc, char **argv) {
    uint8_t buf[512];
    FILE *f;
    if (argc < 2) return 1;
    memset(buf, 0, sizeof(buf));
    memcpy(buf, "\x7f""ELF", 4);
    buf[4] = 2; /* 64-bit */
    buf[5] = 1; /* little-endian */
    wr64(buf + 40, 64); /* e_shoff */
    wr16(buf + 58, 64); /* e_shentsize */
    wr16(buf + 60, 2);  /* e_shnum: [0]=dynstr, [1]=verneed */

    /* Section 0: .dynstr at offset 256 */
    wr32(buf + 64 + 4, 3);
    wr64(buf + 64 + 24, 256);
    memcpy(buf + 256 + 1, "libc.so.6", 10);
    memcpy(buf + 256 + 16, "GLIBC_2.35", 11);

    /* Section 1: .gnu.version_r at offset 320, sh_link=0, sh_info=1 */
    wr32(buf + 128 + 4, 0x6ffffffe);
    wr64(buf + 128 + 24, 320);
    wr32(buf + 128 + 40, 0);
    wr32(buf + 128 + 44, 1);

    /* Elf64_Verneed at 320, Elf64_Vernaux at 336 */
    wr16(buf + 320 + 0, 1);
    wr16(buf + 320 + 2, 1);
    wr32(buf + 320 + 4, 1);
    wr32(buf + 320 + 8, 16);
    wr32(buf + 320 + 12, 0);
    wr32(buf + 336 + 0, 0x069691b5u);
    wr32(buf + 336 + 8, 16);
    wr32(buf + 336 + 12, 0);

    f = fopen(argv[1], "wb");
    if (!f) return 1;
    fwrite(buf, 1, sizeof(buf), f);
    fclose(f);
    return 0;
}
EOF_GEN_ELF
  "$_cc" -O2 "${TEST_TMP}/gen_elf.c" -o "${TEST_TMP}/gen_elf"
  "${TEST_TMP}/gen_elf" "${TEST_TMP}/sample.elf"
  libscript_patch_elf_verneed "${TEST_TMP}/sample.elf" "GLIBC_2.35=GLIBC_2.29"
  if strings "${TEST_TMP}/sample.elf" 2>/dev/null | grep -q 'GLIBC_2.35'; then
    fail_test 'Expected GLIBC_2.35 to be rewritten to GLIBC_2.29 in sample.elf'
  fi
  strings "${TEST_TMP}/sample.elf" 2>/dev/null | grep -q 'GLIBC_2.29' || fail_test 'Expected GLIBC_2.29 in patched sample.elf'
fi

printf '%s\n' '=== 2. Test Topology Engine 2x Idempotency, Scale, Drain, Failover, Upgrade, Destroy ==='
cat << 'EOF_TOPO' > "${TEST_TMP}/topo.json"
{
  "name": "std-test-cluster",
  "substrate": { "provider": "local" },
  "node_groups": [
    { "name": "leader", "count": 1, "role": "leader" },
    { "name": "db", "count": 2, "role": "follower" }
  ],
  "choreography": {
    "pre_provision": ["printf ok"]
  }
}
EOF_TOPO
LIBSCRIPT_TOPOLOGY_STATE_DIR="${TEST_TMP}/topo_state"
export LIBSCRIPT_TOPOLOGY_STATE_DIR
STACK="" "${LIBSCRIPT_ROOT_DIR}/workloads/constellations/engine.sh" up "${TEST_TMP}/topo.json" >/dev/null
STACK="" "${LIBSCRIPT_ROOT_DIR}/workloads/constellations/engine.sh" up "${TEST_TMP}/topo.json" >/dev/null
STACK="" "${LIBSCRIPT_ROOT_DIR}/workloads/constellations/engine.sh" scale "${TEST_TMP}/topo.json" db=3 >/dev/null
_cnt=$(jq '[.nodes[] | select(.group=="db")] | length' "${LIBSCRIPT_TOPOLOGY_STATE_DIR}/.topology_state.json")
[ "$_cnt" = "3" ] || fail_test "Expected 3 db nodes after scale, got ${_cnt}"
STACK="" "${LIBSCRIPT_ROOT_DIR}/workloads/constellations/engine.sh" drain "${TEST_TMP}/topo.json" db-2 >/dev/null
_dr=$(jq -r '.nodes[] | select(.id=="db-2") | .state' "${LIBSCRIPT_TOPOLOGY_STATE_DIR}/.topology_state.json")
[ "$_dr" = "DRAINED" ] || fail_test "Expected db-2 DRAINED, got ${_dr}"
STACK="" "${LIBSCRIPT_ROOT_DIR}/workloads/constellations/engine.sh" failover "${TEST_TMP}/topo.json" leader-0 >/dev/null
_fn=$(jq -r '.nodes[] | select(.id=="leader-0") | .state' "${LIBSCRIPT_TOPOLOGY_STATE_DIR}/.topology_state.json")
[ "$_fn" = "FENCED" ] || fail_test "Expected leader-0 FENCED after failover, got ${_fn}"
STACK="" "${LIBSCRIPT_ROOT_DIR}/workloads/constellations/engine.sh" upgrade "${TEST_TMP}/topo.json" >/dev/null
STACK="" "${LIBSCRIPT_ROOT_DIR}/workloads/constellations/engine.sh" destroy "${TEST_TMP}/topo.json" >/dev/null
STACK="" "${LIBSCRIPT_ROOT_DIR}/workloads/constellations/engine.sh" destroy "${TEST_TMP}/topo.json" >/dev/null

printf '%s\n' '=== 3. Test Payload Schedulers (native, nomad, slurm_ray) ==='
cat << 'EOF_PAY' > "${TEST_TMP}/payload.json"
{
  "name": "demo-worker",
  "type": "service",
  "artifact": { "format": "oci-image", "image": "alpine:3.20", "entrypoint": ["/bin/echo", "ok"] },
  "resources": { "cpu_cores": 2, "memory_mb": 512, "gpu_count": 1 },
  "scaling": { "replicas": 2 }
}
EOF_PAY
STACK="" "${LIBSCRIPT_ROOT_DIR}/workloads/schedulers/native.sh" compile "${TEST_TMP}/payload.json" --init sc | grep -q 'sc.exe create "LibScript-demo-worker"' || fail_test 'native.sh --init sc failed'
STACK="" "${LIBSCRIPT_ROOT_DIR}/workloads/schedulers/nomad.sh" compile "${TEST_TMP}/payload.json" | jq -e '.Job.ID == "demo-worker"' >/dev/null || fail_test 'nomad.sh compile failed'
STACK="" "${LIBSCRIPT_ROOT_DIR}/workloads/schedulers/slurm_ray.sh" compile "${TEST_TMP}/payload.json" | grep -q '#SBATCH --job-name=demo-worker' || fail_test 'slurm_ray.sh compile failed'

printf '%s\n' '=== 4. Test Experiment Scaffold 2x Idempotency ==='
STACK="" "${LIBSCRIPT_ROOT_DIR}/experiments/cli/scaffold.sh" demo-std-suite --out-root="${TEST_TMP}/exps" >/dev/null
_skip_out=$(STACK="" "${LIBSCRIPT_ROOT_DIR}/experiments/cli/scaffold.sh" demo-std-suite --out-root="${TEST_TMP}/exps")
case "$_skip_out" in
  *'[SKIP]'*) ;;
  *) fail_test "Expected [SKIP] on 2nd scaffold invocation, got: ${_skip_out}" ;;
esac

printf '%s\n' '=== 5. Test Audit Rule Rejections & Cross-Platform 6-Tier Parity ==='
if grep -q 'has_dirname_z0' "${LIBSCRIPT_ROOT_DIR}/devtools/audit/audit_posix.sh"; then
  :
else
  fail_test 'Expected has_dirname_z0 rule in audit_posix.sh'
fi
if grep -qE '_lib/\(_common|web-apps/\.\*/|orchestration/distro/' "${LIBSCRIPT_ROOT_DIR}/devtools/audit/audit_standards.ps1"; then
  fail_test 'Stale 5-tier allowlist regex found in devtools/audit/audit_standards.ps1'
fi
if grep -qE '_lib!_BS!_common|topologies!_BS!engine\.cmd|payloads!_BS!schedulers|cli!_BS!commands!_BS!experiment' "${LIBSCRIPT_ROOT_DIR}/tests/test_standards_adherence.cmd"; then
  fail_test 'Stale 5-tier path found in tests/test_standards_adherence.cmd'
fi
if grep -q 'synthesis\\msi\\/' "${LIBSCRIPT_ROOT_DIR}/synthesis/msi/harvest_payload.cmd"; then
  fail_test 'Malformed gawk \m escape found in synthesis/msi/harvest_payload.cmd'
fi
for _req_pat in \
  'engine/common/(pkg_mgr|daemonize)' \
  'workloads/apps/.*/(test_harness|health.*|service)' \
  'synthesis/distro/linux/' \
  'workloads/services/' \
  'engine/common/(service|service_install|daemonize)\.cmd' \
  'engine/common/pkg_mgr\.ps1'; do
  grep -qF "$_req_pat" "${LIBSCRIPT_ROOT_DIR}/devtools/audit/audit_standards.ps1" || fail_test "Missing 6-tier allowlist pattern ${_req_pat} in audit_standards.ps1"
done
_t1_iptables=$(awk '/^### T1:/{in_t1=1;next} /^### T2:/{in_t1=0} in_t1 && /\| `iptables`[[:space:]]*\|/{print}' "${LIBSCRIPT_ROOT_DIR}/README.md")
_t2_iptables=$(awk '/^### T2:/{in_t2=1;next} /^### T[345]:/{in_t2=0} in_t2 && /\| `iptables`[[:space:]]*\|/{print}' "${LIBSCRIPT_ROOT_DIR}/README.md")
[ -z "$_t1_iptables" ] || fail_test 'Expected iptables not to appear under T1 in README.md'
[ -n "$_t2_iptables" ] || fail_test 'Expected iptables under T2 in README.md'

printf '%s\n' '[PASS] All standards adherence regression tests succeeded.'
exit 0
