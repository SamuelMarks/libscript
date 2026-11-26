#!/bin/sh
# ## Overview
# Audits component variables, scoped variable packs (schemas/vars/*.schema.json), $ref integrity,
# _lib/*/*/manifest.json schemas, and profiles/**/*.json schemas across LibScript.
# ## Usage
# ./devtools/audit/audit_schema_vars.sh [--all | --staged | <component_dir>...]
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
ASV_WORK=$(libscript_make_tmpdir 'asv')

if ! command -v jq >/dev/null 2>&1; then
  printf '[ERROR] jq is required by audit_schema_vars.sh.\n' >&2
  exit 1
fi

BASE_SCHEMA="${LIBSCRIPT_ROOT_DIR}/engine/schemas/base_vars.schema.json"
MANIFEST_SCHEMA="${LIBSCRIPT_ROOT_DIR}/engine/schemas/manifest.schema.json"
OS_CONFIG_SCHEMA="${LIBSCRIPT_ROOT_DIR}/synthesis/schemas/os-config.schema.json"
FREEBSD_SCHEMA="${LIBSCRIPT_ROOT_DIR}/synthesis/schemas/execution-plan.freebsd.schema.json"
ILLUMOS_SCHEMA="${LIBSCRIPT_ROOT_DIR}/synthesis/schemas/execution-plan.illumos.schema.json"
REACTOS_SCHEMA="${LIBSCRIPT_ROOT_DIR}/synthesis/schemas/execution-plan.reactos.schema.json"
RTOS_SCHEMA="${LIBSCRIPT_ROOT_DIR}/synthesis/schemas/execution-plan.rtos.schema.json"
EXEC_COMMON_SCHEMA="${LIBSCRIPT_ROOT_DIR}/synthesis/schemas/execution-plan-common.schema.json"
ROOT_LIBSCRIPT_SCHEMA="${LIBSCRIPT_ROOT_DIR}/libscript.schema.json"
NESTED_LIBSCRIPT_SCHEMA="${LIBSCRIPT_ROOT_DIR}/workloads/schemas/libscript.schema.json"
TFRC_POLICY_SCHEMA="${LIBSCRIPT_ROOT_DIR}/engine/schemas/tfrc-policy.schema.json"
VARS_PACK_DIR="${LIBSCRIPT_ROOT_DIR}/schemas/vars"
ERRORS=0
AUDITED=0

# ## extract_schema_keys
# Prints all property keys and deprecated_aliases from a JSON schema file.
extract_schema_keys() {
  _schema="$1"
  [ -f "$_schema" ] || return 0
  jq -r '((.properties // {} | keys[]), (.properties // {} | to_entries[] | .value.deprecated_aliases[]?))' "$_schema" 2>/dev/null | sort -u || true
}

