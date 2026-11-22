#!/bin/sh
# ## Overview
# Tier 5 (T5) unified workloads CLI router dispatching declarative scheduler payloads, stateful HA service constellations,
# multi-service web application stacks, local/remote stack deployments, and distributed AI/ML training & serving jobs.
#
# ## Usage
# ./workloads/cli.sh <workload|payload|constellation|stack|app|deploy|deploy-remote|up|down|start|stop|status|train|infer> [args...]

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

# ## show_workloads_help
# Displays usage instructions for the T5 workloads router.
show_workloads_help() {
  printf '%s\n' 'Usage: ./workloads/cli.sh <workload|payload|constellation|stack|app|deploy|deploy-remote|up|down|start|stop|status|train|infer> [args...]'
}

SUBCMD="${1:-}"
shift || true

case "$SUBCMD" in
  --help|-h|'')
    show_workloads_help
    exit 0
    ;;
  workload|payload)
    exec "${LIBSCRIPT_ROOT_DIR}/workloads/engine.sh" "$@"
    ;;
  constellation)
    exec "${LIBSCRIPT_ROOT_DIR}/workloads/constellations/engine.sh" "$@"
    ;;
  app)
    _app_name="${1:-}"
    shift || true
    if [ -x "${LIBSCRIPT_ROOT_DIR}/workloads/apps/${_app_name}/cli.sh" ]; then
      exec "${LIBSCRIPT_ROOT_DIR}/workloads/apps/${_app_name}/cli.sh" "$@"
    fi
    printf "Error: Unknown application stack '%s'.\n" "$_app_name" >&2
    exit 1
    ;;
  deploy)
    exec "${LIBSCRIPT_ROOT_DIR}/workloads/services/deploy.sh" "$@"
    ;;
  deploy-remote)
    exec "${LIBSCRIPT_ROOT_DIR}/workloads/services/deploy-remote.sh" "$@"
    ;;
  stack)
    exec "${LIBSCRIPT_ROOT_DIR}/workloads/services/actions.sh" "$@"
    ;;
  start|stop|status|health|logs|restart|up|down|deprovision-db|export-state|import-state|prepare-storage|uninstall-service)
    export CMD="$SUBCMD"
    exec "${LIBSCRIPT_ROOT_DIR}/workloads/services/actions.sh" "$SUBCMD" "$@"
    ;;
  train|infer|serve-ml|eval-ml|benchmark-ml)
    export CMD="$SUBCMD"
    exec "${LIBSCRIPT_ROOT_DIR}/workloads/ai/actions.sh" "$SUBCMD" "$@"
    ;;
  *)
    printf "Error: Unknown workloads subcommand '%s'.\n" "$SUBCMD" >&2
    exit 1
    ;;
esac
