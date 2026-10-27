#!/bin/sh
# ## Overview
# Main entry point for the libscript framework.
# 
# ## Usage
# Execute this script to access global libscript functionality.


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
LIBSCRIPT_ENTRY_FILE="${THIS_FILE}"
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

# ## show_help
# Displays command-line usage instructions and available options.
show_help() {
  printf '%s\n' 'LibScript Global CLI'
  printf '%s\n' '===================='
  printf '%s\n' ""
  printf '%s\n' "Usage: ${LIBSCRIPT_ENTRY_FILE##*/} [COMMAND] [ARGS...]"
  printf '%s\n' ""
  printf '%s\n' 'Commands:'
  printf '%s\n' '  list                        List all available components'
  printf '%s\n' '  search <query>              Search available components by name or description'
  printf '%s\n' '  process-downloads [file]    Process an aria2-formatted download list'
  printf '%s\n' '  env <component> <version>   Print environment variables for a component'
  printf '%s\n' '  install-deps [file]         Install all dependencies defined in a JSON file (default: libscript.json)'
  printf '%s\n' '  package-as <format> [args]  Package libscript usage (e.g., docker, docker_compose)'
  printf '%s\n' '  install <package_name> <version> Install a specific version of a component'
  printf '%s\n' '  use <package_name> <version> Set the default version of a component'
  printf '%s\n' '  download <package_name> <version> Download artifacts for a component to the local cache without installing'
  printf '%s\n' '  start [package_name...]     Start services (or all deps in json)'
  printf '%s\n' '  stop [package_name...]      Stop services'
  printf '%s\n' '  status [package_name...]    Show service status'
  printf '%s\n' '  health [package_name...]    Check service health'
  printf '%s\n' '  restart [package_name...]   Restart services'
  printf '%s\n' '  logs [-f] [package_name...]  Show service logs (real-time stream)'
  printf '%s\n' '  up [package_name...]        Alias for start'
  printf '%s\n' '  down [package_name...]      Alias for stop'
  printf '%s\n' '  provision <provider> ...    Provision a cloud environment'
  printf '%s\n' '  deprovision <provider> ...  Deprovision a cloud environment'
  printf '%s\n' '  deploy [repo_or_path] ...   Git-driven application and cloud deployment workflow'
  printf '%s\n' '  deploy-remote <user@host>   Idempotently deploy multiple apps to a remote host'
  printf '%s\n' '  <component> [OPTIONS...]    Invoke the CLI for a specific component'
  printf '%s\n' ""
  printf '%s\n' 'Options:'
  printf '%s\n' '  --help, -h, /?, -?          Show this extensive help text'
  printf '%s\n' '  --offline, -o               Enable offline execution mode (prohibits remote network requests)'
  printf '%s\n' '  --force-offline             Strictly abort execution if network calls are attempted'
  printf '%s\n' '  --online                    Explicitly enable online execution mode'
  printf '%s\n' '  --cache-dir=<dir>           Set local artifact cache directory (LIBSCRIPT_CACHE_DIR)'
  printf '%s\n' '  --download-dir=<dir>        Set temporary download staging directory (DOWNLOAD_DIR)'
  printf '%s\n' '  --prefix=<dir>              Set local installation prefix'
  printf '%s\n' '  --log-format=<text|json>    Set log output format'
  printf '%s\n' '  --log-level=<0-4>           Set minimum log level (0=DEBUG, 1=INFO, etc)'
  printf '%s\n' '  --log-file=<path>           Set a file to mirror all logs to'
  printf '%s\n' '  --service-name=<name>       Set a custom service/daemon name'
  printf '%s\n' '  --secrets=<dir|url>         Save generated secrets to a directory or OpenBao/Vault URL'
  printf '%s\n' "  --listen=<str>                Global listen (port, addr:port, unix:socket)
  --listen-port=<port>        Global port to listen on"
  printf '%s\n' '  --listen-address=<addr>     Global address to listen on'
  printf '%s\n' '  --listen-socket=<socket>    Global unix socket to listen on'
  printf '%s\n' ""
  printf '%s\n' 'Examples:'
  printf '%s\n' "  ${LIBSCRIPT_ENTRY_FILE##*/} list"
  printf '%s\n' "  ${LIBSCRIPT_ENTRY_FILE##*/} search ruby"
  printf '%s\n' "  ${LIBSCRIPT_ENTRY_FILE##*/} ruby --help"
  printf '%s\n' "  ${LIBSCRIPT_ENTRY_FILE##*/} postgres --help"
  printf '%s\n' ""
  printf '%s\n' "You can specify components by their short name (e.g., 'ruby' instead of '_lib/languages/ruby')."
  printf '%s\n' 'If there are multiple matches, it will ask you to be more specific.'
  printf '%s\n' ""
}

