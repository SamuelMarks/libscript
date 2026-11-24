#!/bin/sh
# ## Overview
# Smoke validation and idempotent dry-run + LaTeX synthesis check for the `gemma-4-sql` experiment plugin.
# ## Usage
# ./experiments/gemma-4-sql/test.sh

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

# ## run_plugin_smoke_test
# Validates suite.json/vars.schema.json and verifies dry-run + --render-latex synthesis idempotently.
run_plugin_smoke_test() {
  STACK='' "${LIBSCRIPT_ROOT_DIR}/experiments/engine.sh" validate 'gemma-4-sql' >/dev/null
  _smoke_tmp=$(mktemp -d)
  STACK='' "${LIBSCRIPT_ROOT_DIR}/experiments/gemma-4-sql/benchmark_experiments.sh" --dry-run --repo-dir="${_smoke_tmp}" --results-dir="${_smoke_tmp}/out" >/dev/null
  STACK='' "${LIBSCRIPT_ROOT_DIR}/experiments/gemma-4-sql/benchmark_experiments.sh" --render-latex --repo-dir="${_smoke_tmp}" --results-dir="${_smoke_tmp}/out" >/dev/null
  [ -s "${_smoke_tmp}/out/comparison_summary.json" ]
  [ -s "${_smoke_tmp}/out/generated_metrics.tex" ]
  rm -rf "${_smoke_tmp}"
}

run_plugin_smoke_test
