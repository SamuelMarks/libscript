#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  THIS_FILE="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  THIS_FILE="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  THIS_FILE="${(%):-%x}"
  set -o pipefail
else
  THIS_FILE="${0}"
fi

case "${STACK+x}" in
  *':'"${THIS_FILE}"':'*)
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
SCRIPT_DIR=$(cd "$(dirname -- "${THIS_FILE}")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-${SCRIPT_DIR}}"
export LIBSCRIPT_ROOT_DIR

# Source logging
for LIB in _lib/_common/log.sh ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  export SCRIPT_NAME
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

show_help() {
  echo "LibScript Global CLI"
  echo "===================="
  echo ""
  echo "Usage: $0 [COMMAND] [ARGS...]"
  echo ""
  echo "Commands:"
  echo "  list                        List all available components"
  echo "  search <query>              Search available components by name or description"
  echo "  process-downloads [file]    Process an aria2-formatted download list"
  echo "  env <component> <version>   Print environment variables for a component"
  echo "  install-deps [file]         Install all dependencies defined in a JSON file (default: libscript.json)"
  echo "  package_as <format> [args]  Package libscript usage (e.g., docker, docker_compose)"
  echo "  start [package_name...]     Start services (or all deps in json)"
  echo "  stop [package_name...]      Stop services"
  echo "  status [package_name...]    Show service status"
  echo "  health [package_name...]    Check service health"
  echo "  restart [package_name...]   Restart services"
  echo "  logs [-f] [package_name...]  Show service logs (real-time stream)"
  echo "  up [package_name...]        Alias for start"
  echo "  down [package_name...]      Alias for stop"
  echo "  provision <provider> ...    Provision a cloud environment"
  echo "  deprovision <provider> ...  Deprovision a cloud environment"
  echo "  <component> [OPTIONS...]    Invoke the CLI for a specific component"
  echo ""
  echo "Options:"
  echo "  --help, -h, /?              Show this extensive help text"
  echo "  --prefix=<dir>              Set local installation prefix"
  echo "  --log-format=<text|json>    Set log output format"
  echo "  --log-level=<0-4>           Set minimum log level (0=DEBUG, 1=INFO, etc)"
  echo "  --log-file=<path>           Set a file to mirror all logs to"
  echo "  --service-name=<name>       Set a custom service/daemon name"
  echo "  --secrets=<dir|url>         Save generated secrets to a directory or OpenBao/Vault URL"
  echo "  --listen=<str>                Global listen (port, addr:port, unix:socket)
  --listen-port=<port>        Global port to listen on"
  echo "  --listen-address=<addr>     Global address to listen on"
  echo "  --listen-socket=<socket>    Global unix socket to listen on"
  echo ""
  echo "Examples:"
  echo "  $0 list"
  echo "  $0 search ruby"
  echo "  $0 ruby --help"
  echo "  $0 postgres --help"
  echo ""
  echo "You can specify components by their short name (e.g., 'ruby' instead of '_lib/languages/ruby')."
  echo "If there are multiple matches, it will ask you to be more specific."
  echo ""
}

find_components() {
  find "$SCRIPT_DIR" -name "cli.sh" | while read -r cli_script; do
    dir=$(dirname "$cli_script")
    if [ -f "$dir/vars.schema.json" ]; then
      rel_dir="${dir#"$SCRIPT_DIR"/}"
      if [ "$rel_dir" != "$dir" ]; then
        echo "$rel_dir"
      fi
    fi
  done
}

get_desc() {
  schema="$SCRIPT_DIR/$1/vars.schema.json"
  if command -v jq >/dev/null 2>&1; then
    jq -r '
      def aliases: [ .properties[]? | select(.version_aliases) | .version_aliases[] ] | unique | join(", ");
      if .description then
        if (aliases | length > 0) then .description + " [version aliases: " + aliases + "]" else .description end
      else "" end
    ' "$schema" 2>/dev/null || true
  fi
}

while [ $# -gt 0 ]; do
  case "$1" in
    --cache-dir=*)
      export LIBSCRIPT_CACHE_DIR="${1#*=}"
      shift
      ;;
    --log-format=*)
      export LIBSCRIPT_LOG_FORMAT="${1#*=}"
      shift
      ;;
    --log-level=*)
      export LIBSCRIPT_LOG_LEVEL="${1#*=}"
      shift
      ;;
    --log-file=*)
      export LIBSCRIPT_LOG_FILE="${1#*=}"
      shift
      ;;
    --prefix=*)
      export PREFIX="${1#*=}"
      shift
      ;;
    --listen=*)
      LISTEN_STR="${1#*=}"
      if echo "$LISTEN_STR" | grep -q "^unix:"; then
        export LIBSCRIPT_LISTEN_SOCKET="${LISTEN_STR#unix:}"
      elif echo "$LISTEN_STR" | grep -q ":"; then
        export LIBSCRIPT_LISTEN_ADDRESS="${LISTEN_STR%%:*}"
        export LIBSCRIPT_LISTEN_PORT="${LISTEN_STR##*:}"
      else
        export LIBSCRIPT_LISTEN_PORT="$LISTEN_STR"
      fi
      shift
      ;;
    --listen-port=*)
      export LIBSCRIPT_LISTEN_PORT="${1#*=}"
      shift
      ;;
    --listen-address=*)
      export LIBSCRIPT_LISTEN_ADDRESS="${1#*=}"
      shift
      ;;
    --listen-socket=*)
      export LIBSCRIPT_LISTEN_SOCKET="${1#*=}"
      shift
      ;;
    --service-name=*)
      export LIBSCRIPT_SERVICE_NAME="${1#*=}"
      shift
      ;;
    --secrets=*)
      export LIBSCRIPT_SECRETS="${1#*=}"
      shift
      ;;
    *)
      break
      ;;
  esac
