#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  this_file="${(%):-%x}"
  set -o pipefail
else
  this_file="${0}"
fi

case "${STACK+x}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
export STACK="${STACK:-}${this_file}"':'
SCRIPT_DIR=$(cd "$(dirname -- "${this_file}")" && pwd)
LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-${SCRIPT_DIR}}"
export LIBSCRIPT_ROOT_DIR

# Source logging
for lib in '_lib/_common/log.sh' ; do
  SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/'"${lib}"
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
      def aliases: [ .properties[]? | select(.versionAliases) | .versionAliases[] ] | unique | join(", ");
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
      listen_str="${1#*=}"
      if echo "$listen_str" | grep -q "^unix:"; then
        export LIBSCRIPT_LISTEN_SOCKET="${listen_str#unix:}"
      elif echo "$listen_str" | grep -q ":"; then
        export LIBSCRIPT_LISTEN_ADDRESS="${listen_str%%:*}"
        export LIBSCRIPT_LISTEN_PORT="${listen_str##*:}"
      else
        export LIBSCRIPT_LISTEN_PORT="$listen_str"
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
cmd="$1"
if [ -z "$cmd" ] || [ "$cmd" = "--help" ] || [ "$cmd" = "-h" ] || [ "$cmd" = "/?" ]; then
  show_help
  exit 0
fi

if [ "$cmd" = "--version" ] || [ "$cmd" = "-v" ]; then
  echo "${LIBSCRIPT_VERSION:-dev}"
  exit 0
fi

shift || true

case "$cmd" in
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

is_action=0
req_version=0
case "$cmd" in
  install|install_daemon|install_service|uninstall_daemon|uninstall_service|remove_daemon|remove_service)
    is_action=1; req_version=1 ;;
  remove|uninstall|status|health|test|ls|ls-remote|start|stop|restart|logs|up|down)
    is_action=1 ;;
  run|which|exec|env|download|serve|route|info)
    is_action=1; req_version=1 ;;
esac

action_pkg="$cmd"
if [ "$is_action" = "1" ]; then
  action_pkg="$1"
  if [ -z "$action_pkg" ]; then
    echo "Error: package_name is required for $cmd" >&2
    exit 1
  fi
  # We do not shift here because the local cli.sh expects the action as $1
  # But we need to pass "$cmd" "$action_pkg" "$@" to local cli.sh
  # Oh wait, we already shifted. So $1 is action_pkg.
  # Let's restore "$cmd" for the local cli.sh.
  set -- "$cmd" "$@"
fi

target=""
if [ -f "$SCRIPT_DIR/$action_pkg/cli.sh" ]; then
  target="$SCRIPT_DIR/$action_pkg"
else
  if ! matches=$(find_components | grep -i "$action_pkg"); then
    matches=""
  fi
  if ! count=$(echo "$matches" | grep -c .); then
    count=0
  fi
  if [ "$count" -eq 0 ]; then
    echo "Error: Unknown component '$action_pkg'."
    exit 1
  elif [ "$count" -eq 1 ]; then
    target="$SCRIPT_DIR/$matches"
  else
    if ! exact_match=$(echo "$matches" | grep "/$action_pkg$"); then
      exact_match=""
    fi
    if ! exact_count=$(echo "$exact_match" | grep -c .); then
      exact_count=0
    fi
    if [ "$exact_count" -eq 1 ]; then
      target="$SCRIPT_DIR/$exact_match"
    else
      echo "Error: Component '$action_pkg' is ambiguous. Matches:"
      echo "$matches" | sed 's/^/  /'
      exit 1
    fi
  fi
fi

if [ -x "$target/cli.sh" ]; then
  exec "$target/cli.sh" "$@"
elif [ -f "$target/cli.sh" ]; then
  exec sh "$target/cli.sh" "$@"
else
  echo "Error: Local CLI not found in $target"
  exit 1
fi
