#!/bin/sh
# ## Overview
# Command-line interface router for the Open edX stack.
# Routes subcommands to core lifecycle handlers or dedicated feature modules:
# user, demo, dbshell, healthcheck, config, backup, restore, workers, theme, xblock, upgrade, mfe, logs,
# plus full Tutor parity commands (do, local, dev, plugins).
#
# ## Usage
#   ./cli.sh <subcommand> [args...]
#   ./cli.sh do <job> [args...]
#   ./cli.sh local <subcommand> [args...]
#   ./cli.sh help

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
export DIR="${SCRIPT_DIR}"

# ## handle_tutor_do
# Dispatches tutor 'do' task commands to native Open edX handlers.
# ## handle_tutor_do
# Executes the handle_tutor_do logic.
handle_tutor_do() {
  _job="${1:-}"
  if [ -z "${_job}" ]; then
    printf 'Error: Tutor "do" requires a task command (e.g., createuser, setpassword, importdemocourse, settheme, sqlshell, mongosh, reindex, run)\n' >&2
    exit 1
  fi
  shift
  case "${_job}" in
    createuser)
      SCRIPT_NAME="${SCRIPT_DIR}/user.sh"
      export SCRIPT_NAME
      exec "${SCRIPT_NAME}" create "$@"
      ;;
    setpassword)
      SCRIPT_NAME="${SCRIPT_DIR}/user.sh"
      export SCRIPT_NAME
      exec "${SCRIPT_NAME}" set-password "$@"
      ;;
    importdemocourse)
      SCRIPT_NAME="${SCRIPT_DIR}/import_demo.sh"
      export SCRIPT_NAME
      exec "${SCRIPT_NAME}" course "$@"
      ;;
    importdemolibraries)
      SCRIPT_NAME="${SCRIPT_DIR}/import_demo.sh"
      export SCRIPT_NAME
      exec "${SCRIPT_NAME}" libraries "$@"
      ;;
    settheme)
      SCRIPT_NAME="${SCRIPT_DIR}/theme.sh"
      export SCRIPT_NAME
      exec "${SCRIPT_NAME}" set "$@"
      ;;
    sqlshell)
      SCRIPT_NAME="${SCRIPT_DIR}/dbshell.sh"
      export SCRIPT_NAME
      exec "${SCRIPT_NAME}" mysql "$@"
      ;;
    mongosh)
      SCRIPT_NAME="${SCRIPT_DIR}/dbshell.sh"
      export SCRIPT_NAME
      exec "${SCRIPT_NAME}" mongo "$@"
      ;;
    reindex)
      OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR:-${LIBSCRIPT_HOME:-$HOME/.libscript}/openedx}"
      if [ -x "${OPENEDX_INSTALL_DIR}/.venv/bin/python" ] && [ -f "${OPENEDX_INSTALL_DIR}/manage.py" ]; then
        (cd "${OPENEDX_INSTALL_DIR}" && "${OPENEDX_INSTALL_DIR}/.venv/bin/python" manage.py cms reindex_course --active)
      else
        printf 'Error: Open edX environment not initialized at %s\n' "${OPENEDX_INSTALL_DIR}" >&2
        exit 1
      fi
      ;;
    run)
      _svc="${1:-}"
      if [ -z "${_svc}" ]; then
        printf 'Usage: do run <lms|cms> <command...>\n' >&2
        exit 1
      fi
      shift
      OPENEDX_INSTALL_DIR="${OPENEDX_INSTALL_DIR:-${LIBSCRIPT_HOME:-$HOME/.libscript}/openedx}"
      if [ -x "${OPENEDX_INSTALL_DIR}/.venv/bin/python" ]; then
        export PATH="${OPENEDX_INSTALL_DIR}/.venv/bin:${PATH}"
        (cd "${OPENEDX_INSTALL_DIR}" && "$@")
      else
        printf 'Error: Virtual environment not found in %s\n' "${OPENEDX_INSTALL_DIR}" >&2
        exit 1
      fi
      ;;
    *)
      printf 'Error: Unknown tutor job "%s"\n' "${_job}" >&2
      exit 1
      ;;
  esac
}

case "${1:-}" in
  do)
    shift
    handle_tutor_do "$@"
    ;;
  local|dev)
    shift
    _subcmd="${1:-}"
    shift || true
    case "${_subcmd}" in
      start|stop|restart|reboot|status)
        SCRIPT_NAME="${SCRIPT_DIR}/service.sh"
        export SCRIPT_NAME
        exec "${SCRIPT_NAME}" "${_subcmd}" "$@"
        ;;
      logs)
        SCRIPT_NAME="${SCRIPT_DIR}/logs.sh"
        export SCRIPT_NAME
        exec "${SCRIPT_NAME}" "$@"
        ;;
      upgrade)
        SCRIPT_NAME="${SCRIPT_DIR}/upgrade.sh"
        export SCRIPT_NAME
        exec "${SCRIPT_NAME}" "$@"
        ;;
      do)
        handle_tutor_do "$@"
        ;;
      *)
        SCRIPT_NAME="${SCRIPT_DIR}/service.sh"
        export SCRIPT_NAME
        exec "${SCRIPT_NAME}" "${_subcmd}" "$@"
        ;;
    esac
    ;;
  plugins)
    shift
    SCRIPT_NAME="${SCRIPT_DIR}/xblock.sh"
    export SCRIPT_NAME
    exec "${SCRIPT_NAME}" "$@"
    ;;
  start|stop|restart|status|lms|studio|cms|install-service|uninstall-service)
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
  logs)
    shift
    SCRIPT_NAME="${SCRIPT_DIR}/logs.sh"
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
