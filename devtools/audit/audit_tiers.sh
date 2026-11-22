#!/bin/sh
# ## Overview
# Audits LibScript's T0-T5 + Orthogonal Planes (Plane A: traits, Plane B: experiments) architecture,
# enforcing unidirectional downward-only imports, atomic _lib/ purity, zero fractional tiers, and zero legacy aliases.
#
# ## Usage
# ./devtools/audit/audit_tiers.sh [--all|--staged] [--root <repo_dir>]

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
    if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2; fi
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) if [ "${LIBSCRIPT_DEBUG:-0}" = '1' ]; then printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2; fi ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

TARGET_ROOT="$LIBSCRIPT_ROOT_DIR"
while [ $# -gt 0 ]; do
  case "$1" in
    --all|--staged) shift ;;
    --root) TARGET_ROOT="$2"; shift 2 ;;
    --root=*) TARGET_ROOT="${1#*=}"; shift ;;
    --help|-h)
      printf '%s\n' 'Usage: ./devtools/audit/audit_tiers.sh [--all|--staged] [--root <repo_dir>]'
      exit 0
      ;;
    *) shift ;;
  esac
done

ERRORS=0

# ## log_tier_violation
# Records and prints a structured architectural tier violation.
log_tier_violation() {
  _ltv_rule="$1"
  _ltv_path="$2"
  _ltv_msg="$3"
  printf '[TIER VIOLATION] [%s] %s: %s\n' "$_ltv_rule" "$_ltv_path" "$_ltv_msg" >&2
  ERRORS=$((ERRORS + 1))
}

# ## check_no_legacy_aliases
# Verifies deleted legacy directories and normalize_component_alias shims never reappear.
check_no_legacy_aliases() {
  for _leg_dir in \
    _lib/_common \
    _lib/orchestration \
    _lib/web-apps \
    _lib/cloud-providers \
    _lib/cloud \
    _lib/ai-serving \
    _lib/ml-training \
    _lib/storage \
    _lib/freebsd \
    _lib/illumos \
    _lib/reactos \
    topologies \
    payloads \
    profiles \
    packaging \
    marketplace \
    cli/commands/package_as \
    cli/commands/packaging \
    cli/commands/cloud \
    cli/commands/marketplace \
    cli/commands/ml \
    cli/commands/services \
    cli/commands/experiment; do
    if [ -e "${TARGET_ROOT}/${_leg_dir}" ]; then
      log_tier_violation 'NO_LEGACY_ALIASES' "$_leg_dir" 'Deleted legacy directory reappeared; use canonical T0-T5 paths.'
    fi
  done

  for _router in libscript.sh libscript.cmd; do
    if [ -f "${TARGET_ROOT}/${_router}" ] && grep -q 'normalize_component_alias' "${TARGET_ROOT}/${_router}" 2>/dev/null; then
      log_tier_violation 'NO_LEGACY_ALIASES' "$_router" 'Legacy normalize_component_alias redirect table is forbidden.'
    fi
  done
}