# ## find_components
# Performs the find_components operation and updates component state.
find_components() {
  find "$LIBSCRIPT_CLI_DIR" -name "cli.sh" ! -path "*/tmp/*" ! -path "*/.*" | while read -r cli_script; do
    dir=$(dirname "$cli_script")
    if [ -f "$dir/vars.schema.json" ] || [ -f "$dir/topology.json" ] || [ -f "$dir/payload.json" ]; then
      rel_dir="${dir#"$LIBSCRIPT_CLI_DIR"/}"
      if [ "$rel_dir" != "$dir" ]; then
        printf '%s\n' "$rel_dir"
      fi
    fi
  done
}

# ## get_desc
# Performs the get_desc operation and updates component state.
get_desc() {
  schema="$LIBSCRIPT_CLI_DIR/$1/vars.schema.json"
  if [ ! -f "$schema" ]; then
    schema="$LIBSCRIPT_CLI_DIR/$1/topology.json"
  fi
  if [ ! -f "$schema" ]; then
    schema="$LIBSCRIPT_CLI_DIR/$1/payload.json"
  fi
  if [ -f "$schema" ] && command -v jq >/dev/null 2>&1; then
    jq -r '
      def aliases: [ .properties[]? | select(.version_aliases) | .version_aliases[] ] | unique | join(", ");
      if .description then
        if (aliases | length > 0) then .description + " [version aliases: " + aliases + "]" else .description end
      else "" end
    ' "$schema" 2>/dev/null || true
  fi
}

# ## normalize_component_alias
# Maps legacy and shorthand component paths to canonical repository paths.
normalize_component_alias() {
  case "${1:-}" in
    cloud-providers/gcp/cli|gcp/cli) printf '%s\n' "_lib/cloud-providers/gcp-cli" ;;
    cloud-providers/gcp/tpu-vm|gcp/tpu-vm) printf '%s\n' "_lib/cloud-providers/gcp-tpu-vm" ;;
    cloud-providers/gcp/gpu-vm|gcp/gpu-vm) printf '%s\n' "_lib/cloud-providers/gcp-gpu-vm" ;;
    cloud-providers/gcp/filestore|gcp/filestore) printf '%s\n' "_lib/cloud-providers/gcp-filestore" ;;
    cloud-providers/gcp/gke-tpu-cluster|gcp/gke-tpu-cluster|gke-tpu-cluster) printf '%s\n' "topologies/gke-tpu-cluster" ;;
    cloud/storage) printf '%s\n' "_lib/cloud/storage" ;;
    cloud/cdn) printf '%s\n' "_lib/cloud/cdn" ;;
    cloud/cert) printf '%s\n' "_lib/cloud/cert" ;;
    cloud/volume) printf '%s\n' "_lib/cloud/volume" ;;
    cloud/cloudinit) printf '%s\n' "_lib/cloud/cloudinit" ;;
    stacks/ml-training/tpu-vm-eval-node|ml-training/tpu-vm-eval-node|tpu-vm-eval-node) printf '%s\n' "_lib/ml-training" ;;
    stacks/ml-training/gke-xpk-training|ml-training/gke-xpk-training|gke-xpk-training) printf '%s\n' "_lib/orchestration/gke-xpk-training" ;;
    stacks/ai-serving/tpu-vm-vllm|ai-serving/tpu-vm-vllm|tpu-vm-vllm) printf '%s\n' "_lib/ai-serving" ;;
    stacks/ai-serving/gke-xpk-inference|ai-serving/gke-xpk-inference|gke-xpk-inference) printf '%s\n' "_lib/ai-serving/gke-xpk-inference" ;;
    stacks/cms/openedx) printf '%s\n' "_lib/web-apps/openedx" ;;
    stacks/cms/wordpress) printf '%s\n' "_lib/web-apps/wordpress" ;;
    stacks/cms/drupal) printf '%s\n' "_lib/web-apps/drupal" ;;
    stacks/cms/joomla) printf '%s\n' "_lib/web-apps/joomla" ;;
    stacks/ecommerce/woocommerce) printf '%s\n' "_lib/web-apps/woocommerce" ;;
    stacks/ecommerce/magento) printf '%s\n' "_lib/web-apps/magento" ;;
    stacks/ecommerce/prestashop) printf '%s\n' "_lib/web-apps/prestashop" ;;
    stacks/collaboration/nextcloud) printf '%s\n' "_lib/web-apps/nextcloud" ;;
    stacks/crawlers/firecrawl) printf '%s\n' "_lib/web-apps/firecrawl" ;;
    stacks/data-science/jupyterhub) printf '%s\n' "_lib/web-apps/jupyterhub" ;;
    stacks/erp/odoo) printf '%s\n' "_lib/web-apps/odoo" ;;
    stacks/forums/phpbb) printf '%s\n' "_lib/web-apps/phpbb" ;;
    stacks/networking/openvpn) printf '%s\n' "_lib/networking/openvpn" ;;
    stacks/scaffolds/serve-actix-diesel-auth-scaffold) printf '%s\n' "_lib/web-apps/serve-actix-diesel-auth-scaffold" ;;
    stacks/task-queues/celery) printf '%s\n' "_lib/web-apps/celery" ;;
    stacks/virtualization/bento-builder) printf '%s\n' "_lib/virtualization/bento-builder" ;;
    *) printf '%s\n' "${1:-}" ;;
  esac
}

