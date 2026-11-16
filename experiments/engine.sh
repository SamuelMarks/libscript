#!/bin/sh
# ## Overview
# Open/Closed Research Experiment Plugin Engine auto-discovering `experiments/<suite-id>/suite.json`
# suites and executing `list`, `scaffold`, `validate`, `provision`, `sync`, `run`, `collect`,
# `render-latex`, `update-readme`, `test`, and `teardown`.
#
# ## Usage
# ./experiments/engine.sh <list|scaffold|validate|provision|sync|run|collect|render-latex|update-readme|test|teardown> [suite-id] [--key=value ...]

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

# ## ensure_jq
# Ensures jq is available on PATH, bootstrapping _lib/utilities/jq idempotently if required.
ensure_jq() {
  if command -v jq >/dev/null 2>&1; then
    return 0
  fi
  if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh" ]; then
    _ej_this="$THIS_FILE"
    _ej_dir="$SCRIPT_DIR"
    SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090,SC1091
    if . "$SCRIPT_NAME" >/dev/null 2>&1; then :; fi
    unset SCRIPT_NAME || true
    THIS_FILE="$_ej_this"
    SCRIPT_DIR="$_ej_dir"
  fi
  if ! command -v jq >/dev/null 2>&1; then
    STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install jq latest >/dev/null 2>&1
    if [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh" ]; then
      _ej_this="$THIS_FILE"
      _ej_dir="$SCRIPT_DIR"
      SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/utilities/jq/env.sh"
      export SCRIPT_NAME
      # shellcheck disable=SC1090,SC1091
      if . "$SCRIPT_NAME" >/dev/null 2>&1; then :; fi
      unset SCRIPT_NAME || true
      THIS_FILE="$_ej_this"
      SCRIPT_DIR="$_ej_dir"
    fi
  fi
}

EXP_ROOT="${LIBSCRIPT_EXPERIMENTS_DIR:-${SCRIPT_DIR}}"
VERB="${1:-list}"
shift 2>/dev/null || true

case "$VERB" in
  --help|-h)
    printf '%s\n' 'Usage: libscript.sh experiment <list|scaffold|validate|provision|sync|run|collect|render-latex|update-readme|test|teardown> [suite-id] [--key=value ...]'
    exit 0
    ;;
  list)
    ensure_jq
    set +f
    for _sf in "${EXP_ROOT}"/*/suite.json; do
      [ -f "$_sf" ] || continue
      jq -r '"\(.id)\t\(.substrate // "local-native")\t\(.title)"' "$_sf"
    done
    set -f
    exit 0
    ;;
  scaffold)
    exec "${LIBSCRIPT_ROOT_DIR}/cli/commands/experiment/scaffold.sh" "$@"
    ;;
  update-readme)
    exec "${LIBSCRIPT_ROOT_DIR}/tests/update_results.sh" "$@"
    ;;
esac

ensure_jq

SUITE_ID="${1:-}"
[ -n "$SUITE_ID" ] || { printf '[ERROR] <suite-id> required for verb "%s"\n' "$VERB" >&2; exit 1; }
shift

SUITE_DIR="${EXP_ROOT}/${SUITE_ID}"
SUITE_JSON="${SUITE_DIR}/suite.json"
[ -f "$SUITE_JSON" ] || { printf '[ERROR] Experiment plugin not found: %s\n' "$SUITE_JSON" >&2; exit 1; }

# ## validate_suite_manifest
# Validates suite.json against experiment-suite.schema.json required fields, substrate enum, and installer_e2e references.
validate_suite_manifest() {
  jq -e '
    (.id | type == "string" and length > 0)
    and (.title | type == "string" and length > 0)
    and (.protocol_version | type == "string" and length > 0)
    and (.subsuites | type == "array" and length > 0)
    and ((.substrate // "local-native") | IN("local-native", "vagrant-os-matrix", "installer-e2e", "cloud-vm", "tpu-slice", "gke-xpk"))
  ' "$SUITE_JSON" >/dev/null || return 1

  _pkg_manifest=$(jq -r '.installer_e2e.packaging_manifest // empty' "$SUITE_JSON")
  if [ -n "$_pkg_manifest" ]; then
    case "$_pkg_manifest" in
      /*) _resolved_manifest="$_pkg_manifest" ;;
      *) _resolved_manifest="${SUITE_DIR}/${_pkg_manifest}" ;;
    esac
    if [ ! -f "$_resolved_manifest" ]; then
      printf '[ERROR] Missing packaging_manifest referenced by suite.json: %s\n' "$_resolved_manifest" >&2
      return 1
    fi
  fi
  return 0
}

# ## validate_and_export_suite_vars
# Validates --key=value flags against vars.schema.json (when declared) and exports UPPER_SNAKE vars.
validate_and_export_suite_vars() {
  _vars_schema="${SUITE_DIR}/vars.schema.json"
  for _arg in "$@"; do
    case "$_arg" in
      --*=*)
        _raw_k="${_arg%%=*}"
        _raw_k="${_raw_k#--}"
        _val="${_arg#*=}"
        case "$_raw_k" in
          results-dir|paper-dir|repo-dir|subsuites|tfrc-config|backends|model|output|json|suite-dir|phase) continue ;;
        esac
        _env_k=$(printf '%s' "$_raw_k" | tr '[:lower:]-' '[:upper:]_')
        case "$_raw_k" in
          target-os|bento-prefix|bento-dir|provider|pkg-format|pkg-source|release-repo|release-tag|install-modes|force-rebuild|dry-run)
            export "${_env_k}=${_val}"
            continue
            ;;
        esac
        if [ -f "$_vars_schema" ]; then
          if ! jq -e --arg k "$_env_k" '(.properties // {}) | has($k)' "$_vars_schema" >/dev/null 2>&1; then
            printf '[ERROR] Unknown suite flag --%s (not declared in %s)\n' "$_raw_k" "$_vars_schema" >&2
            exit 1
          fi
        fi
        export "${_env_k}=${_val}"
        ;;
    esac
  done
}

# ## provision_suite_dependencies
# Installs required Tier 1 components idempotently and delegates installer-e2e box provisioning when applicable.
provision_suite_dependencies() {
  for _comp in $(jq -r '.required_components[]? // empty' "$SUITE_JSON"); do
    if command -v "$_comp" >/dev/null 2>&1 || [ -d "${LIBSCRIPT_HOME:-${HOME:-/tmp}/.libscript}/${_comp}" ]; then
      printf '[PROVISION] Verified required Tier 1 component: %s\n' "$_comp"
    else
      printf '[PROVISION] Installing required Tier 1 component via LibScript: %s\n' "$_comp"
      STACK='' "${LIBSCRIPT_ROOT_DIR}/libscript.sh" install "$_comp" latest
    fi
  done
  _sub=$(jq -r '.substrate // "local-native"' "$SUITE_JSON")
  if [ "$_sub" = 'installer-e2e' ] && [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/_common/experiment/pkg_ui_runner.sh" ]; then
    STACK='' sh "${LIBSCRIPT_ROOT_DIR}/_lib/_common/experiment/pkg_ui_runner.sh" --suite-dir="${SUITE_DIR}" --phase=provision "$@"
  fi
}

case "$VERB" in
  validate)
    validate_suite_manifest || { printf '[FAIL] Invalid suite.json: %s\n' "$SUITE_JSON" >&2; exit 1; }
    [ -f "${SUITE_DIR}/run.sh" ] && [ -f "${SUITE_DIR}/run.cmd" ] || { printf '[FAIL] Missing run.sh/run.cmd in %s\n' "$SUITE_DIR" >&2; exit 1; }
    validate_and_export_suite_vars "$@"
    printf '[PASS] Experiment suite "%s" validated cleanly.\n' "$SUITE_ID"
    ;;
  provision)
    validate_suite_manifest
    validate_and_export_suite_vars "$@"
    provision_suite_dependencies "$@"
    ;;
  sync|collect|teardown)
    validate_suite_manifest
    validate_and_export_suite_vars "$@"
    if [ -f "${SUITE_DIR}/${VERB}.sh" ]; then
      STACK='' exec sh "${SUITE_DIR}/${VERB}.sh" "$@"
    fi
    _sub=$(jq -r '.substrate // "local-native"' "$SUITE_JSON")
    if [ "$_sub" = 'installer-e2e' ] && [ -f "${LIBSCRIPT_ROOT_DIR}/_lib/_common/experiment/pkg_ui_runner.sh" ]; then
      STACK='' exec sh "${LIBSCRIPT_ROOT_DIR}/_lib/_common/experiment/pkg_ui_runner.sh" --suite-dir="${SUITE_DIR}" --phase="${VERB}" "$@"
    fi
    printf '[OK] Experiment "%s" lifecycle phase "%s" completed.\n' "$SUITE_ID" "$VERB"
    ;;
  render-latex)
    validate_suite_manifest
    validate_and_export_suite_vars "$@"
    EXPERIMENT_PHASE='render-latex' export EXPERIMENT_PHASE
    STACK='' exec sh "${SUITE_DIR}/run.sh" --render-latex "$@"
    ;;
  run)
    validate_suite_manifest
    validate_and_export_suite_vars "$@"
    STACK='' exec sh "${SUITE_DIR}/run.sh" "$@"
    ;;
  test)
    STACK='' exec sh "${SUITE_DIR}/test.sh" "$@"
    ;;
  *)
    printf '[ERROR] Unsupported experiment verb: %s\n' "$VERB" >&2
    exit 1
    ;;
esac
