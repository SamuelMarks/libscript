#!/bin/sh
# ## Overview
# Tier 4 (T4) unified infrastructure & cluster substrate CLI router dispatching cloud IaaS provisioning,
# cloud resource operators, image imports, Marketplace publishing, and cluster substrate choreography.
#
# ## Usage
# ./infrastructure/cli.sh <provision|deprovision|cluster|import-image|publish-marketplace|backup|restore|provider> [args...]

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

# ## show_infra_help
# Displays usage instructions for the T4 infrastructure router.
show_infra_help() {
  printf '%s\n' 'Usage: ./infrastructure/cli.sh <provision|deprovision|cluster|import-image|publish-marketplace|backup|restore> [args...]'
}

SUBCMD="${1:-}"
shift || true

case "$SUBCMD" in
  --help|-h|'')
    show_infra_help
    exit 0
    ;;
  provision)
    exec "${LIBSCRIPT_ROOT_DIR}/infrastructure/cli_actions/provision.sh" "$@"
    ;;
  deprovision)
    exec "${LIBSCRIPT_ROOT_DIR}/infrastructure/cli_actions/deprovision.sh" "$@"
    ;;
  backup|export-remote)
    exec "${LIBSCRIPT_ROOT_DIR}/infrastructure/cli_actions/backup.sh" "$@"
    ;;
  restore|import-remote)
    exec "${LIBSCRIPT_ROOT_DIR}/infrastructure/cli_actions/restore.sh" "$@"
    ;;
  import-image)
    exec "${LIBSCRIPT_ROOT_DIR}/infrastructure/resources/image-import/cli.sh" "$@"
    ;;
  publish-marketplace)
    exec "${LIBSCRIPT_ROOT_DIR}/infrastructure/marketplace/publish.sh" "$@"
    ;;
  cluster)
    _cl_verb="${1:-status}"
    shift || true
    case "$_cl_verb" in
      plan) exec "${LIBSCRIPT_ROOT_DIR}/infrastructure/clusters/engine.sh" 'up' "$@" '--dry-run' ;;
      fence) exec "${LIBSCRIPT_ROOT_DIR}/infrastructure/clusters/engine.sh" 'failover' "$@" ;;
      *) exec "${LIBSCRIPT_ROOT_DIR}/infrastructure/clusters/engine.sh" "$_cl_verb" "$@" ;;
    esac
    ;;
  *)
    if [ -x "${LIBSCRIPT_ROOT_DIR}/infrastructure/providers/${SUBCMD}/cli.sh" ]; then
      exec "${LIBSCRIPT_ROOT_DIR}/infrastructure/providers/${SUBCMD}/cli.sh" "$@"
    elif [ -x "${LIBSCRIPT_ROOT_DIR}/infrastructure/resources/${SUBCMD}/cli.sh" ]; then
      exec "${LIBSCRIPT_ROOT_DIR}/infrastructure/resources/${SUBCMD}/cli.sh" "$@"
    fi
    printf "Error: Unknown infrastructure subcommand '%s'.\n" "$SUBCMD" >&2
    exit 1
    ;;
esac
