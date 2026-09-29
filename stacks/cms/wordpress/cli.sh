#!/bin/sh
# ## Overview
# Command-line interface router for the WordPress 7.1.2 platform stack.
# Dispatches subcommands to core lifecycle daemons and management feature modules:
# user, config, dbshell, healthcheck, backup, restore, service, cron, upgrade, and wp.
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
  start|stop|restart|status)
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
  config)
    shift
    SCRIPT_NAME="${SCRIPT_DIR}/config.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090
    exec "${SCRIPT_NAME}" "$@"
    ;;
  dbshell|sql|query)
    shift
    SCRIPT_NAME="${SCRIPT_DIR}/dbshell.sh"
    export SCRIPT_NAME
    # shellcheck disable=SC1090
    exec "${SCRIPT_NAME}" "$@"
    ;;
  healthcheck|health|status-all)
    shift
    SCRIPT_NAME="${SCRIPT_DIR}/healthcheck.sh"
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
  cron)
    shift
    SCRIPT_NAME="${SCRIPT_DIR}/cron.sh"
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
  wp)
    shift
    WWWROOT="${WORDPRESS_WWWROOT:-/var/www/wordpress}"
    if command -v wp >/dev/null 2>&1; then
      exec wp --path="${WWWROOT}" "$@"
    elif [ -f "${LIBSCRIPT_ROOT_DIR}/cache/wp-cli.phar" ]; then
      exec php "${LIBSCRIPT_ROOT_DIR}/cache/wp-cli.phar" --path="${WWWROOT}" "$@"
    else
      printf '[ERROR] WP-CLI binary not found in PATH or cache.
' >&2
      exit 1
    fi
    ;;
  help|--help|-h|"")
    cat << 'EOF_HELP'
WordPress 7.1.2 Management Console

Usage:
  ./cli.sh <subcommand> [args...]

Subcommands:
  user        WordPress user administration (create, list, set-password, delete)
  config      Read and modify wp-config.php and stack environment configuration
  dbshell     Interactive MySQL database shell and query executor
  healthcheck Run comprehensive system diagnostics and connectivity tests
  backup      Create full-state snapshot archives of database, uploads, and config
  restore     Restore WordPress database and files from snapshot archive
  service     Manage web server (Nginx/Apache/Caddy) and PHP-FPM daemons
  cron        Manage and trigger scheduled WP-Cron background tasks
  upgrade     Execute safe WordPress release upgrade pipeline
  wp          Execute raw WP-CLI commands against WordPress document root
EOF_HELP
    exit 0
    ;;
  *)
    printf '[ERROR] Unknown subcommand: %s
' "$1" >&2
    printf 'Run "./cli.sh help" for available commands.
' >&2
    exit 1
    ;;
esac