# ## check_schema_descriptions
# Validates that a schema file is valid JSON, every property has a non-empty description, and no description uses a lazy "Variable <NAME>." placeholder.
check_schema_descriptions() {
  _schema="$1"
  _rel="${_schema#"${LIBSCRIPT_ROOT_DIR}"/}"
  if ! jq empty "$_schema" >/dev/null 2>&1; then
    printf '[STANDARDS VIOLATION] [INVALID_JSON] %s: Schema is not valid JSON.\n' "$_rel" >&2
    ERRORS=$((ERRORS + 1))
    return 1
  fi
  _missing=$(jq -r '
    def check_props($prefix):
      to_entries[]
      | (($prefix + .key) as $p |
         (if ((.value.description // "") | gsub("^\\s+|\\s+$"; "") | length) == 0 then $p else empty end),
         (if (.value | type) == "object" and (.value.properties | type) == "object" then (.value.properties | check_props($p + ".")) else empty end),
         (if (.value | type) == "object" and (.value.items | type) == "object" and (.value.items.properties | type) == "object" then (.value.items.properties | check_props($p + "[].")) else empty end)
        );
    ((.properties // {}) | check_props("")),
    ((."$defs" // {}) | check_props("$defs."))
  ' "$_schema" 2>/dev/null || true)
  if [ -n "$_missing" ]; then
    for _k in $_missing; do
      printf '[STANDARDS VIOLATION] [MISSING_SCHEMA_DESC] %s: Property "%s" is missing a non-empty description.\n' "$_rel" "$_k" >&2
      ERRORS=$((ERRORS + 1))
    done
  fi
  _placeholders=$(jq -r '
    .properties // {} | to_entries[]
    | select((.value.description // "") | test("^Variable [A-Za-z0-9_]+\\.?$"))
    | .key
  ' "$_schema" 2>/dev/null || true)
  if [ -n "$_placeholders" ]; then
    for _pk in $_placeholders; do
      printf '[STANDARDS VIOLATION] [SCHEMA_PLACEHOLDER_DESC] %s: Property "%s" uses placeholder description "Variable ...".\n' "$_rel" "$_pk" >&2
      ERRORS=$((ERRORS + 1))
    done
  fi
  return 0
}

# ## is_internal_runtime_var
# Returns 0 if a variable is an internal runtime, memoization, or test-harness variable that must not appear in user-facing vars.schema.json.
is_internal_runtime_var() {
  _var_name="$1"
  case "$_var_name" in
    LIBSCRIPT_ROOT_DIR|LIBSCRIPT_SERVERS_*|LIBSCRIPT_SERVICE_UNIT_UNCHANGED|LIBSCRIPT_INSTALL_MAP_*|LIBSCRIPT_ENV_sourced_*|LIBSCRIPT_IS_INSTALLED)
      return 0
      ;;
    LIBSCRIPT_OVERRIDE_CHANGED|LIBSCRIPT_RESOLVED_CC_*|LIBSCRIPT_RESOLVED_CXX_BIN|LIBSCRIPT_LAST_PEAK_RSS_KB|LIBSCRIPT_LAST_COMPILE_TIME_MS|LIBSCRIPT_EXTRACTED_SRC_DIR|LIBSCRIPT_BUILD_TARGET_DIR|LIBSCRIPT_BASE_DIR)
      return 0
      ;;
    LIBSCRIPT_HW_CPU_MODEL|LIBSCRIPT_HW_PHYS_CORES|LIBSCRIPT_HW_PERF_CORES|LIBSCRIPT_HW_NUMA_NODES|LIBSCRIPT_RESOLVED_JOBS|LIBSCRIPT_BG_SUPPORTED|LIBSCRIPT_PARALLEL_SUPPORTED|LIBSCRIPT_PARALLEL_PROBED|LIBSCRIPT_MAP_FN)
      return 0
      ;;
    LIBSCRIPT_BENCH_CLOCK_NS_BIN|LIBSCRIPT_BENCH_PROBE_BIN|LIBSCRIPT_BENCH_FAKE_TRANSLATED_ISA)
      return 0
      ;;
    LIBSCRIPT_INTERNAL_START|LIBSCRIPT_COMPONENT_CORE_LIB_ONLY|LIBSCRIPT_MOCK_SYSTEMD|LIBSCRIPT_DUMMY_NO_RUN|LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB|LIBSCRIPT_DISABLE_CHECKSUM_TXT_UPDATE|LIBSCRIPT_TARGET_OS|LIBSCRIPT_TARGET_ARCH|LIBSCRIPT_FORCE_SYSTEM_PKG_MGR)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# ## audit_schema_refs
# Verifies that all file-based $ref links across *.schema.json files resolve to existing files on disk.
audit_schema_refs() {
  _tmp_refs="${ASV_WORK}/REFS.TSV"
  # shellcheck disable=SC2016
  find "${LIBSCRIPT_ROOT_DIR}" \( -name node_modules -o -name .git -o -name cache -o -name tests_tmp \) -prune -o -type f -name '*.schema.json' \
    -exec jq -rn 'inputs | (input_filename) as $f | (.. | objects | select(has("$ref")) | ."$ref" | "\($f)\t\(.)")' {} + > "$_tmp_refs" 2>/dev/null || true
  while IFS='	' read -r _sf _r; do
    [ -n "$_sf" ] && [ -n "$_r" ] || continue
    case "$_r" in
      '#'*|http://*|https://*) continue ;;
    esac
    _target_rel="${_r%%#*}"
    [ -n "$_target_rel" ] || continue
    _sf_dir="${_sf%/*}"
    if [ ! -f "${_sf_dir}/${_target_rel}" ]; then
      _sf_rel="${_sf#"${LIBSCRIPT_ROOT_DIR}"/}"
      printf '[STANDARDS VIOLATION] [SCHEMA_BROKEN_REF] %s: %s "%s" does not resolve to an existing file.\n' "$_sf_rel" "\$ref" "$_r" >&2
      ERRORS=$((ERRORS + 1))
    fi
  done < "$_tmp_refs"
  rm -f "$_tmp_refs"
}

PACK_CACHE_FILE="${ASV_WORK}/PACKS.TSV"
: > "$PACK_CACHE_FILE"
trap 'rm -rf "$ASV_WORK" 2>/dev/null || true' EXIT INT TERM HUP
if [ -d "$VARS_PACK_DIR" ]; then
  set +f
  for _pack_file in "${VARS_PACK_DIR}"/*.schema.json; do
    [ -f "$_pack_file" ] || continue
    _pack_name="${_pack_file##*/}"
    _pack_name="${_pack_name%.schema.json}"
    _pack_keys=$(extract_schema_keys "$_pack_file" | tr '\n' ' ')
    printf '%s\t%s\n' "$_pack_name" "$_pack_keys" >> "$PACK_CACHE_FILE"
  done
  set -f
fi

# ## lookup_cached_pack_keys
# Prints space-separated keys for a pre-cached variable pack name, or returns 1 if unknown.
lookup_cached_pack_keys() {
  _want_pack="$1"
  awk -F '\t' -v p="$_want_pack" '$1 == p { print $2; found=1; exit } END { exit(found ? 0 : 1) }' "$PACK_CACHE_FILE"
}

# ## resolve_component_pack_keys
# Resolves property keys and deprecated_aliases from any x-libscript-var-packs declared in a component schema.
resolve_component_pack_keys() {
  _comp_schema="$1"
  _packs_csv="${2:-}"
  _comp_rel="${_comp_schema#"${LIBSCRIPT_ROOT_DIR}"/}"
  if [ -z "$_packs_csv" ]; then
    _packs=$(jq -r '."x-libscript-var-packs"[]? // empty' "$_comp_schema" 2>/dev/null || true)
  else
    _packs=$(printf '%s' "$_packs_csv" | tr ',' ' ')
  fi
  [ -n "$_packs" ] || return 0
  for _p in $_packs; do
    if _cached=$(lookup_cached_pack_keys "$_p"); then
      printf '%s\n' "$_cached"
    else
      printf '[STANDARDS VIOLATION] [UNKNOWN_VAR_PACK] %s: Declared x-libscript-var-packs entry "%s" has no %s.\n' "$_comp_rel" "$_p" "schemas/vars/${_p}.schema.json" >&2
      ERRORS=$((ERRORS + 1))
    fi
  done
}

# ## audit_manifest_json
# Validates a component's manifest.json against engine/schemas/manifest.schema.json.
audit_manifest_json() {
  _comp_dir="$1"
  _rel_dir="${_comp_dir#"${LIBSCRIPT_ROOT_DIR}"/}"
  _manifest="${_comp_dir}/manifest.json"
  if [ ! -f "$_manifest" ]; then
    printf '[STANDARDS VIOLATION] [MISSING_MANIFEST] %s: Missing manifest.json.\n' "$_rel_dir" >&2
    ERRORS=$((ERRORS + 1))
    return 0
  fi
  if [ -f "$MANIFEST_SCHEMA" ]; then
    if ! _m_err=$(jq -r --slurpfile ms "$MANIFEST_SCHEMA" '
      . as $doc
      | ($ms[0].required // []) as $req
      | ($ms[0].properties.category.enum // []) as $cats
      | ($ms[0].properties.capabilities.items.enum // []) as $caps
      | ($ms[0].properties | keys) as $allowed
      | [
          ($req[] as $r | select(($doc | has($r)) | not) | "missing required field: \($r)"),
          (if (.name // "") | test("^[a-z0-9_-]+$") | not then "name \"\(.name // "")\" does not match ^[a-z0-9_-]+$" else empty end),
          (if ((.title // "") | length) == 0 then "title must be non-empty" else empty end),
          (if ((.description // "") | length) == 0 then "description must be non-empty" else empty end),
          (if ($cats | length) > 0 and ((.category // "") as $c | ($cats | index($c)) == null) then "category \"\(.category // "")\" not in manifest.schema.json enum" else empty end),
          (if ((.capabilities // null) | type) != "array" or ((.capabilities // []) | length) == 0 then "capabilities must be a non-empty array" else empty end),
          (if ((.capabilities // null) | type) == "array" then (.capabilities[] | select(. as $cap | ($caps | index($cap)) == null) | "capability \"\(.)\" not in manifest.schema.json enum") else empty end),
          (keys[] | select(. as $k | ($allowed | index($k)) == null) | "undeclared top-level property: \(.)")
        ]
      | .[]
    ' "$_manifest" 2>/dev/null); then
      printf '[STANDARDS VIOLATION] [INVALID_JSON] %s/manifest.json: File is not valid JSON.\n' "$_rel_dir" >&2
      ERRORS=$((ERRORS + 1))
      return 0
    fi
    if [ -n "$_m_err" ]; then
      printf '%s\n' "$_m_err" | while IFS= read -r _line; do
        [ -n "$_line" ] || continue
        printf '[STANDARDS VIOLATION] [MANIFEST_SCHEMA] %s/manifest.json: %s\n' "$_rel_dir" "$_line" >&2
      done
      ERRORS=$((ERRORS + 1))
    fi
  elif ! jq empty "$_manifest" >/dev/null 2>&1; then
    printf '[STANDARDS VIOLATION] [INVALID_JSON] %s/manifest.json: File is not valid JSON.\n' "$_rel_dir" >&2
    ERRORS=$((ERRORS + 1))
  fi
}

# ## audit_root_schemas_and_profiles
# Validates root OS/RTOS/TFRC/LibScript schemas, scoped variable packs, and profiles/**/*.json files.
audit_root_schemas_and_profiles() {
  for _rs in "$BASE_SCHEMA" "$RTOS_SCHEMA" "$EXEC_COMMON_SCHEMA" "$ROOT_LIBSCRIPT_SCHEMA" "$TFRC_POLICY_SCHEMA" "${LIBSCRIPT_ROOT_DIR}/component-scaffold.schema.json"; do
    if [ -f "$_rs" ]; then
      check_schema_descriptions "$_rs" || true
    fi
  done

  set +f
  for _vp in \
    "${VARS_PACK_DIR}"/*.schema.json \
    "${LIBSCRIPT_ROOT_DIR}/engine/schemas"/*.schema.json \
    "${LIBSCRIPT_ROOT_DIR}/synthesis/schemas"/*.schema.json \
    "${LIBSCRIPT_ROOT_DIR}/workloads/schemas"/*.schema.json \
    "${LIBSCRIPT_ROOT_DIR}/experiments/schemas"/*.schema.json; do
    [ -f "$_vp" ] || continue
    check_schema_descriptions "$_vp" || true
  done
  set -f

  if [ -f "$BASE_SCHEMA" ]; then
    _base_raw_keys=$(jq -r '.properties // {} | keys[]' "$BASE_SCHEMA" 2>/dev/null || true)
    _base_count=0
    for _bk in $_base_raw_keys; do
      _base_count=$((_base_count + 1))
      if is_internal_runtime_var "$_bk"; then
        printf '[STANDARDS VIOLATION] [INTERNAL_VAR_IN_BASE_SCHEMA] engine/schemas/base_vars.schema.json: Internal variable "%s" must not appear in user-facing base_vars.schema.json.\n' "$_bk" >&2
        ERRORS=$((ERRORS + 1))
      fi
    done
    if [ "$_base_count" -gt 32 ]; then
      printf '[STANDARDS VIOLATION] [BASE_SCHEMA_BLOAT] engine/schemas/base_vars.schema.json: Contains %d properties (maximum allowed core globals is 32; move domain variables to schemas/vars/*.schema.json).\n' "$_base_count" >&2
      ERRORS=$((ERRORS + 1))
    fi
  fi

  if [ -f "$NESTED_LIBSCRIPT_SCHEMA" ]; then
    if ! jq empty "$NESTED_LIBSCRIPT_SCHEMA" >/dev/null 2>&1; then
      printf '[STANDARDS VIOLATION] [INVALID_JSON] workloads/schemas/libscript.schema.json: File is not valid JSON.\n' >&2
      ERRORS=$((ERRORS + 1))
    else
      _wrap_ref=$(jq -r '."$ref" // empty' "$NESTED_LIBSCRIPT_SCHEMA" 2>/dev/null || true)
      if [ "$_wrap_ref" != '../../libscript.schema.json' ]; then
        printf '[STANDARDS VIOLATION] [SCHEMA_SYNC] workloads/schemas/libscript.schema.json must %s "../../libscript.schema.json" as a thin canonical wrapper.\n' "\$ref" >&2
        ERRORS=$((ERRORS + 1))
      fi
    fi
  fi

  audit_schema_refs

  if [ ! -d "${LIBSCRIPT_ROOT_DIR}/synthesis/profiles" ]; then
    return 0
  fi
  set +f
  for _pf in "${LIBSCRIPT_ROOT_DIR}/synthesis/profiles"/*/*.json "${LIBSCRIPT_ROOT_DIR}/synthesis/profiles"/*/*/*.json; do
    [ -f "$_pf" ] || continue
    _rel_pf="${_pf#"${LIBSCRIPT_ROOT_DIR}"/}"
    if ! jq empty "$_pf" >/dev/null 2>&1; then
      printf '[STANDARDS VIOLATION] [INVALID_JSON] %s: OS profile is not valid JSON.\n' "$_rel_pf" >&2
      ERRORS=$((ERRORS + 1))
      continue
    fi
    _os_fam=$(jq -r '.target.os_family // "linux"' "$_pf" 2>/dev/null || printf 'linux')
    _pf_err=''
    case "$_os_fam" in
      freebsd)
        if [ -f "$FREEBSD_SCHEMA" ]; then
          _pf_err=$(jq -r --slurpfile fs "$FREEBSD_SCHEMA" '
            . as $doc
            | ($fs[0].required // []) as $req
            | [ ($req[] as $r | select(($doc | has($r)) | not) | "missing required FreeBSD field: \($r)") ] | .[]
          ' "$_pf" 2>/dev/null || true)
        fi
        ;;
      illumos)
        if [ -f "$ILLUMOS_SCHEMA" ]; then
          _pf_err=$(jq -r --slurpfile is "$ILLUMOS_SCHEMA" '
            . as $doc
            | ($is[0].required // []) as $req
            | [ ($req[] as $r | select(($doc | has($r)) | not) | "missing required illumos field: \($r)") ] | .[]
          ' "$_pf" 2>/dev/null || true)
        fi
        ;;
      reactos)
        if [ -f "$REACTOS_SCHEMA" ]; then
          _pf_err=$(jq -r --slurpfile rs "$REACTOS_SCHEMA" '
            . as $doc
            | ($rs[0].required // []) as $req
            | [ ($req[] as $r | select(($doc | has($r)) | not) | "missing required ReactOS field: \($r)") ] | .[]
          ' "$_pf" 2>/dev/null || true)
        fi
        ;;
      rtos)
        if [ -f "$OS_CONFIG_SCHEMA" ]; then
          _pf_err=$(jq -r --slurpfile os "$OS_CONFIG_SCHEMA" '
            ($os[0].properties.target.properties.arch.enum // []) as $archs
            | ($os[0].properties.target.properties.libc.enum // []) as $libcs
            | ($os[0].properties.rtos.properties.kernel.enum // []) as $kernels
            | [
                (if has("schema_version") | not then "missing required field: schema_version" else empty end),
                (if has("profile_name") | not then "missing required field: profile_name" else empty end),
                (if has("target") | not then "missing required field: target" else empty end),
                (if has("rtos") | not then "missing required field: rtos" else empty end),
                (if ((.target.arch // "") as $a | ($archs | index($a)) == null) then "target.arch \"\(.target.arch // "")\" not in synthesis/schemas/os-config.schema.json enum" else empty end),
                (if ((.target.libc // "") as $l | ($libcs | index($l)) == null) then "target.libc \"\(.target.libc // "")\" not in synthesis/schemas/os-config.schema.json enum" else empty end),
                (if ((.rtos.kernel // "") as $k | ($kernels | index($k)) == null) then "rtos.kernel \"\(.rtos.kernel // "")\" not in synthesis/schemas/os-config.schema.json enum" else empty end)
              ] | .[]
          ' "$_pf" 2>/dev/null || true)
        fi
        ;;
      *)
        if [ -f "$OS_CONFIG_SCHEMA" ]; then
          _pf_err=$(jq -r --slurpfile os "$OS_CONFIG_SCHEMA" '
            . as $doc
            | ($os[0].required // []) as $req
            | ($os[0].properties.target.properties.arch.enum // []) as $archs
            | ($os[0].properties.target.properties.libc.enum // []) as $libcs
            | [
                ($req[] as $r | select(($doc | has($r)) | not) | "missing required field: \($r)"),
                (if ((.target.arch // "") as $a | ($archs | index($a)) == null) then "target.arch \"\(.target.arch // "")\" not in synthesis/schemas/os-config.schema.json enum" else empty end),
                (if ((.target.libc // "") as $l | ($libcs | index($l)) == null) then "target.libc \"\(.target.libc // "")\" not in synthesis/schemas/os-config.schema.json enum" else empty end)
              ] | .[]
          ' "$_pf" 2>/dev/null || true)
        fi
        ;;
    esac
    if [ -n "$_pf_err" ]; then
      printf '%s\n' "$_pf_err" | while IFS= read -r _line; do
        [ -n "$_line" ] || continue
        printf '[STANDARDS VIOLATION] [PROFILE_SCHEMA] %s: %s\n' "$_rel_pf" "$_line" >&2
      done
      ERRORS=$((ERRORS + 1))
    fi
  done

  # Validate higher-tier schemas (descriptions) and declarative instances (STD-03)
  for _hts in \
    "${LIBSCRIPT_ROOT_DIR}/engine/schemas"/*.schema.json \
    "${LIBSCRIPT_ROOT_DIR}/synthesis/schemas"/*.schema.json \
    "${LIBSCRIPT_ROOT_DIR}/infrastructure/clusters/cluster-substrate.schema.json" \
    "${LIBSCRIPT_ROOT_DIR}/infrastructure/marketplace/marketplace-offer.schema.json" \
    "${LIBSCRIPT_ROOT_DIR}/workloads/constellations/constellation.schema.json" \
    "${LIBSCRIPT_ROOT_DIR}/workloads/schemas"/*.schema.json \
    "${LIBSCRIPT_ROOT_DIR}/traits/trait.schema.json" \
    "${LIBSCRIPT_ROOT_DIR}/experiments/schemas"/*.schema.json; do
    if [ -f "$_hts" ] && [ "$_hts" != "$NESTED_LIBSCRIPT_SCHEMA" ]; then
      check_schema_descriptions "$_hts" || true
    fi
  done

  for _pair in \
    "CLUSTER_SCHEMA|${LIBSCRIPT_ROOT_DIR}/infrastructure/clusters/cluster-substrate.schema.json|infrastructure/clusters/*/topology.json" \
    "CONSTELLATION_SCHEMA|${LIBSCRIPT_ROOT_DIR}/workloads/constellations/constellation.schema.json|workloads/constellations/*/topology.json" \
    "PAYLOAD_SCHEMA|${LIBSCRIPT_ROOT_DIR}/workloads/schemas/payload.schema.json|workloads/payloads/*/*/payload.json" \
    "TRAIT_SCHEMA|${LIBSCRIPT_ROOT_DIR}/traits/trait.schema.json|traits/*/trait.json" \
    "EXPERIMENT_SCHEMA|${LIBSCRIPT_ROOT_DIR}/experiments/schemas/experiment-suite.schema.json|experiments/*/suite.json" \
    "MARKETPLACE_SCHEMA|${LIBSCRIPT_ROOT_DIR}/infrastructure/marketplace/marketplace-offer.schema.json|infrastructure/marketplace/*/offer.json"; do
    _tag="${_pair%%|*}"
    _rest="${_pair#*|}"
    _sch="${_rest%%|*}"
    _glob="${_rest#*|}"
    [ -f "$_sch" ] || continue
    for _inst in "${LIBSCRIPT_ROOT_DIR}"/$_glob; do
      [ -f "$_inst" ] || continue
      _rel_inst="${_inst#"${LIBSCRIPT_ROOT_DIR}"/}"
      if ! jq empty "$_inst" >/dev/null 2>&1; then
        printf '[STANDARDS VIOLATION] [INVALID_JSON] %s: Instance is not valid JSON.\n' "$_rel_inst" >&2
        ERRORS=$((ERRORS + 1))
        continue
      fi
      _i_err=$(jq -r --slurpfile s "$_sch" '
        . as $doc
        | ($s[0].required // []) as $req
        | (($s[0].properties // {} | keys) + ["$schema"]) as $allowed
        | [
            ($req[] as $r | select(($doc | has($r)) | not) | "missing required field: \($r)"),
            (keys[] | select(. as $k | ($allowed | index($k)) == null) | "undeclared top-level property: \(.)")
          ]
        | .[]
      ' "$_inst" 2>/dev/null || true)
      if [ -n "$_i_err" ]; then
        printf '%s\n' "$_i_err" | while IFS= read -r _il; do
          [ -n "$_il" ] || continue
          printf '[STANDARDS VIOLATION] [%s] %s: %s\n' "$_tag" "$_rel_inst" "$_il" >&2
        done
        ERRORS=$((ERRORS + 1))
      fi
    done
  done
  set -f
}

GLOBAL_KEYS=$(extract_schema_keys "$BASE_SCHEMA" | tr '\n' ' ')
BASE_RAW_KEYS=$(jq -r '.properties // {} | keys[]' "$BASE_SCHEMA" 2>/dev/null | tr '\n' ' ' || true)

# ## audit_component_vars
# Audits a single component directory for manifest compliance, duplicate base vars, and undocumented script variables.
audit_component_vars() {
  _comp_dir="$1"
  [ -d "$_comp_dir" ] || return 0
  case "$_comp_dir" in
    */_common|*/_common/*) return 0 ;;
  esac
  [ -f "$_comp_dir/manifest.json" ] || [ -f "$_comp_dir/cli.sh" ] || [ -f "$_comp_dir/setup.sh" ] || return 0

  AUDITED=$((AUDITED + 1))
  _comp_trimmed="${_comp_dir%/}"
  _comp_name="${_comp_trimmed##*/}"
  _prefix=$(printf '%s' "$_comp_name" | tr '[:lower:]-' '[:upper:]_')
  _local_schema="${_comp_dir}/vars.schema.json"
  _rel_dir="${_comp_dir#"${LIBSCRIPT_ROOT_DIR}"/}"

  audit_manifest_json "$_comp_dir"

  if [ ! -f "$_local_schema" ]; then
    printf '[STANDARDS VIOLATION] [MISSING_SCHEMA] %s: Missing vars.schema.json.\n' "$_rel_dir" >&2
    ERRORS=$((ERRORS + 1))
    return 0
  fi

  _rel_schema="${_local_schema#"${LIBSCRIPT_ROOT_DIR}"/}"
  if ! _schema_info=$(jq -r '
    def check_props($prefix):
      to_entries[]
      | (($prefix + .key) as $p |
         (if ((.value.description // "") | gsub("^\\s+|\\s+$"; "") | length) == 0 then $p else empty end),
         (if (.value | type) == "object" and (.value.properties | type) == "object" then (.value.properties | check_props($p + ".")) else empty end),
         (if (.value | type) == "object" and (.value.items | type) == "object" and (.value.items.properties | type) == "object" then (.value.items.properties | check_props($p + "[].")) else empty end)
        );
    [
      ([((.properties // {}) | check_props("")), ((."$defs" // {}) | check_props("$defs."))] | join(" ")),
      ([.properties // {} | to_entries[] | select((.value.description // "") | test("^Variable [A-Za-z0-9_]+\\.?$")) | .key] | join(" ")),
      ([.properties // {} | keys[]] | join(" ")),
      ([((.properties // {} | keys[]), (.properties // {} | to_entries[] | .value.deprecated_aliases[]?))] | unique | join(" ")),
      ([."x-libscript-var-packs"[]? // empty] | join(","))
    ] | join("|")
  ' "$_local_schema" 2>/dev/null); then
    printf '[STANDARDS VIOLATION] [INVALID_JSON] %s: Schema is not valid JSON.\n' "$_rel_schema" >&2
    ERRORS=$((ERRORS + 1))
    return 0
  fi

  IFS='|' read -r _missing _placeholders _local_raw_keys _local_keys _packs_csv <<EOF_SCH
$_schema_info
EOF_SCH

  if [ -n "$_missing" ]; then
    for _k in $_missing; do
      printf '[STANDARDS VIOLATION] [MISSING_SCHEMA_DESC] %s: Property "%s" is missing a non-empty description.\n' "$_rel_schema" "$_k" >&2
      ERRORS=$((ERRORS + 1))
    done
  fi
  if [ -n "$_placeholders" ]; then
    for _pk in $_placeholders; do
      printf '[STANDARDS VIOLATION] [SCHEMA_PLACEHOLDER_DESC] %s: Property "%s" uses placeholder description "Variable ...".\n' "$_rel_schema" "$_pk" >&2
      ERRORS=$((ERRORS + 1))
    done
  fi

  for _lk in $_local_raw_keys; do
    case "$_lk" in
      LIBSCRIPT_LISTEN_ADDRESS|LIBSCRIPT_LISTEN_PORT|LIBSCRIPT_LISTEN_SOCKET) continue ;;
    esac
    case " ${BASE_RAW_KEYS} " in
      *" ${_lk} "*)
        printf '[STANDARDS VIOLATION] [DUPLICATE_BASE_VAR] %s/vars.schema.json: Property "%s" redundantly duplicates engine/schemas/base_vars.schema.json.\n' "$_rel_dir" "$_lk" >&2
        ERRORS=$((ERRORS + 1))
        ;;
    esac
  done

  _pack_keys=""
  if [ -n "$_packs_csv" ]; then
    _pack_keys=$(resolve_component_pack_keys "$_local_schema" "$_packs_csv" | tr '\n' ' ')
  fi
  _allowed=" ${GLOBAL_KEYS} ${_pack_keys} ${_local_keys} "

  _had_noglob=0
  case "$-" in *f*) _had_noglob=1 ;; esac
  set +f
  _scripts=''
  for _s in "$_comp_dir"/*.sh "$_comp_dir"/*.cmd "$_comp_dir"/*.bat "$_comp_dir"/*.ps1; do
    [ -f "$_s" ] || continue
    case "${_s##*/}" in
      test.sh|test.cmd|test.ps1|test_*.sh|test_*.cmd) continue ;;
    esac
    _scripts="${_scripts} ${_s}"
  done
  [ "$_had_noglob" = '1' ] && set -f

  [ -n "$_scripts" ] || return 0

  # shellcheck disable=SC2086
  _used_vars=$(awk -v prefix="$_prefix" '
    {
      sub(/\r$/, "", $0)
      if ($0 ~ /^[[:space:]]*(#|::|rem[[:space:]])/) next
      line = $0
      while (match(line, /(\$\{[A-Z][A-Z0-9_]*_[A-Z0-9_]+[:-]|\$env:[A-Z][A-Z0-9_]*_[A-Z0-9_]+|if[[:space:]]+not[[:space:]]+defined[[:space:]]+[A-Z][A-Z0-9_]*_[A-Z0-9_]+|if[[:space:]]+"%[A-Z][A-Z0-9_]*_[A-Z0-9_]+%"==""|printenv[[:space:]]+"?[A-Z][A-Z0-9_]*_[A-Z0-9_]+)/)) {
        tok = substr(line, RSTART, RLENGTH)
        line = substr(line, RSTART + RLENGTH)
        gsub(/^(\$\{|\$env:|if[[:space:]]+not[[:space:]]+defined[[:space:]]+|if[[:space:]]+"%|printenv[[:space:]]+"?)/, "", tok)
        gsub(/([:-]|%"==""|")$/, "", tok)
        if (index(tok, prefix "_") == 1 || index(tok, "LIBSCRIPT_") == 1) {
          print tok
        }
      }
    }
  ' $_scripts 2>/dev/null | sort -u || true)

  for _v in $_used_vars; do
    if is_internal_runtime_var "$_v"; then
      continue
    fi
    case "$_allowed" in
      *" ${_v} "*) ;;
      *)
        printf '[STANDARDS VIOLATION] [MISSING_JSON_VAR] %s/vars.schema.json: Variable "%s" is used in component scripts but missing from vars.schema.json (or x-libscript-var-packs / base_vars.schema.json).\n' "$_rel_dir" "$_v" >&2
        ERRORS=$((ERRORS + 1))
        ;;
    esac
  done
}

# shellcheck disable=SC2329
# ## _asv_shard_worker
# Audits a shard of component directories for schema and manifest conformance.
_asv_shard_worker() {
  _asw_sh="$1"
  ERRORS=0
  AUDITED=0
  while IFS= read -r _asw_c || [ -n "$_asw_c" ]; do
    [ -n "$_asw_c" ] && audit_component_vars "$_asw_c"
  done < "$_asw_sh"
  printf '%d %d\n' "$AUDITED" "$ERRORS" > "${_asw_sh}.cnt"
  [ "$ERRORS" -eq 0 ] && return 0 || return 1
}

MODE="${1:---all}"
if [ "$MODE" = '--all' ]; then
  audit_root_schemas_and_profiles
  _comps_f="${ASV_WORK}/COMPS.TXT"
  : > "$_comps_f"
  set +f
  for _cat in "${LIBSCRIPT_ROOT_DIR}/_lib"/*; do
    [ -d "$_cat" ] || continue
    [ "$(basename "$_cat")" = '_common' ] && continue
    for _comp in "$_cat"/*; do
      [ -d "$_comp" ] || continue
      printf '%s\n' "$_comp" >> "$_comps_f"
    done
  done
  set -f
  _jobs=$(libscript_parallel_jobs)
  if [ "$_jobs" -gt 1 ] && [ -s "$_comps_f" ]; then
    _sdir="${ASV_WORK}/shards"
    mkdir -p "$_sdir"
    awk -v n="$_jobs" -v d="$_sdir" 'NF > 0 { idx = (c % n) + 1; c++; out = d "/S" idx ".TXT"; print $0 >> out; close(out) }' "$_comps_f"
    _pids=''
    _i=1
    while [ "$_i" -le "$_jobs" ]; do
      if [ -s "${_sdir}/S${_i}.TXT" ]; then
        ( _asv_shard_worker "${_sdir}/S${_i}.TXT" ) &
        _pids="${_pids} $!"
      fi
      _i=$((_i + 1))
    done
    for _p in $_pids; do
      wait "$_p" || true
    done
    set +f
    for _cf in "${_sdir}"/*.cnt; do
      [ -f "$_cf" ] || continue
      read -r _ca _ce < "$_cf"
      AUDITED=$((AUDITED + _ca))
      ERRORS=$((ERRORS + _ce))
    done
    set -f
  else
    while IFS= read -r _comp || [ -n "$_comp" ]; do
      [ -n "$_comp" ] && audit_component_vars "$_comp"
    done < "$_comps_f"
  fi
elif [ "$MODE" = '--staged' ]; then
  audit_root_schemas_and_profiles
  _staged_dirs=$(git -C "$LIBSCRIPT_ROOT_DIR" diff --cached --name-only --diff-filter=ACMR | awk -F/ '$1 == "_lib" && $2 != "_common" && NF >= 3 { print $1 "/" $2 "/" $3 }' | sort -u || true)
  for _d in $_staged_dirs; do
    audit_component_vars "${LIBSCRIPT_ROOT_DIR}/${_d}"
  done
else
  for _arg in "$@"; do
    if [ -d "$_arg" ]; then
      audit_component_vars "$_arg"
    fi
  done
fi

if [ "$ERRORS" -gt 0 ]; then
  printf '[FAIL] Schema & Manifest Audit failed with %d violation(s) across %d component(s).\n' "$ERRORS" "$AUDITED" >&2
  exit 1
fi

printf '[PASS] All %d audited component(s), scoped variable packs, manifests, and OS profiles conform to JSON schemas.\n' "$AUDITED"
exit 0
