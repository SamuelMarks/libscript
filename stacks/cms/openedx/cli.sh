#!/bin/sh
# ## Overview
# Command-line interface router for the Open edX stack.
# Routes subcommands to core lifecycle handlers or dedicated feature modules:
# user, demo, dbshell, healthcheck, config, backup, restore, workers, theme, xblock, upgrade, mfe.
#
# ## Usage
#   ./cli.sh <subcommand> [args...]
#   ./cli.sh help

set -feu
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE}"
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"
' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"
' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd -- "$(dirname -- "${THIS_FILE}")" && pwd)
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s
' "$d")}"
export DIR="${SCRIPT_DIR}"

case "${1:-}" in
  start|stop|restart|status|lms|studio|cms)
    SCRIPT_NAME="${SCRIPT_DIR}/service.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090
    exec "${SCRIPT_NAME}" "$@"
    ;;
  user)
    shift
    SCRIPT_NAME="${SCRIPT_DIR}/user.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090
    exec "${SCRIPT_NAME}" "$@"
    ;;
  demo)
    shift
    SCRIPT_NAME="${SCRIPT_DIR}/import_demo.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090
    exec "${SCRIPT_NAME}" "$@"
    ;;
  dbshell|mongosh|redis-cli)
    SCRIPT_NAME="${SCRIPT_DIR}/dbshell.sh"
    export SCRIPT_NAME
    if [ "$1" = "mongosh" ]; then
      shift
      exec "${SCRIPT_NAME}" mongo "$@"
    elif [ "$1" = "redis-cli" ]; then
      shift
      exec "${SCRIPT_NAME}" redis "$@"
    else
      shift
      exec "${SCRIPT_NAME}" "$@"
    fi
    ;;
  healthcheck|health|status-all)
    shift
    SCRIPT_NAME="${SCRIPT_DIR}/healthcheck.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090
    exec "${SCRIPT_NAME}" "$@"
    ;;
  config)
    shift
    SCRIPT_NAME="${SCRIPT_DIR}/config.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090
    exec "${SCRIPT_NAME}" "$@"
    ;;
  backup)
    shift
    SCRIPT_NAME="${SCRIPT_DIR}/backup.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090
    exec "${SCRIPT_NAME}" "$@"
    ;;
  restore)
    shift
    SCRIPT_NAME="${SCRIPT_DIR}/restore.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090
    exec "${SCRIPT_NAME}" "$@"
    ;;
  workers)
    shift
    SCRIPT_NAME="${SCRIPT_DIR}/workers.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090
    exec "${SCRIPT_NAME}" "$@"
    ;;
  theme)
    shift
    SCRIPT_NAME="${SCRIPT_DIR}/theme.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090
    exec "${SCRIPT_NAME}" "$@"
    ;;
  xblock|plugin)
    shift
    SCRIPT_NAME="${SCRIPT_DIR}/xblock.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090
    exec "${SCRIPT_NAME}" "$@"
    ;;
  upgrade)
    shift
    SCRIPT_NAME="${SCRIPT_DIR}/upgrade.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090
    exec "${SCRIPT_NAME}" "$@"
    ;;
  mfe)
    shift
    SCRIPT_NAME="${SCRIPT_DIR}/mfe.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090
    exec "${SCRIPT_NAME}" "$@"
    ;;
esac

export PACKAGE_NAME="openedx"
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}/_lib/_common/component_core.sh"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"
