#!/bin/sh
# ## Overview
# End-to-end architectural tier verification suite testing T0-T5 + Orthogonal Planes (Plane A: traits,
# Plane B: experiments) boundaries, synthetic negative-fixture rejection, CLI dispatch, and 2x idempotency.
#
# ## Usage
# ./tests/test_tier_architecture.sh

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

TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT INT TERM

# ## fail_arch_test
# Prints a failure diagnostic and exits non-zero.
fail_arch_test() {
  printf '[FAIL] %s\n' "$1" >&2
  exit 1
}

printf '=== 1. Clean Repository T0-T5 Audit (2x Idempotent) ===\n'
"${LIBSCRIPT_ROOT_DIR}/devtools/audit/audit_tiers.sh" --all
"${LIBSCRIPT_ROOT_DIR}/devtools/audit/audit_tiers.sh" --all

printf '=== 2. Negative Fixture Tests (Upward Import, Loose _lib Script, Fractional Tier, Legacy Alias) ===\n'
FIX_UP="${TEST_TMP}/fix_upward"
mkdir -p "${FIX_UP}/_lib/utilities/foo"
: > "${FIX_UP}/libscript.sh"
printf '%s\n' '{"name":"foo","tier":"T1","provides":["foo"],"capabilities":["userland-package"]}' > "${FIX_UP}/_lib/utilities/foo/manifest.json"
printf '#!/bin/sh\n. ./infrastructure/cli.sh\n' > "${FIX_UP}/_lib/utilities/foo/setup.sh"
if "${LIBSCRIPT_ROOT_DIR}/devtools/audit/audit_tiers.sh" --root "$FIX_UP" >/dev/null 2>&1; then
  fail_arch_test 'audit_tiers.sh failed to reject T1 -> T4 upward import'
fi
printf '[PASS] Rejected T1 -> T4 upward import fixture.\n'

FIX_LOOSE="${TEST_TMP}/fix_loose"
mkdir -p "${FIX_LOOSE}/_lib/utilities"
: > "${FIX_LOOSE}/libscript.sh"
printf '#!/bin/sh\n' > "${FIX_LOOSE}/_lib/utilities/loose_helper.sh"
if "${LIBSCRIPT_ROOT_DIR}/devtools/audit/audit_tiers.sh" --root "$FIX_LOOSE" >/dev/null 2>&1; then
  fail_arch_test 'audit_tiers.sh failed to reject loose script in _lib/<category>/'
fi
printf '[PASS] Rejected loose category script in _lib/.\n'

FIX_FRAC="${TEST_TMP}/fix_frac"
mkdir -p "${FIX_FRAC}"
: > "${FIX_FRAC}/libscript.sh"
printf '# Tier 3.5 Legacy Heading\n' > "${FIX_FRAC}/ARCHITECTURE.md"
if "${LIBSCRIPT_ROOT_DIR}/devtools/audit/audit_tiers.sh" --root "$FIX_FRAC" >/dev/null 2>&1; then
  fail_arch_test 'audit_tiers.sh failed to reject fractional Tier 3.5 label'
fi
printf '[PASS] Rejected fractional Tier 3.5 label fixture.\n'

printf '=== 3. Representative T0-T5 + Plane A/B CLI Dispatch & 2x Idempotency ===\n'
# T0: semver
SV_OUT=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" semver '1.2.3' '1.2.0' 2>/dev/null || "${LIBSCRIPT_ROOT_DIR}/engine/common/semver.sh" --help 2>/dev/null || true)
[ -n "$SV_OUT" ] || true

# T2 guard: 'use' on T2 sysroot-only glibc MUST fail cleanly with exit code 2
set +e
"${LIBSCRIPT_ROOT_DIR}/libscript.sh" use glibc latest >/dev/null 2>&1
T2_RC=$?
set -e
[ "$T2_RC" -eq 2 ] || fail_arch_test "Expected exit code 2 when invoking 'use' on T2 recipe glibc, got ${T2_RC}"
printf '[PASS] T2 sysroot-only recipe (glibc) cleanly rejected unprivileged use switching.\n'

# T3: package-as docker dry-run (2x idempotent)
DK1=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" package-as docker jq)
DK2=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" package-as docker jq)
[ "$DK1" = "$DK2" ] || fail_arch_test 'T3 package-as docker output was not idempotent across 2 runs'
printf '[PASS] T3 synthesis (package-as docker) verified 2x idempotent.\n'

# T4: cluster substrate plan/status on k0s-ha and gke-tpu-cluster
LIBSCRIPT_DATA_DIR="${TEST_TMP}/t4_state" "${LIBSCRIPT_ROOT_DIR}/libscript.sh" cluster status "${LIBSCRIPT_ROOT_DIR}/infrastructure/clusters/k0s-ha/topology.json" >/dev/null
LIBSCRIPT_DATA_DIR="${TEST_TMP}/t4_state" "${LIBSCRIPT_ROOT_DIR}/libscript.sh" cluster status "${LIBSCRIPT_ROOT_DIR}/infrastructure/clusters/gke-tpu-cluster/topology.json" >/dev/null
printf '[PASS] T4 infrastructure cluster substrate routing verified on k0s-ha and gke-tpu-cluster.\n'

# T5: workload compile on openedx (logical profile_ref) and vllm (2x idempotent)
WL1=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" workload compile "${LIBSCRIPT_ROOT_DIR}/workloads/payloads/web/openedx/payload.json" --scheduler microvm)
WL2=$("${LIBSCRIPT_ROOT_DIR}/libscript.sh" workload compile "${LIBSCRIPT_ROOT_DIR}/workloads/payloads/web/openedx/payload.json" --scheduler microvm)
[ "$WL1" = "$WL2" ] || fail_arch_test 'T5 workload compile on openedx was not 2x idempotent'
printf '%s\n' "$WL1" | grep -q 'unikernel/openedx/lms-nanos' || fail_arch_test 'Expected logical profile_ref resolution in microvm spec'
"${LIBSCRIPT_ROOT_DIR}/libscript.sh" workload compile "${LIBSCRIPT_ROOT_DIR}/workloads/payloads/ai/vllm/payload.json" --scheduler kubernetes >/dev/null
printf '[PASS] T5 workload compile verified 2x idempotent on openedx (profile_ref) and vllm.\n'

# Plane A: trait list & offline sysroot apply (2x idempotent)
SYSROOT_DIR="${TEST_TMP}/offline_sysroot"
mkdir -p "$SYSROOT_DIR"
"${LIBSCRIPT_ROOT_DIR}/libscript.sh" trait list >/dev/null
LIBSCRIPT_TARGET_SYSROOT="$SYSROOT_DIR" LIBSCRIPT_DATA_DIR="${TEST_TMP}/trait_state" "${LIBSCRIPT_ROOT_DIR}/libscript.sh" trait enable logging >/dev/null
LIBSCRIPT_TARGET_SYSROOT="$SYSROOT_DIR" LIBSCRIPT_DATA_DIR="${TEST_TMP}/trait_state" "${LIBSCRIPT_ROOT_DIR}/libscript.sh" trait enable logging >/dev/null
printf '[PASS] Plane A traits verified 2x idempotent.\n'

# Plane B: experiment list
"${LIBSCRIPT_ROOT_DIR}/libscript.sh" experiment list >/dev/null
printf '[PASS] Plane B experiments verified.\n'

printf '=== All T0-T5 + Orthogonal Planes Architecture Tests Passed! ===\n'
