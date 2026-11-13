#!/bin/sh
# ## Overview
# Command-line interface entrypoint for the `libtpu-rs` component. Routes `experiments` and `cloud-experiments` (`rapid-experiment`) to the empirical evaluation harness and delegates standard Version Manager Contract verbs to `component_core.sh`.
#
# ## Usage
# ./_lib/toolchains/libtpu-rs/cli.sh [install|use|ls|ls-remote|experiments|cloud-experiments|...] [args]

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

case "${1:-}" in
  experiments|bench)
    shift
    unset SCRIPT_NAME || true
    STACK="${STACK%"${THIS_FILE}":}"
    export STACK
    exec "${SCRIPT_DIR}/benchmark_experiments.sh" "$@"
    ;;
  cloud-experiments|rapid-experiment)
    shift
    unset SCRIPT_NAME || true
    STACK="${STACK%"${THIS_FILE}":}"
    export STACK
    export CORE_EXPERIMENT_SUITE="${CORE_EXPERIMENT_SUITE:-libtpu}"
    exec "${LIBSCRIPT_ROOT_DIR}/_lib/cloud/core/experiment_cloud.sh" "$@"
    ;;
esac

export PACKAGE_NAME='libtpu-rs'
SCRIPT_NAME="${SCRIPT_DIR}/../../_common/component_core.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090,SC1091
. "${SCRIPT_NAME}"