done
CMD="$1"
if [ -z "$CMD" ] || [ "$CMD" = "--help" ] || [ "$CMD" = "-h" ] || [ "$CMD" = "/?" ]; then
  show_help
  exit 0
fi

if [ "$CMD" = "--version" ] || [ "$CMD" = "-v" ]; then
  echo "${LIBSCRIPT_VERSION:-dev}"
  exit 0
fi

shift || true

case "$CMD" in
  list) . "$SCRIPT_DIR/cli/commands/core/list.sh" ;;
  process-downloads) . "$SCRIPT_DIR/cli/commands/deps/process_downloads.sh" ;;
  provision) . "$SCRIPT_DIR/cli/commands/cloud/provision.sh" ;;
  deprovision) . "$SCRIPT_DIR/cli/commands/cloud/deprovision.sh" ;;
  search) . "$SCRIPT_DIR/cli/commands/core/search.sh" ;;
  start|stop|status|health|logs|restart|up|down) . "$SCRIPT_DIR/cli/commands/services/actions.sh" ;;
  install-deps) . "$SCRIPT_DIR/cli/commands/deps/install.sh" ;;
  db-search) . "$SCRIPT_DIR/cli/commands/registry/search.sh" ;;
  update-db) . "$SCRIPT_DIR/cli/commands/registry/update.sh" ;;
  semver) . "$SCRIPT_DIR/cli/commands/core/semver.sh" ;;
  package_as) . "$SCRIPT_DIR/cli/commands/packaging/package_as.sh" ;;
esac

IS_ACTION=0
REQ_VERSION=0
case "$CMD" in
  install|install_daemon|install_service|uninstall_daemon|uninstall_service|remove_daemon|remove_service)
    IS_ACTION=1; REQ_VERSION=1 ;;
  remove|uninstall|status|health|test|ls|ls-remote|start|stop|restart|logs|up|down)
    IS_ACTION=1 ;;
  run|which|exec|env|download|serve|route|info)
    IS_ACTION=1; REQ_VERSION=1 ;;
esac

ACTION_PKG="$CMD"
if [ "$IS_ACTION" = "1" ]; then
  ACTION_PKG="$1"
  if [ -z "$ACTION_PKG" ]; then
    echo "Error: package_name is required for $CMD" >&2
    exit 1
  fi
  # We do not shift here because the local cli.sh expects the action as $1
  # But we need to pass "$CMD" "$ACTION_PKG" "$@" to local cli.sh
  # Oh wait, we already shifted. So $1 is ACTION_PKG.
  # Let's restore "$CMD" for the local cli.sh.
  set -- "$CMD" "$@"
fi

TARGET=""
if [ -f "$SCRIPT_DIR/$ACTION_PKG/cli.sh" ]; then
  TARGET="$SCRIPT_DIR/$ACTION_PKG"
else
  if ! matches=$(find_components | grep -i "$ACTION_PKG"); then
    matches=""
  fi
  if ! count=$(echo "$matches" | grep -c .); then
    count=0
  fi
  if [ "$count" -eq 0 ]; then
    echo "Error: Unknown component '$ACTION_PKG'."
    exit 1
  elif [ "$count" -eq 1 ]; then
    TARGET="$SCRIPT_DIR/$matches"
  else
    if ! exact_match=$(echo "$matches" | grep "/$ACTION_PKG$"); then
      exact_match=""
    fi
    if ! exact_count=$(echo "$exact_match" | grep -c .); then
      exact_count=0
    fi
    if [ "$exact_count" -eq 1 ]; then
      TARGET="$SCRIPT_DIR/$exact_match"
    else
      echo "Error: Component '$ACTION_PKG' is ambiguous. Matches:"
      echo "$matches" | sed 's/^/  /'
      exit 1
    fi
  fi
fi

if [ -x "$TARGET/cli.sh" ]; then
  exec "$TARGET/cli.sh" "$@"
elif [ -f "$TARGET/cli.sh" ]; then
  exec sh "$TARGET/cli.sh" "$@"
else
  echo "Error: Local CLI not found in $TARGET"
  exit 1
fi