# Pre-scan arguments for global offline and cache flags
for _scan_arg in "$@"; do
  case "$_scan_arg" in
    --offline|-o) export LIBSCRIPT_OFFLINE=1 ;;
    --force-offline) export LIBSCRIPT_FORCE_OFFLINE=1; export LIBSCRIPT_OFFLINE=1 ;;
    --online) export LIBSCRIPT_OFFLINE=0 ;;
  esac
done

while [ $# -gt 0 ]; do
  case "$1" in
    --offline|-o)
      export LIBSCRIPT_OFFLINE=1
      shift
      ;;
    --force-offline)
      export LIBSCRIPT_FORCE_OFFLINE=1
      export LIBSCRIPT_OFFLINE=1
      shift
      ;;
    --online)
      export LIBSCRIPT_OFFLINE=0
      shift
      ;;
    --cache-dir=*)
      export LIBSCRIPT_CACHE_DIR="${1#*=}"
      shift
      ;;
    --cache-dir)
      shift
      export LIBSCRIPT_CACHE_DIR="${1:-}"
      shift
      ;;
    --download-dir=*)
      export DOWNLOAD_DIR="${1#*=}"
      export LIBSCRIPT_DOWNLOAD_DIR="${1#*=}"
      shift
      ;;
    --download-dir)
      shift
      export DOWNLOAD_DIR="${1:-}"
      export LIBSCRIPT_DOWNLOAD_DIR="${DOWNLOAD_DIR}"
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
      if printf '%s\n' "$LISTEN_STR" | grep -q "^unix:"; then
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
if [ -z "$CMD" ] || [ "$CMD" = "help" ] || [ "$CMD" = "--help" ] || [ "$CMD" = "-h" ] || [ "$CMD" = "/?" ] || [ "$CMD" = "-?" ]; then
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
  deploy) . "$LIBSCRIPT_ROOT_DIR/cli/commands/cloud/deploy.sh" ;;
  deploy-remote) . "$LIBSCRIPT_ROOT_DIR/cli/commands/cloud/deploy-remote.sh" ;;
  backup|export-remote) . "$LIBSCRIPT_ROOT_DIR/cli/commands/cloud/backup.sh" ;;
  restore|import-remote) . "$LIBSCRIPT_ROOT_DIR/cli/commands/cloud/restore.sh" ;;
  netctl) exec "$LIBSCRIPT_ROOT_DIR/_lib/networking/netctl/cli.sh" "$@" ;;
  search) . "$LIBSCRIPT_ROOT_DIR/cli/commands/core/search.sh" ;;
  start|stop|status|health|logs|restart|up|down|deprovision-db|export-state|import-state|prepare-storage) . "$LIBSCRIPT_ROOT_DIR/cli/commands/services/actions.sh" ;;
  uninstall-service)
    if [ $# -eq 0 ] || [ "${1:-}" = "libscript.json" ] || [ "${1##*.}" = "json" ] || [ "${1#--}" != "${1:-}" ]; then
      . "$LIBSCRIPT_ROOT_DIR/cli/commands/services/actions.sh"
    fi
    ;;
  install-deps) . "$LIBSCRIPT_ROOT_DIR/cli/commands/deps/install.sh" ;;
  db-search) . "$LIBSCRIPT_ROOT_DIR/cli/commands/registry/search.sh" ;;
  update-db) . "$LIBSCRIPT_ROOT_DIR/cli/commands/registry/update.sh" ;;
  semver) . "$LIBSCRIPT_ROOT_DIR/cli/commands/core/semver.sh" ;;
  package-as) . "$LIBSCRIPT_ROOT_DIR/cli/commands/packaging/package-as.sh" ;;
  config) . "$LIBSCRIPT_ROOT_DIR/cli/commands/config/config.sh" ;;
  repogen) . "$LIBSCRIPT_ROOT_DIR/_lib/orchestration/repogen/repogen.sh" ;;
  distro) . "$LIBSCRIPT_ROOT_DIR/_lib/orchestration/distro/distro.sh" ;;
  payload) exec "$LIBSCRIPT_ROOT_DIR/payloads/engine.sh" "$@" ;;
  topology) exec "$LIBSCRIPT_ROOT_DIR/topologies/engine.sh" "$@" ;;
  trait) exec "$LIBSCRIPT_ROOT_DIR/traits/engine.sh" "$@" ;;
  train|infer|serve-ml|eval-ml) exec "$LIBSCRIPT_ROOT_DIR/cli/commands/ml/actions.sh" "$CMD" "$@" ;;
  env)
    if [ "${1:-}" = "--manifest" ] || [ -z "${1:-}" ] || [ -f "${1:-}" ]; then
      _env_manifest='libscript.json'
      _env_fmt='sh'
      if [ "${1:-}" = "--manifest" ]; then
        shift || true
        if [ -n "${1:-}" ] && [ "${1#--}" = "$1" ]; then
          _env_manifest="$1"
          shift || true
        fi
      elif [ -n "${1:-}" ] && [ -f "${1:-}" ]; then
        _env_manifest="$1"
        shift || true
      fi
      for _e_arg in "$@"; do
        case "$_e_arg" in
          --format=*) _env_fmt="${_e_arg#*=}" ;;
          sh|bash|zsh|fish|cmd|powershell|ps1|docker|dockerfile|docker_compose|dotenv|envfile|systemd|json) _env_fmt="$_e_arg" ;;
        esac
      done
      SCRIPT_NAME="$LIBSCRIPT_ROOT_DIR/_lib/_common/env_printer.sh"
      export SCRIPT_NAME
      # shellcheck disable=SC1090,SC1091
      . "$SCRIPT_NAME"
      libscript_print_manifest_env "$_env_fmt" "$_env_manifest"
      exit 0
    fi
    ;;
