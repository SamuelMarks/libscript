#!/bin/sh
# ## Overview
# Audits LibScript's T0-T5 + Orthogonal Planes (Plane A: traits, Plane B: experiments) architecture,
# enforcing unidirectional downward-only imports, atomic _lib/ purity, zero fractional tiers, and zero legacy aliases.
# ## Usage
# ./devtools/audit/audit_tiers.sh [--all | --staged | --root <dir>]

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

SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/engine/common/parallel.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
unset SCRIPT_NAME || true

TARGET_ROOT="${LIBSCRIPT_ROOT_DIR}"
TIER_MODE='all'

# ## show_help
# Prints usage instructions for the architectural tier boundary auditor.
show_help() {
  printf 'Usage: %s [--all | --staged | --root <dir> | --help]\n' "$(basename "$THIS_FILE")"
  printf 'Audits T0-T5 + Orthogonal Planes (traits, experiments) architectural boundaries.\n'
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --help|-h|'/?'|'-?')
      show_help
      exit 0
      ;;
    --root)
      TARGET_ROOT="$2"
      shift 2
      ;;
    --all)
      TIER_MODE='all'
      shift
      ;;
    --staged)
      TIER_MODE='staged'
      shift
      ;;
    *)
      shift
      ;;
  esac
done

AT_WORK=$(libscript_make_tmpdir 'tiers')
trap 'rm -rf "$AT_WORK"' EXIT INT TERM
ERRORS=0

# ## log_tier_violation
# Emits a structured architectural tier violation diagnostic to stderr and increments ERRORS.
log_tier_violation() {
  _rule="$1"
  _loc="$2"
  _msg="$3"
  printf '[TIER VIOLATION] [%s] %s: %s\n' "$_rule" "$_loc" "$_msg" >&2
  ERRORS=$((ERRORS + 1))
}

