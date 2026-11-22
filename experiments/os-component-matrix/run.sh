#!/bin/sh
# ## Overview
# Aggregates multi-OS test markers into a provenance-stamped `matrix_results.json` conforming to
# `experiments/schemas/os-matrix-results.schema.json` and deterministically updates `README.md` without plan side-effects.
#
# ## Usage
# ./experiments/os-component-matrix/run.sh [--results-dir=<dir>] [--readme-out=<README.md>]

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

RESULTS_DIR="${LIBSCRIPT_ROOT_DIR}/build/experiments/os-component-matrix"
TARGET_README="${README_OUT:-${LIBSCRIPT_ROOT_DIR}/README.md}"
while [ $# -gt 0 ]; do
  case "$1" in
    --results-dir=*) RESULTS_DIR="${1#*=}"; shift ;;
    --readme-out=*) TARGET_README="${1#*=}"; shift ;;
    *) shift ;;
  esac
done

mkdir -p "$RESULTS_DIR"
RAW_JSON="${RESULTS_DIR}/raw_matrix.json"
FINAL_JSON="${RESULTS_DIR}/matrix_results.json"

"${LIBSCRIPT_ROOT_DIR}/tests/update_results.sh" --output "$TARGET_README" --json "$RAW_JSON"
GIT_SHA=$(git -C "$LIBSCRIPT_ROOT_DIR" rev-parse HEAD 2>/dev/null || printf 'unknown')
TS_NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if [ -f "$RAW_JSON" ]; then
  jq --arg ts "$TS_NOW" --arg sha "$GIT_SHA" '
    if type == "array" then
      { generated_at: $ts, git_commit: $sha, components: . }
    else
      . + { generated_at: (.generated_at // $ts), git_commit: (.git_commit // $sha) }
    end
  ' "$RAW_JSON" > "${FINAL_JSON}.tmp"
  mv "${FINAL_JSON}.tmp" "$FINAL_JSON"
  rm -f "$RAW_JSON"
else
  printf '{"generated_at":"%s","git_commit":"%s","components":[]}\n' "$TS_NOW" "$GIT_SHA" > "$FINAL_JSON"
fi
printf '[OK] Emitted 7-OS compatibility matrix JSON at %s\n' "$FINAL_JSON"
