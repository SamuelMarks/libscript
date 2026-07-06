#!/bin/sh
# ## Overview
# Main entry point for the libscript framework.
# 
# ## Usage
# Execute this script to access global libscript functionality.


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
    printf '[STOP]     processing "%s"\n' "${THIS_FILE}" >&2
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${THIS_FILE}" >&2 ;;
esac
export STACK="${STACK:-}${THIS_FILE}"':'
LIBSCRIPT_CLI_DIR=$(cd "$(dirname -- "${THIS_FILE}")" && pwd)
SCRIPT_DIR="${LIBSCRIPT_CLI_DIR}"
: "${LIBSCRIPT_ROOT_DIR:=$(d="$SCRIPT_DIR"; while [ ! -f "$d/libscript.sh" ]; do n="${d%/*}"; [ -z "$n" ] && n="/"; [ "$d" = "$n" ] && break; d="$n"; done; printf '%s\n' "$d")}"
export LIBSCRIPT_ROOT_DIR

# Source logging
for LIB in "_lib/_common/log.sh" ${_LIBSCRIPT_DUMMY_NO_RUN:-}; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${LIB}"
  # shellcheck disable=SC1090
  . "${SCRIPT_NAME}"
done

show_help() {
  printf '%s\n' "LibScript Global CLI"
  printf '%s\n' "===================="
  printf '%s\n' ""
  printf '%s\n' "Usage: $0 [COMMAND] [ARGS...]"
  printf '%s\n' ""
  printf '%s\n' "Commands:"
  printf '%s\n' "  list                        List all available components"
  printf '%s\n' "  search <query>              Search available components by name or description"
  printf '%s\n' "  process-downloads [file]    Process an aria2-formatted download list"
  printf '%s\n' "  env <component> <version>   Print environment variables for a component"
  printf '%s\n' "  install-deps [file]         Install all dependencies defined in a JSON file (default: libscript.json)"
  printf '%s\n' "  package-as <format> [args]  Package libscript usage (e.g., docker, docker_compose)"
  printf '%s\n' "  install <package_name> <version> Install a specific version of a component"
  printf '%s\n' "  use <package_name> <version> Set the default version of a component"
  printf '%s\n' "  download <package_name> <version> Download artifacts for a component to the local cache without installing"
  printf '%s\n' "  start [package_name...]     Start services (or all deps in json)"
  printf '%s\n' "  stop [package_name...]      Stop services"
  printf '%s\n' "  status [package_name...]    Show service status"
  printf '%s\n' "  health [package_name...]    Check service health"
  printf '%s\n' "  restart [package_name...]   Restart services"
  printf '%s\n' "  logs [-f] [package_name...]  Show service logs (real-time stream)"
  printf '%s\n' "  up [package_name...]        Alias for start"
  printf '%s\n' "  down [package_name...]      Alias for stop"
  printf '%s\n' "  provision <provider> ...    Provision a cloud environment"
  printf '%s\n' "  deprovision <provider> ...  Deprovision a cloud environment"
  printf '%s\n' "  <component> [OPTIONS...]    Invoke the CLI for a specific component"
  printf '%s\n' ""
  printf '%s\n' "Options:"
  printf '%s\n' "  --help, -h, /?, -?          Show this extensive help text"
  printf '%s\n' "  --prefix=<dir>              Set local installation prefix"
  printf '%s\n' "  --log-format=<text|json>    Set log output format"
  printf '%s\n' "  --log-level=<0-4>           Set minimum log level (0=DEBUG, 1=INFO, etc)"
  printf '%s\n' "  --log-file=<path>           Set a file to mirror all logs to"
  printf '%s\n' "  --service-name=<name>       Set a custom service/daemon name"
  printf '%s\n' "  --secrets=<dir|url>         Save generated secrets to a directory or OpenBao/Vault URL"
  printf '%s\n' "  --listen=<str>                Global listen (port, addr:port, unix:socket)
  --listen-port=<port>        Global port to listen on"
  printf '%s\n' "  --listen-address=<addr>     Global address to listen on"
  printf '%s\n' "  --listen-socket=<socket>    Global unix socket to listen on"
  printf '%s\n' ""
  printf '%s\n' "Examples:"
  printf '%s\n' "  $0 list"
  printf '%s\n' "  $0 search ruby"
  printf '%s\n' "  $0 ruby --help"
  printf '%s\n' "  $0 postgres --help"
  printf '%s\n' ""
  printf '%s\n' "You can specify components by their short name (e.g., 'ruby' instead of '_lib/languages/ruby')."
  printf '%s\n' "If there are multiple matches, it will ask you to be more specific."
  printf '%s\n' ""
}

find_components() {
  find "$LIBSCRIPT_CLI_DIR" -name "cli.sh" | while read -r cli_script; do
    dir=$(dirname "$cli_script")
    if [ -f "$dir/vars.schema.json" ]; then
      rel_dir="${dir#"$LIBSCRIPT_CLI_DIR"/}"
      if [ "$rel_dir" != "$dir" ]; then
        printf '%s\n' "$rel_dir"
      fi
    fi
  done
}

get_desc() {
  schema="$LIBSCRIPT_CLI_DIR/$1/vars.schema.json"
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
      elif printf '%s\n' "$LISTEN_STR" | grep -q ":"; then
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
CMD="${1:-}"
if [ -z "$CMD" ] || [ "$CMD" = "--help" ] || [ "$CMD" = "-h" ] || [ "$CMD" = "/?" ] || [ "$CMD" = "-?" ]; then
  show_help
  exit 0
fi

if [ "$CMD" = "--version" ] || [ "$CMD" = "-v" ]; then
  printf '%s\n' "${LIBSCRIPT_VERSION:-dev}"
  exit 0
fi

shift || true

case "$CMD" in
  list) . "$LIBSCRIPT_ROOT_DIR/cli/commands/core/list.sh" ;;
  process-downloads) . "$LIBSCRIPT_ROOT_DIR/cli/commands/deps/process_downloads.sh" ;;
  provision) . "$LIBSCRIPT_ROOT_DIR/cli/commands/cloud/provision.sh" ;;
  deprovision) . "$LIBSCRIPT_ROOT_DIR/cli/commands/cloud/deprovision.sh" ;;
  search) . "$LIBSCRIPT_ROOT_DIR/cli/commands/core/search.sh" ;;
  start|stop|status|health|logs|restart|up|down) . "$LIBSCRIPT_ROOT_DIR/cli/commands/services/actions.sh" ;;
  install-deps) . "$LIBSCRIPT_ROOT_DIR/cli/commands/deps/install.sh" ;;
  db-search) . "$LIBSCRIPT_ROOT_DIR/cli/commands/registry/search.sh" ;;
  update-db) . "$LIBSCRIPT_ROOT_DIR/cli/commands/registry/update.sh" ;;
  semver) . "$LIBSCRIPT_ROOT_DIR/cli/commands/core/semver.sh" ;;
  package-as) . "$LIBSCRIPT_ROOT_DIR/cli/commands/packaging/package-as.sh" ;;
esac

IS_ACTION=0
REQ_VERSION=0
case "$CMD" in
  install|install-service|uninstall-service|use|download)
    IS_ACTION=1; REQ_VERSION=1 ;;
  remove|uninstall|status|health|test|ls|ls-remote|start|stop|restart|logs|up|down)
    IS_ACTION=1 ;;
  run|which|exec|env|serve|route|info)
    IS_ACTION=1; REQ_VERSION=1 ;;
esac

ACTION_PKG="$CMD"
if [ "$IS_ACTION" = "1" ]; then
  ACTION_PKG="$1"
  if [ -z "$ACTION_PKG" ]; then
    printf '%s\n' "Error: package_name is required for $CMD" >&2
    exit 1
  fi
  # We do not shift here because the local cli.sh expects the action as $1
  # But we need to pass "$CMD" "$ACTION_PKG" "$@" to local cli.sh
  # Oh wait, we already shifted. So $1 is ACTION_PKG.
  # Let's restore "$CMD" for the local cli.sh.
  set -- "$CMD" "$@"
fi

TARGET=""
if [ "$ACTION_PKG" = "cloud" ]; then
  TARGET="$LIBSCRIPT_CLI_DIR/_lib/cloud/core"
elif [ -f "$SCRIPT_DIR/$ACTION_PKG/cli.sh" ]; then
  TARGET="$LIBSCRIPT_CLI_DIR/$ACTION_PKG"
else
  if ! matches=$(find_components | grep -i "$ACTION_PKG"); then
    matches=""
  fi
  if ! count=$(printf '%s\n' "$matches" | grep -c .); then
    count=0
  fi
  if [ "$count" -eq 0 ]; then
    printf '%s\n' "Error: Unknown component '$ACTION_PKG'."
    exit 1
  elif [ "$count" -eq 1 ]; then
    TARGET="$LIBSCRIPT_CLI_DIR/$matches"
  else
    if ! exact_match=$(printf '%s\n' "$matches" | grep "/$ACTION_PKG$"); then
      exact_match=""
    fi
    if ! exact_count=$(printf '%s\n' "$exact_match" | grep -c .); then
      exact_count=0
    fi
    if [ "$exact_count" -eq 1 ]; then
      TARGET="$LIBSCRIPT_CLI_DIR/$exact_match"
    else
      printf '%s\n' "Error: Component '$ACTION_PKG' is ambiguous. Matches:"
      printf '%s\n' "$matches" | sed 's/^/  /'
      exit 1
    fi
  fi
fi

if [ -x "$TARGET/cli.sh" ]; then
  exec "$TARGET/cli.sh" "$@"
elif [ -f "$TARGET/cli.sh" ]; then
  exec sh "$TARGET/cli.sh" "$@"
else
  printf '%s\n' "Error: Local CLI not found in $TARGET"
  exit 1
fi
