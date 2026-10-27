#!/bin/sh
# ## Overview
# Audits all LibScript components in `_lib/<category>/<component>/` to ensure that
# every component-scoped (`<COMP>_*`) and global (`LIBSCRIPT_*`) configuration
# variable referenced in `.sh`, `.cmd`, `.bat`, and `.ps1` scripts is declared and
# documented in either the component's local `vars.schema.json` or the global
# `_lib/_common/base_vars.schema.json`.
#
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

# ## show_help
# Displays command-line usage information for the schema variable auditor.
show_help() {
  printf 'Usage: %s [--all | --staged | <component_dir>...]\n' "$(basename "$THIS_FILE")"
  printf 'Audits component scripts for undocumented environment variables missing from JSON schemas.\n'
}

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "/?" ] || [ "${1:-}" = "-?" ]; then
  show_help
  exit 0
fi

BASE_SCHEMA="${LIBSCRIPT_ROOT_DIR}/_lib/_common/base_vars.schema.json"
ERRORS=0
AUDITED=0

# ## extract_schema_keys
# Extracts property key names from a JSON schema file using awk (zero external dependencies).
extract_schema_keys() {
  _schema_file="$1"
  if [ ! -f "$_schema_file" ]; then
    return 0
  fi
  awk '
    /"properties"[[:space:]]*:/ { in_props = 1; next }
    in_props && /^[[:space:]]*"[A-Za-z0-9_]+"[[:space:]]*:[[:space:]]*\{/ {
      line = $0
      sub(/^[[:space:]]*"/, "", line)
      sub(/".*$/, "", line)
      print line
    }
  ' "$_schema_file"
}

GLOBAL_KEYS=$(extract_schema_keys "$BASE_SCHEMA" | tr '\n' ' ')

# ## is_internal_runtime_var
# Returns 0 if a variable is an internal runtime/header variable that does not belong in user-facing vars.schema.json.
is_internal_runtime_var() {
  _var_name="$1"
  case "$_var_name" in
    LIBSCRIPT_ROOT_DIR|LIBSCRIPT_SERVERS_*|LIBSCRIPT_SERVICE_UNIT_UNCHANGED|LIBSCRIPT_INSTALL_MAP_*|LIBSCRIPT_ENV_sourced_*|LIBSCRIPT_IS_INSTALLED)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# ## audit_component_vars
# Audits a single component directory for undocumented <COMP>_* or LIBSCRIPT_* variables.
audit_component_vars() {
  _comp_dir="$1"
  case "$_comp_dir" in
    /*) ;;
    *) _comp_dir="${LIBSCRIPT_ROOT_DIR}/${_comp_dir#./}" ;;
  esac
  [ -d "$_comp_dir" ] || return 0

  _rel_dir="${_comp_dir#"${LIBSCRIPT_ROOT_DIR}"/}"
  case "$_rel_dir" in
    _lib/_common*) return 0 ;;
  esac
  [ -f "${_comp_dir}/vars.schema.json" ] || return 0

  AUDITED=$((AUDITED + 1))
  _comp_name=$(basename "$_comp_dir")
  _comp_prefix=$(printf '%s' "$_comp_name" | tr '[:lower:]-' '[:upper:]_')
  if [ "$_comp_name" = "7zip" ]; then
    _comp_prefix='SEVENZIP'
  fi

  _local_keys=$(extract_schema_keys "${_comp_dir}/vars.schema.json" | tr '\n' ' ')
  _all_allowed=" ${GLOBAL_KEYS} ${_local_keys} "

  # Temporarily allow glob expansion for script files in component directory
  set +f
  _used_vars=$(awk -v prefix="$_comp_prefix" '
    {
      sub(/\r$/, "", $0)
      if ($0 ~ /^[[:space:]]*(#|::|rem[[:space:]])/) next
      line = $0
      while (match(line, /(\$\{[A-Z][A-Z0-9_]*_[A-Z0-9_]+[:-]|\$env:[A-Z][A-Z0-9_]*_[A-Z0-9_]+|if[[:space:]]+not[[:space:]]+defined[[:space:]]+[A-Z][A-Z0-9_]*_[A-Z0-9_]+|if[[:space:]]+"%[A-Z][A-Z0-9_]*_[A-Z0-9_]+%"==""|printenv[[:space:]]+"?[A-Z][A-Z0-9_]*_[A-Z0-9_]+)/)) {
        chunk = substr(line, RSTART, RLENGTH)
        if (match(chunk, /[A-Z][A-Z0-9_]*_[A-Z0-9_]+/)) {
          tok = substr(chunk, RSTART, RLENGTH)
          if (index(tok, prefix "_") == 1 || index(tok, "LIBSCRIPT_") == 1) {
            print tok
          }
        }
        line = substr(line, RSTART + RLENGTH)
      }
    }
  ' "$_comp_dir"/*.sh "$_comp_dir"/*.cmd "$_comp_dir"/*.ps1 2>/dev/null | sort -u || true)
  set -f

  for _v in $_used_vars; do
    [ -n "$_v" ] || continue
    if is_internal_runtime_var "$_v"; then
      continue
    fi
    case "$_all_allowed" in
      *" ${_v} "*)
        ;;
      *)
        printf '[STANDARDS VIOLATION] [MISSING_JSON_VAR] %s/vars.schema.json: Variable "%s" is used in component scripts but missing from vars.schema.json (or base_vars.schema.json).\n' "$_rel_dir" "$_v" >&2
        ERRORS=$((ERRORS + 1))
        ;;
    esac
  done
}

if [ $# -eq 0 ] || [ "${1:-}" = "--all" ]; then
  _comp_dirs=$(find "${LIBSCRIPT_ROOT_DIR}/_lib" -mindepth 2 -maxdepth 2 -type d | sort)
  for _d in $_comp_dirs; do
    audit_component_vars "$_d"
  done
elif [ "${1:-}" = "--staged" ]; then
  _staged_comps=$(git diff --no-ext-diff --cached --name-only --diff-filter=ACM | awk -F'/' '$1 == "_lib" && $2 != "_common" && NF >= 3 { print $1 "/" $2 "/" $3 }' | sort -u)
  if [ -z "$_staged_comps" ]; then
    printf '[PASS] No staged component directories to audit for schema variables.\n'
    exit 0
  fi
  for _d in $_staged_comps; do
    audit_component_vars "$_d"
  done
else
  for _arg in "$@"; do
    if [ -f "$_arg" ]; then
      audit_component_vars "$(dirname "$_arg")"
    elif [ -d "$_arg" ]; then
      audit_component_vars "$_arg"
    fi
  done
fi

if [ "$ERRORS" -gt 0 ]; then
  printf '[FAIL] Schema Variable Audit failed with %d undocumented variable(s) across %d component(s).\n' "$ERRORS" "$AUDITED" >&2
  exit 1
fi

printf '[PASS] All %d audited component(s) have 100%% of their configuration variables documented in JSON schemas.\n' "$AUDITED"
exit 0
