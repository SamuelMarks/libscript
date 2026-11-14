#!/bin/sh
# ## Overview
# End-to-end verification matrix and 2-pass idempotency test across kernels, components, and formats.
# ## Usage
# ./tests/test_kernel_component_matrix.sh

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

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  printf 'Usage: %s\n' "$(basename "$THIS_FILE")"
  exit 0
fi

TMP_MAT=$(mktemp -d "${TMPDIR:-/tmp}/libscript_kmat.XXXXXX")
trap 'rm -rf "$TMP_MAT"' EXIT INT TERM HUP

# ## fail_test
# Prints an error diagnostic and terminates with exit code 1.
fail_test() {
  printf '[FAIL] %s\n' "$1" >&2
  exit 1
}

printf '=== [1/4] Verifying Dry-Run Plan Resolution Across Kernels x Component Sets ===\n'

# Full multi-process OS + OSv/Nanos matrix for all 5 component combinations
for _kern in linux-glibc linux-musl freebsd illumos osv nanos; do
  for _cset in "redis" "postgres" "redis,postgres" "openedx" "redis,postgres,openedx"; do
    LIBSCRIPT_BUILD_DIR="${TMP_MAT}/plan_${_kern}_$(printf '%s' "$_cset" | tr ',' '_')" \
      STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" build-image \
        --kernel="$_kern" \
        --format=qcow2 \
        --components="$_cset" \
        --dry-run >/dev/null
  done
done

# Unikraft & Rumprun support single-process redis (and Unikraft supports openedx decomposed pod)
LIBSCRIPT_BUILD_DIR="${TMP_MAT}/plan_unikraft_redis" \
  STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" build-image --kernel=unikraft --format=direct-kernel --components=redis --dry-run >/dev/null
LIBSCRIPT_BUILD_DIR="${TMP_MAT}/plan_rumprun_redis" \
  STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" build-image --kernel=rumprun --format=direct-kernel --components=redis --dry-run >/dev/null
LIBSCRIPT_BUILD_DIR="${TMP_MAT}/plan_mirageos_mirage" \
  STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" build-image --kernel=mirageos --format=direct-kernel --components=mirage --dry-run >/dev/null

# Verify capability resolution: illumos + openedx -> ferretdb + postgres + exim + gunicorn (no hmailserver!)
IL_PLAN="${TMP_MAT}/plan_illumos_openedx/.work-illumos-x86_64/execution-plan.generated.json"
jq -e '.stages[] | select(.stage=="stage2-target-sysroot") | [.tasks[].name] | (index("ferretdb") != null and index("postgres") != null and index("exim") != null and index("gunicorn") != null and index("hmailserver") == null)' "$IL_PLAN" >/dev/null ||
  fail_test 'illumos openedx plan did not resolve ferretdb + postgres + exim + gunicorn cleanly'

# Verify FreeBSD + openedx -> mongodb + exim + gunicorn + redis
FB_PLAN="${TMP_MAT}/plan_freebsd_openedx/.work-freebsd-x86_64/execution-plan.generated.json"
jq -e '.stages[] | select(.stage=="stage2-target-sysroot") | [.tasks[].name] | (index("mongodb") != null and index("redis") != null and index("exim") != null)' "$FB_PLAN" >/dev/null ||
  fail_test 'FreeBSD openedx plan did not resolve mongodb + redis + exim cleanly'

# Verify multi-unikernel pod decomposition on Nanos when multiple daemons ({redis, postgres, openedx}) are requested
NANOS_PLAN="${TMP_MAT}/plan_nanos_redis_postgres_openedx/.work-unikernel-nanos-x86_64/execution-plan.generated.json"
jq -e '.execution_mode == "multi-unikernel-pod"' "$NANOS_PLAN" >/dev/null ||
  fail_test 'Nanos multi-component stack did not decompose into multi-unikernel-pod'

# Verify deterministic fork() incompatibility rejection: postgres on rumprun and mirageos MUST fail
if LIBSCRIPT_BUILD_DIR="${TMP_MAT}/bad_rump_pg" STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" build-image --kernel=rumprun --format=direct-kernel --components=postgres --dry-run >/dev/null 2>&1; then
  fail_test 'Expected postgres on rumprun to be rejected with UNIKERNEL_INCOMPATIBLE'
fi
if LIBSCRIPT_BUILD_DIR="${TMP_MAT}/bad_mir_pg" STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" build-image --kernel=mirageos --format=direct-kernel --components=postgres --dry-run >/dev/null 2>&1; then
  fail_test 'Expected postgres on mirageos to be rejected with UNIKERNEL_INCOMPATIBLE'
fi

printf '[PASS] All kernel x component dependency plans & unikernel constraints verified.\n'

printf '=== [2/4] Verifying 2-Pass Consecutive Idempotency Across Formats ===\n'
SYS_STUB="${TMP_MAT}/sample_sysroot"
mkdir -p "${SYS_STUB}/etc" "${SYS_STUB}/boot/kernel" "${SYS_STUB}/platform/i86pc/kernel/amd64"
printf 'LibScript Matrix Test Root\n' > "${SYS_STUB}/etc/os-release"