esac

IS_ACTION=0
export REQ_VERSION=0
case "$CMD" in
  install|install-service|uninstall-service|use|download)
    IS_ACTION=1; export REQ_VERSION=1 ;;
  remove|uninstall|status|health|test|ls|ls-remote|start|stop|restart|logs|up|down)
    IS_ACTION=1 ;;
  run|which|exec|env|serve|route|info)
    IS_ACTION=1; export REQ_VERSION=1 ;;
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

ACTION_PKG="$(normalize_component_alias "$ACTION_PKG")"
SCRIPT_DIR="$LIBSCRIPT_CLI_DIR"

TARGET=""
if [ "$ACTION_PKG" = "cloud" ]; then
  TARGET="$LIBSCRIPT_CLI_DIR/_lib/cloud/core"
elif [ -f "$SCRIPT_DIR/$ACTION_PKG/cli.sh" ]; then
  TARGET="$LIBSCRIPT_CLI_DIR/$ACTION_PKG"
elif [ -f "$SCRIPT_DIR/_lib/$ACTION_PKG/cli.sh" ]; then
  TARGET="$LIBSCRIPT_CLI_DIR/_lib/$ACTION_PKG"
elif [ -f "$SCRIPT_DIR/topologies/$ACTION_PKG/cli.sh" ]; then
  TARGET="$LIBSCRIPT_CLI_DIR/topologies/$ACTION_PKG"
elif [ -f "$SCRIPT_DIR/payloads/$ACTION_PKG/cli.sh" ]; then
  TARGET="$LIBSCRIPT_CLI_DIR/payloads/$ACTION_PKG"
else
  if ! matches=$(find_components | grep -i "$ACTION_PKG"); then
    matches=""
  fi
  if ! count=$(printf '%s\n' "$matches" | grep -c .); then
    count=0
  fi
  if [ "$count" -eq 0 ]; then
    printf '%s\n' "Error: Unknown component '$ACTION_PKG'." >&2
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
      printf '%s\n' "Error: Component '$ACTION_PKG' is ambiguous. Matches:" >&2
      printf '%s\n' "$matches" | sed 's/^/  /' >&2
      exit 1
    fi
  fi
fi

if [ "$IS_ACTION" = "1" ]; then
  if [ -x "$TARGET/cli.sh" ]; then
    exec "$TARGET/cli.sh" "$@"
  elif [ -f "$TARGET/cli.sh" ]; then
    exec sh "$TARGET/cli.sh" "$@"
  else
    printf '%s\n' "Error: Local CLI not found in $TARGET" >&2
    exit 1
  fi
else
  if [ -x "$TARGET/cli.sh" ]; then
    exec "$TARGET/cli.sh" "$@"
  elif [ -f "$TARGET/cli.sh" ]; then
    exec sh "$TARGET/cli.sh" "$@"
  else
    printf '%s\n' "Error: Local CLI not found in $TARGET" >&2
    exit 1
  fi
fi