# ## check_lib_atomic_purity
# Verifies _lib/ contains exclusively atomic T1/T2 component directories with zero loose scripts or *-suite directories.
check_lib_atomic_purity() {
  [ -d "${TARGET_ROOT}/_lib" ] || return 0
  set +f
  for _top_entry in "${TARGET_ROOT}/_lib"/*; do
    [ -e "$_top_entry" ] || continue
    _bn=$(basename "$_top_entry")
    if [ -f "$_top_entry" ]; then
      case "$_bn" in
        README.md|checksums.txt) ;;
        *) log_tier_violation 'LIB_ATOMIC_PURITY' "_lib/${_bn}" 'Loose file at _lib/ root is forbidden.' ;;
      esac
      continue
    fi
    case "$_bn" in
      _*) log_tier_violation 'LIB_ATOMIC_PURITY' "_lib/${_bn}" 'Underscore helper directory inside _lib/ belongs in T0 engine/.' ; continue ;;
    esac

    for _sub in "$_top_entry"/*; do
      [ -e "$_sub" ] || continue
      _sbn=$(basename "$_sub")
      if [ -f "$_sub" ]; then
        if [ "$_sbn" != 'README.md' ]; then
          log_tier_violation 'LIB_ATOMIC_PURITY' "_lib/${_bn}/${_sbn}" 'Loose category script inside _lib/<category>/ is forbidden; move to T0 engine/ or T3 synthesis/.'
        fi
        continue
      fi
      case "$_sbn" in
        *-suite)
          log_tier_violation 'LIB_ATOMIC_PURITY' "_lib/${_bn}/${_sbn}" 'Experiment suites belong in Plane B experiments/, never in _lib/.'
          ;;
      esac
      if [ -d "${_sub}/suites" ]; then
        log_tier_violation 'LIB_ATOMIC_PURITY' "_lib/${_bn}/${_sbn}/suites" 'Experiment subsuites belong in Plane B experiments/, never in _lib/.'
      fi
      if [ ! -f "${_sub}/manifest.json" ]; then
        log_tier_violation 'LIB_ATOMIC_PURITY' "_lib/${_bn}/${_sbn}" 'Missing manifest.json in atomic _lib/ component.'
      else
        if ! grep -Eq '"tier"[[:space:]]*:[[:space:]]*"(T1|T2)"' "${_sub}/manifest.json" 2>/dev/null; then
          log_tier_violation 'LIB_ATOMIC_PURITY' "_lib/${_bn}/${_sbn}/manifest.json" 'Component manifest.json must declare "tier": "T1" or "T2".'
        fi
        if grep -Eq '"tier"[[:space:]]*:[[:space:]]*"T1"' "${_sub}/manifest.json" 2>/dev/null && [ "$_bn" != 'virtualization' ]; then
          for _setup_sh in "${_sub}"/setup*.sh; do
            [ -f "$_setup_sh" ] || continue
            if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(mount|umount|losetup|fdisk|sfdisk|parted|mkfs(\.[a-z0-9]+)?|cryptsetup)[[:space:]]' "$_setup_sh" 2>/dev/null; then
              log_tier_violation 'LIB_ATOMIC_PURITY' "_lib/${_bn}/${_sbn}/$(basename "$_setup_sh")" 'T1 userland recipe must not invoke raw disk/partition/mount primitives.'
            fi
          done
        fi
      fi
    done
  done
  set -f
}

# ## check_upward_imports
# Enforces strict downward-only tier references (T5 -> T4 -> T3 -> T2 -> T1 -> T0; Plane A -> T0..T2).
check_upward_imports() {
  # T0 engine/{common,schemas,hooks,target,consensus} must not reference T3/T4/T5/Plane A/Plane B
  for _t0_sub in common schemas hooks target consensus; do
    [ -d "${TARGET_ROOT}/engine/${_t0_sub}" ] || continue
    _hits=$(grep -rnE '(^|[^a-zA-Z0-9_-])(synthesis|infrastructure|workloads|traits|experiments)[/\\]' "${TARGET_ROOT}/engine/${_t0_sub}" --include='*.sh' --include='*.cmd' --include='*.ps1' --include='*.json' 2>/dev/null || true)
    if [ -n "$_hits" ]; then
      log_tier_violation 'TIER_UPWARD_IMPORT' "engine/${_t0_sub}" "T0 engine layer references higher tier: $(printf '%s' "$_hits" | head -n 1)"
    fi
  done

  # T1 & T2 (_lib/) must not reference T3 (synthesis/), T4 (infrastructure/), T5 (workloads/), Plane A (traits/), or Plane B (experiments/)
  if [ -d "${TARGET_ROOT}/_lib" ]; then
    _hits=$(grep -rnE '(^|[^a-zA-Z0-9_-])(synthesis|infrastructure|workloads|traits|experiments)[/\\]' "${TARGET_ROOT}/_lib" --include='*.sh' --include='*.cmd' --include='*.ps1' --include='*.json' 2>/dev/null || true)
    if [ -n "$_hits" ]; then
      log_tier_violation 'TIER_UPWARD_IMPORT' '_lib' "T1/T2 recipe layer references higher tier: $(printf '%s' "$_hits" | head -n 1)"
    fi
  fi

  # T3 (synthesis/) must not reference T4 (infrastructure/), T5 runtime/cluster engines (workloads/{constellations,payloads,schedulers,ai,services}), or Plane B (experiments/)
  if [ -d "${TARGET_ROOT}/synthesis" ]; then
    _hits=$(grep -rnE '(^|[^a-zA-Z0-9_-])(infrastructure[/\\]|workloads[/\\](constellations|payloads|schedulers|ai|services)[/\\]|experiments[/\\])' "${TARGET_ROOT}/synthesis" --include='*.sh' --include='*.cmd' --include='*.ps1' --include='*.json' 2>/dev/null || true)
    if [ -n "$_hits" ]; then
      log_tier_violation 'TIER_UPWARD_IMPORT' 'synthesis' "T3 synthesis layer references higher tier: $(printf '%s' "$_hits" | head -n 1)"
    fi
  fi

  # T4 (infrastructure/) must not reference T5 (workloads/) or Plane B (experiments/)
  if [ -d "${TARGET_ROOT}/infrastructure" ]; then
    _hits=$(grep -rnE '(^|[^a-zA-Z0-9_-])(workloads|experiments)[/\\]' "${TARGET_ROOT}/infrastructure" --include='*.sh' --include='*.cmd' --include='*.ps1' --include='*.json' 2>/dev/null || true)
    if [ -n "$_hits" ]; then
      log_tier_violation 'TIER_UPWARD_IMPORT' 'infrastructure' "T4 infrastructure layer references higher tier: $(printf '%s' "$_hits" | head -n 1)"
    fi
  fi

  # T5 (workloads/) must not reference Plane B (experiments/)
  if [ -d "${TARGET_ROOT}/workloads" ]; then
    _hits=$(grep -rnE '(^|[^a-zA-Z0-9_-])experiments[/\\]' "${TARGET_ROOT}/workloads" --include='*.sh' --include='*.cmd' --include='*.ps1' --include='*.json' 2>/dev/null || true)
    if [ -n "$_hits" ]; then
      log_tier_violation 'TIER_UPWARD_IMPORT' 'workloads' "T5 workloads layer references Plane B experiments/: $(printf '%s' "$_hits" | head -n 1)"
    fi
  fi

  # Plane A (traits/) must not reference T3 (synthesis/), T4 (infrastructure/), T5 (workloads/), or Plane B (experiments/)
  if [ -d "${TARGET_ROOT}/traits" ]; then
    _hits=$(grep -rnE '(^|[^a-zA-Z0-9_-])(synthesis|infrastructure|workloads|experiments)[/\\]' "${TARGET_ROOT}/traits" --include='*.sh' --include='*.cmd' --include='*.ps1' --include='*.json' 2>/dev/null || true)
    if [ -n "$_hits" ]; then
      log_tier_violation 'TIER_UPWARD_IMPORT' 'traits' "Plane A traits/ references T3/T4/T5/Plane B: $(printf '%s' "$_hits" | head -n 1)"
    fi
  fi
}

# ## check_no_fractional_tiers
# Rejects stale fractional tier labels (Tier 1.5, Tier 3.5) across schemas, manifests, routers, and core docs.
check_no_fractional_tiers() {
  for _scan in engine _lib synthesis infrastructure workloads traits cli libscript.sh libscript.cmd ARCHITECTURE.md README.md; do
    [ -e "${TARGET_ROOT}/${_scan}" ] || continue
    _hits=$(grep -rnE 'Tier[[:space:]]+(1\.5|3\.5)' "${TARGET_ROOT}/${_scan}" --include='*.json' --include='*.sh' --include='*.cmd' --include='*.md' 2>/dev/null || true)
    if [ -n "$_hits" ]; then
      log_tier_violation 'NO_FRACTIONAL_TIERS' "$_scan" "Stale fractional tier label found: $(printf '%s' "$_hits" | head -n 1)"
    fi
  done
}

check_no_legacy_aliases
check_lib_atomic_purity
check_upward_imports
check_no_fractional_tiers

if [ "$ERRORS" -gt 0 ]; then
  printf '[FAIL] Architectural tier audit failed with %d violation(s).\n' "$ERRORS" >&2
  exit 1
fi
printf '[PASS] All T0-T5 tiers and orthogonal planes satisfy strict architectural boundaries.\n'
exit 0