# ## check_no_legacy_aliases
# Verifies deleted legacy directories and normalize_component_alias shims never reappear.
check_no_legacy_aliases() {
  for _leg_dir in \
    _lib/_common \
    _lib/orchestration \
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

# shellcheck disable=SC2329
# ## _audit_lib_category
# Audits a single _lib/<category> directory for atomic T1/T2 purity.
_audit_lib_category() {
  _top_entry="$1"
  _lc_errs=0
  [ -e "$_top_entry" ] || return 0
  _bn=$(basename "$_top_entry")
  if [ -f "$_top_entry" ]; then
    case "$_bn" in
      README.md|checksums.txt) ;;
      *)
        printf '[TIER VIOLATION] [LIB_ATOMIC_PURITY] _lib/%s: Loose file at _lib/ root is forbidden.\n' "$_bn" >&2
        _lc_errs=$((_lc_errs + 1))
        ;;
    esac
    [ "$_lc_errs" -eq 0 ] && return 0 || return 1
  fi
  case "$_bn" in
    _*)
      printf '[TIER VIOLATION] [LIB_ATOMIC_PURITY] _lib/%s: Underscore helper directory inside _lib/ belongs in T0 engine/.\n' "$_bn" >&2
      return 1
      ;;
  esac

  set +f
  for _sub in "$_top_entry"/*; do
    [ -e "$_sub" ] || continue
    _sbn=$(basename "$_sub")
    if [ -f "$_sub" ]; then
      if [ "$_sbn" != 'README.md' ]; then
        printf '[TIER VIOLATION] [LIB_ATOMIC_PURITY] _lib/%s/%s: Loose category script inside _lib/<category>/ is forbidden; move to T0 engine/ or T3 synthesis/.\n' "$_bn" "$_sbn" >&2
        _lc_errs=$((_lc_errs + 1))
      fi
      continue
    fi
    case "$_sbn" in
      *-suite)
        printf '[TIER VIOLATION] [LIB_ATOMIC_PURITY] _lib/%s/%s: Experiment suites belong in Plane B experiments/, never in _lib/.\n' "$_bn" "$_sbn" >&2
        _lc_errs=$((_lc_errs + 1))
        ;;
    esac
    if [ -d "${_sub}/suites" ]; then
      printf '[TIER VIOLATION] [LIB_ATOMIC_PURITY] _lib/%s/%s/suites: Experiment subsuites belong in Plane B experiments/, never in _lib/.\n' "$_bn" "$_sbn" >&2
      _lc_errs=$((_lc_errs + 1))
    fi
    if [ ! -f "${_sub}/manifest.json" ]; then
      printf '[TIER VIOLATION] [LIB_ATOMIC_PURITY] _lib/%s/%s: Missing manifest.json in atomic _lib/ component.\n' "$_bn" "$_sbn" >&2
      _lc_errs=$((_lc_errs + 1))
    else
      _t_val=$(awk '
        /"tier"[[:space:]]*:[[:space:]]*"(T1|T2)"/ {
          if ($0 ~ /"T1"/) t = "T1"; else t = "T2"
        }
        END { print t }
      ' "${_sub}/manifest.json" 2>/dev/null || true)
      if [ -z "$_t_val" ]; then
        printf '[TIER VIOLATION] [LIB_ATOMIC_PURITY] _lib/%s/%s/manifest.json: Component manifest.json must declare "tier": "T1" or "T2".\n' "$_bn" "$_sbn" >&2
        _lc_errs=$((_lc_errs + 1))
      elif [ "$_t_val" = 'T1' ] && [ "$_bn" != 'virtualization' ]; then
        for _setup_sh in "${_sub}"/setup*.sh; do
          [ -f "$_setup_sh" ] || continue
          if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(mount|umount|losetup|fdisk|sfdisk|parted|mkfs(\.[a-z0-9]+)?|cryptsetup)[[:space:]]' "$_setup_sh" 2>/dev/null; then
            printf '[TIER VIOLATION] [LIB_ATOMIC_PURITY] _lib/%s/%s/%s: T1 userland recipe invokes storage/partitioning primitives.\n' "$_bn" "$_sbn" "$(basename "$_setup_sh")" >&2
            _lc_errs=$((_lc_errs + 1))
          fi
        done
      fi
      for _comp_scr in "${_sub}"/*.sh "${_sub}"/*.cmd "${_sub}"/*.ps1; do
        [ -f "$_comp_scr" ] || continue
        if awk -v my_cat="$_bn" -v my_comp="$_sbn" '
          /^[[:space:]]*(#|::|rem[[:space:]]|REM[[:space:]])/ { next }
          /(\.\.[\/\\]_common[\/\\]|\.\.[\/\\]\.\.[\/\\]_common[\/\\]|\.\.[\/\\][a-zA-Z0-9_-]+[\/\\](setup|cli|env|service|uninstall|test)\.(sh|cmd|ps1))/ { bad = 1; exit }
          match($0, /_lib[\/\\][a-z0-9-]+[\/\\][a-z0-9-]+[\/\\]/) {
            seg = substr($0, RSTART + 5, RLENGTH - 6)
            gsub(/\\/, "/", seg)
            if (seg != (my_cat "/" my_comp)) { bad = 1; exit }
          }
          match($0, /\.\.[\/\\]\.\.[\/\\][a-z0-9-]+[\/\\][a-z0-9-]+[\/\\]/) {
            seg = substr($0, RSTART + 6, RLENGTH - 7)
            gsub(/\\/, "/", seg)
            if (seg !~ /^(engine|cli)\// && seg != (my_cat "/" my_comp)) { bad = 1; exit }
          }
          END { exit(bad ? 0 : 1) }
        ' "$_comp_scr"; then
          printf '[TIER VIOLATION] [LIB_ATOMIC_PURITY] _lib/%s/%s/%s: Lateral cross-component or stale _common reference is forbidden; route via libscript.{sh,cmd} or engine/common/.\n' "$_bn" "$_sbn" "$(basename "$_comp_scr")" >&2
          _lc_errs=$((_lc_errs + 1))
        fi
      done
    fi
  done
  set -f
  [ "$_lc_errs" -eq 0 ] && return 0 || return 1
}

# ## check_lib_atomic_purity
# Verifies _lib/ contains exclusively atomic T1/T2 component directories across parallel workers.
check_lib_atomic_purity() {
  [ -d "${TARGET_ROOT}/_lib" ] || return 0
  _cats_file="${AT_WORK}/LIB_CATS.TXT"
  : > "$_cats_file"
  set +f
  for _top_entry in "${TARGET_ROOT}/_lib"/*; do
    [ -e "$_top_entry" ] || continue
    printf '%s\n' "$_top_entry" >> "$_cats_file"
  done
  set -f
  if [ -s "$_cats_file" ]; then
    if ! libscript_parallel_map "$_cats_file" _audit_lib_category; then
      ERRORS=$((ERRORS + 1))
    fi
  fi
}

# shellcheck disable=SC2329
# ## _tier_scan_batch
# Evaluates a batch of files for TIER_UPWARD_IMPORT and NO_FRACTIONAL_TIERS in a single POSIX awk pass.
_tier_scan_batch() {
  awk -v root="${TARGET_ROOT}/" '
    FNR == 1 {
      rel = FILENAME
      if (index(rel, root) == 1) rel = substr(rel, length(root) + 1)
      sub(/^\.\//, "", rel)
      is_code = (rel ~ /\.(sh|cmd|ps1|json)$/)
      is_frac_target = (rel ~ /\.(json|sh|cmd|md)$/ && (rel ~ /^(engine|_lib|synthesis|infrastructure|workloads|traits|cli)\// || rel == "libscript.sh" || rel == "libscript.cmd" || rel == "ARCHITECTURE.md" || rel == "README.md"))
      tier_scope = ""
      if (is_code) {
        if (rel ~ /^engine\/(common|schemas|hooks|target|consensus)\//) {
          split(rel, p, "/"); tier_scope = "T0:" p[1] "/" p[2]
        } else if (rel ~ /^_lib\//) {
          tier_scope = "T12:_lib"
        } else if (rel ~ /^synthesis\//) {
          tier_scope = "T3:synthesis"
        } else if (rel ~ /^infrastructure\//) {
          tier_scope = "T4:infrastructure"
        } else if (rel ~ /^workloads\//) {
          tier_scope = "T5:workloads"
        } else if (rel ~ /^traits\//) {
          tier_scope = "PA:traits"
        }
      }
    }
    {
      if (tier_scope != "") {
        if (tier_scope ~ /^T0:/ && $0 ~ /(^|[^a-zA-Z0-9_-])(synthesis|infrastructure|workloads|traits|experiments)[\/\\]/) {
          loc = substr(tier_scope, 4)
          if (!(loc in seen_up)) {
            seen_up[loc] = 1
            print "[TIER VIOLATION] [TIER_UPWARD_IMPORT] " loc ": T0 engine layer references higher tier: " rel ":" FNR ":" $0
            errs++
          }
        } else if (tier_scope == "T12:_lib" && $0 ~ /(^|[^a-zA-Z0-9_-])(synthesis|infrastructure|workloads|traits|experiments)[\/\\]/) {
          if (!("_lib" in seen_up)) {
            seen_up["_lib"] = 1
            print "[TIER VIOLATION] [TIER_UPWARD_IMPORT] _lib: T1/T2 recipe layer references higher tier: " rel ":" FNR ":" $0
            errs++
          }
        } else if (tier_scope == "T3:synthesis" && $0 ~ /(^|[^a-zA-Z0-9_-])(infrastructure[\/\\]|workloads[\/\\](constellations|payloads|schedulers|ai|services)[\/\\]|experiments[\/\\])/) {
          if (!("synthesis" in seen_up)) {
            seen_up["synthesis"] = 1
            print "[TIER VIOLATION] [TIER_UPWARD_IMPORT] synthesis: T3 synthesis layer references higher tier: " rel ":" FNR ":" $0
            errs++
          }
        } else if (tier_scope == "T4:infrastructure" && $0 ~ /(^|[^a-zA-Z0-9_-])(workloads|experiments)[\/\\]/) {
          if (!("infrastructure" in seen_up)) {
            seen_up["infrastructure"] = 1
            print "[TIER VIOLATION] [TIER_UPWARD_IMPORT] infrastructure: T4 infrastructure layer references higher tier: " rel ":" FNR ":" $0
            errs++
          }
        } else if (tier_scope == "T5:workloads" && $0 ~ /(^|[^a-zA-Z0-9_-])experiments[\/\\]/) {
          if (!("workloads" in seen_up)) {
            seen_up["workloads"] = 1
            print "[TIER VIOLATION] [TIER_UPWARD_IMPORT] workloads: T5 workloads layer references Plane B experiments/: " rel ":" FNR ":" $0
            errs++
          }
        } else if (tier_scope == "PA:traits" && $0 ~ /(^|[^a-zA-Z0-9_-])(synthesis|infrastructure|workloads|experiments)[\/\\]/) {
          if (!("traits" in seen_up)) {
            seen_up["traits"] = 1
            print "[TIER VIOLATION] [TIER_UPWARD_IMPORT] traits: Plane A traits/ references T3/T4/T5/Plane B: " rel ":" FNR ":" $0
            errs++
          }
        }
      }
      if (is_code && rel !~ /^devtools\/audit\// && ($0 ~ /_common[\/\\](pkg_mgr|component_core|setup_base|env_base|service|log|os_info|priv)/ || $0 ~ /_lib[\/\\]databases[\/\\]provision_schema\.(sh|cmd|ps1)/ || $0 ~ /\$libDir[[:space:]]+"databases[\/\\]provision_schema/)) {
        print "[TIER VIOLATION] [NO_LEGACY_ALIASES] " rel ":" FNR ": Stale pre-T0-T5 _common or moved hook path reference: " $0
        errs++
      }
      if (is_frac_target && $0 ~ /Tier[[:space:]]+(1\.5|3\.5)/) {
        split(rel, fp, "/")
        scan_top = fp[1]
        if (!(scan_top in seen_frac)) {
          seen_frac[scan_top] = 1
          print "[TIER VIOLATION] [NO_FRACTIONAL_TIERS] " scan_top ": Stale fractional tier label found: " rel ":" FNR ":" $0
          errs++
        }
      }
    }
    END { exit(errs > 0 ? 1 : 0) }
  ' "$@" >&2
}

# shellcheck disable=SC2329
# ## _tier_shard_worker
# Processes a shard of repository files for upward-import and fractional-tier violations.
_tier_shard_worker() {
  libscript_batch_exec "$1" 250 _tier_scan_batch
}

# ## check_imports_and_fractional_tiers
# Collects candidate files with POSIX tools and audits upward imports and fractional tier labels in parallel.
check_imports_and_fractional_tiers() {
  _cand_files="${AT_WORK}/TIER_FILES.TXT"
  : > "$_cand_files"
  if [ -d "${TARGET_ROOT}/.git" ] && git -C "${TARGET_ROOT}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    _del="${AT_WORK}/DELETED.TXT"
    git -C "${TARGET_ROOT}" ls-files --deleted > "$_del" 2>/dev/null || : > "$_del"
    git -C "${TARGET_ROOT}" ls-files --cached --others --exclude-standard -- \
      'engine/*.sh' 'engine/*.cmd' 'engine/*.ps1' 'engine/*.json' 'engine/*.md' \
      '_lib/*.sh' '_lib/*.cmd' '_lib/*.ps1' '_lib/*.json' '_lib/*.md' \
      'synthesis/*.sh' 'synthesis/*.cmd' 'synthesis/*.ps1' 'synthesis/*.json' 'synthesis/*.md' \
      'infrastructure/*.sh' 'infrastructure/*.cmd' 'infrastructure/*.ps1' 'infrastructure/*.json' 'infrastructure/*.md' \
      'workloads/*.sh' 'workloads/*.cmd' 'workloads/*.ps1' 'workloads/*.json' 'workloads/*.md' \
      'traits/*.sh' 'traits/*.cmd' 'traits/*.ps1' 'traits/*.json' 'traits/*.md' \
      'cli/*.sh' 'cli/*.cmd' 'cli/*.ps1' 'cli/*.json' 'cli/*.md' \
      'libscript.sh' 'libscript.cmd' 'ARCHITECTURE.md' 'README.md' \
      | awk -v root="${TARGET_ROOT}/" -v del_f="$_del" '
        BEGIN { while ((getline d < del_f) > 0) del[d] = 1; close(del_f) }
        NF > 0 && !($0 in del) { print root $0 }
      ' > "$_cand_files"
  else
    for _sc in engine _lib synthesis infrastructure workloads traits cli libscript.sh libscript.cmd ARCHITECTURE.md README.md; do
      if [ -d "${TARGET_ROOT}/${_sc}" ]; then
        find "${TARGET_ROOT}/${_sc}" -type f \( -name '*.sh' -o -name '*.cmd' -o -name '*.ps1' -o -name '*.json' -o -name '*.md' \) >> "$_cand_files" 2>/dev/null || true
      elif [ -f "${TARGET_ROOT}/${_sc}" ]; then
        printf '%s\n' "${TARGET_ROOT}/${_sc}" >> "$_cand_files"
      fi
    done
  fi

  if [ -s "$_cand_files" ]; then
    if ! libscript_parallel_shards "$_cand_files" _tier_shard_worker; then
      ERRORS=$((ERRORS + 1))
    fi
  fi
}

check_no_legacy_aliases
if [ "$TIER_MODE" = 'staged' ] && [ -d "${TARGET_ROOT}/.git" ] && git -C "${TARGET_ROOT}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  _staged_tier_f="${AT_WORK}/STAGED_TIER.TXT"
  git -C "${TARGET_ROOT}" diff --no-ext-diff --no-renames --cached --name-only --diff-filter=ACM     | awk -v root="${TARGET_ROOT}/" 'NF > 0 { print root $0 }'     | while IFS= read -r _st_p || [ -n "$_st_p" ]; do
      [ -f "$_st_p" ] && printf '%s\n' "$_st_p"
    done > "$_staged_tier_f"
  if grep -q '/_lib/' "$_staged_tier_f" 2>/dev/null; then
    check_lib_atomic_purity
  fi
  if [ -s "$_staged_tier_f" ]; then
    if ! libscript_parallel_shards "$_staged_tier_f" _tier_shard_worker; then
      ERRORS=$((ERRORS + 1))
    fi
  fi
else
  check_lib_atomic_purity
  check_imports_and_fractional_tiers
fi

if [ "$ERRORS" -gt 0 ]; then
  printf '[FAIL] Architectural tier audit failed with %d violation(s).\n' "$ERRORS" >&2
  exit 1
fi
printf '[PASS] All T0-T5 tiers and orthogonal planes satisfy strict architectural boundaries.\n'
exit 0