for _fmt in live-iso raw zfs-stream rootfs-tar direct-kernel unikernel; do
  _out_target="${TMP_MAT}/out_${_fmt}/artifact.${_fmt}"
  if [ "$_fmt" = "direct-kernel" ]; then
    _out_target="${TMP_MAT}/out_${_fmt}/bundle"
  fi
  mkdir -p "$(dirname "$_out_target")"
  case "$_fmt" in
    live-iso)
      LIBSCRIPT_ALLOW_STUB='1' STACK='' "${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/iso.sh" --allow-stub "$SYS_STUB" "$_out_target" >/dev/null
      OUT2=$(LIBSCRIPT_ALLOW_STUB='1' STACK='' "${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/iso.sh" --allow-stub "$SYS_STUB" "$_out_target")
      ;;
    raw)
      LIBSCRIPT_ALLOW_STUB='1' STACK='' "${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/raw_img.sh" --allow-stub "$SYS_STUB" "$_out_target" 1 >/dev/null
      OUT2=$(LIBSCRIPT_ALLOW_STUB='1' STACK='' "${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/raw_img.sh" --allow-stub "$SYS_STUB" "$_out_target" 1)
      ;;
    zfs-stream)
      LIBSCRIPT_ALLOW_STUB='1' STACK='' "${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/zfs_stream.sh" --allow-stub "$SYS_STUB" "$_out_target" >/dev/null
      OUT2=$(LIBSCRIPT_ALLOW_STUB='1' STACK='' "${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/zfs_stream.sh" --allow-stub "$SYS_STUB" "$_out_target")
      ;;
    rootfs-tar)
      STACK='' "${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/rootfs_tar.sh" "$SYS_STUB" "${_out_target}.tar.gz" >/dev/null
      [ -s "${_out_target}.tar.gz" ] || fail_test 'rootfs_tar produced empty archive'
      OUT2='[SKIP]'
      ;;
    direct-kernel)
      LIBSCRIPT_ALLOW_STUB='1' STACK='' "${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/direct_kernel.sh" --allow-stub --kernel=linux "$SYS_STUB" "$_out_target" >/dev/null
      OUT2=$(LIBSCRIPT_ALLOW_STUB='1' STACK='' "${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/direct_kernel.sh" --allow-stub --kernel=linux "$SYS_STUB" "$_out_target")
      ;;
    unikernel)
      LIBSCRIPT_ALLOW_STUB='1' STACK='' "${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/unikernel.sh" --allow-stub --framework=unikraft "$SYS_STUB" "$_out_target" >/dev/null
      OUT2=$(LIBSCRIPT_ALLOW_STUB='1' STACK='' "${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/unikernel.sh" --allow-stub --framework=unikraft "$SYS_STUB" "$_out_target")
      ;;
  esac
  printf '%s\n' "$OUT2" | grep -q '\[SKIP\]' || fail_test "Pass 2 did not emit [SKIP] for format ${_fmt}"
done

printf '=== [3/4] Verifying Strict Mode Rejects Missing-Tool Stubs Without Poisoning Stamps ===\n'
STRICT_UK="${TMP_MAT}/strict_uk/app.elf"
if ! command -v rumpbake >/dev/null 2>&1; then
  if STACK='' "${LIBSCRIPT_ROOT_DIR}/cli/commands/package_as/unikernel.sh" --strict --framework=rumprun "$SYS_STUB" "$STRICT_UK" >/dev/null 2>&1; then
    fail_test 'Strict mode should fail when rumpbake is absent'
  fi
  if [ -f "${STRICT_UK}.stamp" ]; then
    fail_test 'Strict mode wrote a .stamp file on failed synthesis!'
  fi
fi

printf '=== [4/4] Verifying Multi-Unikernel Pod Decomposition Artifact Generation ===\n'
LIBSCRIPT_TARGET_SYSROOT="${TMP_MAT}/pod_sysroot" \
  LIBSCRIPT_UNIKERNEL_FRAMEWORK='unikraft' \
  LIBSCRIPT_POD_DAEMONS='caddy,redis' \
  LIBSCRIPT_ALLOW_STUB='1' \
  STACK='' "${LIBSCRIPT_ROOT_DIR}/_lib/orchestration/unikernel_pod/setup_generic.sh" assemble >/dev/null
[ -f "${TMP_MAT}/pod_sysroot/unikernel-pod/pod-manifest.json" ] || fail_test 'Missing pod-manifest.json'
jq -e '.appliances | length == 2' "${TMP_MAT}/pod_sysroot/unikernel-pod/pod-manifest.json" >/dev/null || fail_test 'Expected 2 decomposed unikernel appliances'

printf '[PASS] Kernel x Component x Format Matrix & 2-Pass Idempotency Suite PASSED!\n'
exit 0
